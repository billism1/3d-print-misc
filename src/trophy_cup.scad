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
rim_h       = ref * 0.09;   // mm, rim band height (Z) — must be <= bowl_wall_h
rim_flare_h = ref * 0.01;   // mm, height of the rim's angled underside flare;
                            // keep >= rim_t for a <=45 deg, support-free overhang

wall        = 4;            // mm, bowl wall thickness (print constraint)
bowl_floor  = ref * 0.10;   // mm of solid between the stem top and cavity floor
inner_round = ref * 0.16;   // radius of the rounded cavity bottom

seat_depth  = 1;            // mm the stem sinks into the base to fuse them
cavity_over = 5;            // mm the cavity overshoots the rim to open it

cup_fn      = 160;          // $fn for the revolved cup surfaces
cup_steps   = 64;           // segments per curved profile section

// Optional holder arms — a pair of handles on two opposite sides of the
// bowl, like a classic loving-cup trophy. Set `handles_on` true to add
// them. Each handle attaches low on the bowl near the stem, flares up and
// out at a print-friendly angle, then curls up and inward into the bowl
// wall just under the rim. The cross-section is a solid square bar (flat
// faces, not a round tube). The ends sink into the wall and are trimmed
// flush by the cavity cut.
handles_on      = false;        // true = add the two opposite handles
handle_t        = ref * 0.10;  // square bar side (cross-section handle_t x handle_t)
handle_out      = ref * 0.12;  // outward bulge past the bowl wall
handle_low_t    = 0.12;        // lower attach point as a t-fraction up the
                               // flare (0 = stem top, 1 = top of flare)
handle_inset    = ref * 0.08;  // how far the handle ends sink past the wall
handle_top_rise = ref * 0.06;  // how much the inner end curls up above the
                               // outer corner (the up-and-in curl at the top)
handle_curve_steps = 24;       // segments in the curved top section

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

// Optional handle — path geometry and guards
//   X-Z path: lower attach (into the bowl near the stem) -> outer corner
//   -> a curved arc that curls up and inward to the upper attach (into
//   the wall just under the rim). The upper attach sits `handle_top_rise`
//   above the outer corner, so the bar curves upward at the top.
handle_low_z  = stem_h + flare_h * handle_low_t;
handle_low_r  = stem_r + (bowl_r - stem_r) * (1 - cos(180 * handle_low_t)) / 2;
handle_high_z = z_rim0 - handle_t / 2;            // bar top lands just under rim
handle_out_z  = handle_high_z - handle_top_rise;  // outer corner, below the inner end

handle_low_pt = [handle_low_r - handle_inset, handle_low_z];
handle_out_pt = [bowl_r + handle_out,         handle_out_z];
handle_top_pt = [bowl_r - handle_inset,       handle_high_z];

//   Curved top: move inward (X) linearly while rising (Z) on a cosine
//   ease — the bar leaves the outer corner level, then curls up and into
//   the wall.
handle_top_curve = [ for (i = [1 : handle_curve_steps])
    let (t = i / handle_curve_steps)
    [ handle_out_pt[0] + (handle_top_pt[0] - handle_out_pt[0]) * t,
      handle_out_pt[1] + (handle_top_pt[1] - handle_out_pt[1]) * (1 - cos(90 * t)) ] ];

handle_path = concat([handle_low_pt, handle_out_pt], handle_top_curve);

handle_rise = handle_out_z - handle_low_z;                             // up to corner
handle_run  = (bowl_r + handle_out) - (handle_low_r - handle_inset);   // out to corner

assert(!handles_on || (handle_low_t > 0 && handle_low_t < 1),
       "handle_low_t must be between 0 and 1");
assert(!handles_on || handle_high_z > handle_low_z + handle_t,
       "handle has no usable height: lower handle_low_t or raise the bowl");
assert(!handles_on || handle_top_rise >= 0,
       "handle_top_rise must not be negative");
assert(!handles_on || handle_out_z > handle_low_z,
       "handle_top_rise too large: outer corner sinks below the lower attach");
assert(!handles_on || handle_run <= handle_rise,
       "handle flare steeper than 45 deg (not support-free): reduce handle_out, handle_top_rise, or lower handle_low_t");

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

// 3b. Handle module — one handle swept along `handle_path` as a solid
//     square bar; trophy_handles() places and mirrors the opposite pair.
//     Each segment is the hull of two axis-aligned cubes, giving flat
//     faces (square cross-section, not a round tube). The flared run leans
//     out <=45 deg; the top section curls up and inward into the wall.
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
