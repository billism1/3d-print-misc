// trophy_cup.scad
// Basic cup trophy: a hollow revolved cup (stem -> flared bowl -> open rim)
// sitting on an interchangeable trophy base.
//
// Base selection: exactly ONE base file is `include`d below. `include`
// renders the base geometry AND exposes its top-level variables to this
// file. To switch bases, comment the active line and uncomment another.
//
// Dimensions exposed by every base file (use these to scale the cup):
//   base_width    mm  — bottom footprint (square side, or diameter for
//                       scotia). The cup's proportions all derive from
//                       this via `ref` below. PRIMARY design input.
//   total_height  mm  — overall base height. The cup is lifted by this so
//                       it lands on the base's top platform. REQUIRED for
//                       placement; never hard-code it.
//
// Extra dimension exposed only by trophy_base_scotia.scad:
//   top_width     mm  — diameter of the platform the cup actually sits on.
//
// Caution: `base_width` is the BOTTOM footprint, wider than the top
// platform the stem rests on. The cup keeps `bowl_d` under `base_width`
// for visual balance, but the stem must fit the (smaller) platform:
//   - ogee bases  -> platform side  = 2 * hw4
//   - scotia base -> platform diam. = top_width
// Keep `stem_d` below that platform size when retuning proportions.

// Render toggle for the base. Must be set BEFORE the `include` line —
// the base file runs its own assembly during `include`, so this value
// has to exist by then. Set false to render the cup alone (e.g. to
// export the cup as a separate STL).
show_base = true;

// Select the desiged base by including its file here:
include <trophy_base_ogee_minimal.scad>
//include <trophy_base_ogee.scad>
//include <trophy_base_scotia.scad>

// 1. Constants & parameters
//    Cup proportions scale from the base footprint so any base fits.
//    `ref` is the single design dimension every cup feature is a fraction
//    of — sourced from the included base's `base_width`.
ref = base_width;

stem_d      = ref * 0.30;   // stem diameter at the base platform
stem_h      = ref * 0.10;   // straight stem height

flare_h     = ref * 0.70;   // height of the bowl's flared foot
bowl_d      = ref * 0.78;   // outer rim diameter (kept under base_width)
bowl_wall_h = ref * 0.15;   // straight bowl wall above the flare

rim_t       = ref * 0.015;  // mm, rim outward extrusion past the wall (0 = no rim)
rim_h       = ref * 0.11;   // mm, rim band height (Z) — must be <= bowl_wall_h
rim_flare_h = ref * 0.01;   // mm, height of the rim's angled underside flare;
                            // keep >= rim_t for a <=45 deg, support-free overhang

wall        = 5;            // mm, bowl wall thickness (print constraint)
bowl_floor  = ref * 0.10;   // mm of solid between the stem top and cavity floor
inner_round = ref * 0.16;   // radius of the rounded cavity bottom

seat_depth  = 1;            // mm the stem sinks into the base to fuse them
cavity_over = 5;            // mm the cavity overshoots the rim to open it

cup_fn      = 160;          // $fn for the revolved cup surfaces
cup_steps   = 64;           // segments per curved profile section

// Optional holder arms — a pair of handles on two opposite sides of the
// bowl, like a classic loving-cup trophy. Set `handles_on` true to add
// them. Each handle is a square bar following a 3-segment path: a steep
// near-vertical lift-off off the bowl near the stem, a straight diagonal
// flare out and up, then a horizontal top run that angles sharply inward
// and sinks into the wall just under the rim. Both end anchors bury into
// the wall; the cavity cut trims the buried inner end flush. The lift-off
// and flare run stay <=45 deg (support-free); the horizontal top prints
// as a short bridge.
handles_on        = true;        // true = add the two opposite handles
handle_t          = ref * 0.10;  // square bar side (cross-section handle_t^2)
handle_low_t      = 0.12;        // lower attach as a t-fraction up the flare
                                 // (0 = stem top, 1 = top of flare)
handle_inset      = ref * 0.08;  // how far each end sinks into the bowl wall
handle_out        = ref * 0.18;  // flare: outer corner radius past the bowl wall
handle_rise_lead  = 0.30;        // steep start: fraction of the total rise spent
                                 // lifting off near-vertical before the flare
                                 // run begins (higher = more vertical lift-off)
handle_bridge_max = 45;          // mm, max horizontal top span (FDM bridge limit)

// 2. Derived dimensions
stem_r  = stem_d / 2;
bowl_r  = bowl_d / 2;
inner_r = bowl_r - wall;

z_flare = stem_h + flare_h;             // flare ends / straight wall begins
cup_top = z_flare + bowl_wall_h;        // outer rim height (== z_flare if no wall)

cav_z0  = stem_h + bowl_floor;          // cavity floor — set inside the flare
z_round = cav_z0 + inner_round;         // top of the rounded cavity floor
cav_top = cup_top + cavity_over;        // cavity opens past the rim

rim_active = rim_t > 0 && rim_h > 0;    // rim suppressed when either is 0
z_rim0     = cup_top - rim_h;           // rim band starts here

//    Flare parameter t where the rounded floor blends into the flare wall,
//    and the inner-wall radius there (outer flare offset inward by `wall`).
t_join  = (z_round - stem_h) / flare_h;
r_join  = stem_r + (bowl_r - stem_r) * (1 - cos(180 * t_join)) / 2 - wall;

assert(inner_r > 0,     "wall too thick: inner radius <= 0");
assert(bowl_r > stem_r, "bowl_d must be greater than stem_d");
assert(bowl_floor > 0,  "bowl_floor must be positive: cavity floor sits in the stem");
assert(z_round < z_flare,
       "cavity curve too tall: rounded floor exceeds the flare — reduce bowl_floor/inner_round or raise flare_h");
assert(r_join > 0,      "flare too narrow at the cavity floor: r_join <= 0");
assert(rim_t >= 0,      "rim_t must not be negative");
assert(rim_h >= 0 && rim_h <= bowl_wall_h, "rim_h must be between 0 and bowl_wall_h");
assert(rim_flare_h >= 0 && rim_flare_h <= rim_h, "rim_flare_h must be between 0 and rim_h");

// Optional handle — 3-segment path and guards.
//   Waypoints (X = radius, Z = height):
//     p0  low anchor    — buried in the flare wall near the stem
//     p1  lift-off knee — top of the steep near-vertical lift-off
//     p2  outer corner  — the flared-out high point
//     p3  top anchor    — buried in the bowl wall just under the rim,
//                         level with p2 so the top run is horizontal
handle_low_z  = stem_h + flare_h * handle_low_t;
handle_low_r  = stem_r + (bowl_r - stem_r) * (1 - cos(180 * handle_low_t)) / 2;
handle_high_z = z_rim0 - handle_t / 2;            // bar top lands just under rim
handle_span   = handle_high_z - handle_low_z;     // total rise of the handle

handle_p0 = [handle_low_r - handle_inset, handle_low_z];
handle_p1 = [handle_low_r + handle_t / 2, handle_low_z + handle_span * handle_rise_lead];
handle_p2 = [bowl_r + handle_out,         handle_high_z];
handle_p3 = [bowl_r - handle_inset,       handle_high_z];

handle_path = [handle_p0, handle_p1, handle_p2, handle_p3];

//   Per-segment slope checks: lift-off (p0->p1) and flare run (p1->p2)
//   must stay <=45 deg from vertical (support-free); the horizontal top
//   run (p2->p3) is a bridge, length-limited instead.
handle_liftoff_slope = (handle_p1[0] - handle_p0[0]) / (handle_p1[1] - handle_p0[1]);
handle_flare_slope   = (handle_p2[0] - handle_p1[0]) / (handle_p2[1] - handle_p1[1]);
handle_bridge_len    = handle_p2[0] - handle_p3[0];

assert(!handles_on || (handle_low_t > 0 && handle_low_t < 1),
       "handle_low_t must be between 0 and 1");
assert(!handles_on || handle_span > handle_t,
       "handle has no usable height: lower handle_low_t or raise the bowl");
assert(!handles_on || (handle_rise_lead > 0 && handle_rise_lead < 1),
       "handle_rise_lead must be between 0 and 1");
assert(!handles_on || handle_p1[1] < handle_p2[1],
       "handle lift-off too tall: handle_rise_lead leaves no room for the flare run");
assert(!handles_on || abs(handle_liftoff_slope) <= 1,
       "handle lift-off overhangs steeper than 45 deg (not support-free): raise handle_rise_lead");
assert(!handles_on || abs(handle_flare_slope) <= 1,
       "handle flare overhangs steeper than 45 deg (not support-free): reduce handle_out or handle_rise_lead");
assert(!handles_on || handle_bridge_len > 0,
       "handle does not flare past its top anchor: increase handle_out");
assert(!handles_on || handle_bridge_len <= handle_bridge_max,
       "handle top run too long to bridge: reduce handle_out or raise handle_bridge_max");

// 3. Profiles (list of [radius, z], revolved around the Z axis)
//    Outer: stem -> cosine-S flare -> straight bowl wall -> rim -> closed top.
flare_pts = [ for (i = [1 : cup_steps])
    let (t = i / cup_steps)
    [ stem_r + (bowl_r - stem_r) * (1 - cos(180 * t)) / 2, stem_h + flare_h * t ] ];

//    Top of the outer profile. With a rim: wall -> diagonal flare (out and
//    up, so the underside is a printable slope, not a 90 deg overhang) ->
//    straight rim face. Without: plain wall vertex (omitted when no wall).
outer_top = rim_active
    ? [ [bowl_r,         z_rim0],                   // bowl wall meets the rim
        [bowl_r + rim_t, z_rim0 + rim_flare_h],     // flare out and up
        [bowl_r + rim_t, cup_top] ]                 // straight rim face
    : (bowl_wall_h > 0 ? [ [bowl_r, cup_top] ] : []);

outer_profile = concat(
    [ [0, 0], [stem_r, 0], [stem_r, stem_h] ],   // axis -> stem
    flare_pts,                                   // flared foot
    outer_top,                                   // straight wall + optional rim
    [ [0, cup_top] ]                             // closed top
);

//    Cavity: rounded floor + a wall that follows the flare (both stay
//    inside the flare), then a straight cylinder cutout through the bowl
//    wall, opening past the rim. No concave curve in the bowl wall zone.
cavity_round = [ for (i = [0 : cup_steps])
    let (a = 90 * i / cup_steps)
    [ r_join * sin(a), cav_z0 + inner_round * (1 - cos(a)) ] ];

//    Inner wall = outer flare offset inward by `wall`, from the rounding
//    join (t_join) up to the top of the flare (t = 1, r = inner_r).
cavity_flare = [ for (i = [1 : cup_steps])
    let (t = t_join + (1 - t_join) * i / cup_steps)
    [ stem_r + (bowl_r - stem_r) * (1 - cos(180 * t)) / 2 - wall,
      stem_h + flare_h * t ] ];

cavity_profile = concat(
    cavity_round,                                // rounded floor (in the flare)
    cavity_flare,                                // wall follows the flare
    [ [inner_r, cav_top], [0, cav_top] ]         // straight cylinder -> open top
);

// 3b. Handle module — one handle swept along the 3-segment `handle_path`
//     as a solid square bar; trophy_handles() places and mirrors the
//     opposite pair. Each segment is the hull of two axis-aligned cubes,
//     giving flat faces (square cross-section, not a round tube): a steep
//     lift-off, a straight diagonal flare, and a horizontal top run.
module trophy_handle() {
    for (i = [0 : len(handle_path) - 2])
        hull() {
            translate([handle_path[i][0], 0, handle_path[i][1]])
                cube(handle_t, center = true);
            translate([handle_path[i + 1][0], 0, handle_path[i + 1][1]])
                cube(handle_t, center = true);
        }
}

module trophy_handles() {
    for (a = [0, 180])
        rotate([0, 0, a])
            trophy_handle();
}

// 4. Component module
module trophy_cup() {
    difference() {
        union() {
            rotate_extrude($fn = cup_fn)
                polygon(outer_profile);
            if (handles_on)
                trophy_handles();
        }
        rotate_extrude($fn = cup_fn)
            polygon(cavity_profile);
    }
}

// 5. Assembly — cup sits on the base platform (total_height from the base file)
translate([0, 0, total_height - seat_depth])
    trophy_cup();
