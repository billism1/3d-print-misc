// trophy_cup.scad
// Basic cup trophy: a hollow revolved cup (stem -> flared bowl -> open rim)
// sitting on an interchangeable trophy base.
//
// Base selection: exactly ONE base file is `include`d below. `include`
// renders the base geometry AND exposes its `total_height` and
// `base_width`. The cup sits on `total_height` and its proportions scale
// from `base_width`, so swapping bases keeps the trophy proportional.
// To switch bases, comment the active line and uncomment another.

include <trophy_base_ogee_minimal.scad>
// include <trophy_base_ogee.scad>
// include <trophy_base_scotia.scad>

// 1. Constants & parameters
//    Cup proportions scale from the base footprint so any base fits.
ref = base_width;

stem_d      = ref * 0.20;   // stem diameter at the base platform
stem_h      = ref * 0.42;   // straight stem height

flare_h     = ref * 0.30;   // height of the bowl's flared foot
bowl_d      = ref * 0.78;   // outer rim diameter (kept under base_width)
bowl_wall_h = ref * 0.62;   // straight bowl wall above the flare

wall        = 3;            // mm, bowl wall thickness (print constraint)
bowl_floor  = ref * 0.10;   // solid thickness between the flare and cavity
inner_round = ref * 0.16;   // radius of the rounded cavity bottom

seat_depth  = 1;            // mm the stem sinks into the base to fuse them
cavity_over = 5;            // mm the cavity overshoots the rim to open it

cup_fn      = 128;          // $fn for the revolved cup surfaces
cup_steps   = 64;           // segments per curved profile section

// 2. Derived dimensions
stem_r  = stem_d / 2;
bowl_r  = bowl_d / 2;
inner_r = bowl_r - wall;

z_flare = stem_h + flare_h;             // flare ends / straight wall begins
cup_top = z_flare + bowl_wall_h;        // outer rim height

cav_z0  = z_flare + bowl_floor;         // cavity floor (stem + flare stay solid)
cav_top = cup_top + cavity_over;        // cavity opens past the rim

assert(inner_r > 0,                   "wall too thick: inner radius <= 0");
assert(cav_z0 + inner_round < cup_top, "bowl too short for its rounded floor");
assert(bowl_r > stem_r,               "bowl_d must be greater than stem_d");

// 3. Profiles (list of [radius, z], revolved around the Z axis)
//    Outer: stem -> cosine-S flare -> straight bowl wall -> closed top.
flare_pts = [ for (i = [1 : cup_steps])
    let (t = i / cup_steps)
    [ stem_r + (bowl_r - stem_r) * (1 - cos(180 * t)) / 2, stem_h + flare_h * t ] ];

outer_profile = concat(
    [ [0, 0], [stem_r, 0], [stem_r, stem_h] ],  // axis -> stem
    flare_pts,                                   // flared foot
    [ [bowl_r, cup_top], [0, cup_top] ]          // bowl wall -> closed top
);

//    Cavity: rounded floor -> straight inner wall -> open past the rim.
//    Sits entirely within the straight bowl wall so the flare stays solid.
cavity_round = [ for (i = [0 : cup_steps])
    let (a = 90 * i / cup_steps)
    [ inner_r * sin(a), cav_z0 + inner_round * (1 - cos(a)) ] ];

cavity_profile = concat(
    cavity_round,                                // rounded inner floor
    [ [inner_r, cav_top], [0, cav_top] ]         // inner wall -> open top
);

// 4. Component module
module trophy_cup() {
    difference() {
        rotate_extrude($fn = cup_fn)
            polygon(outer_profile);
        rotate_extrude($fn = cup_fn)
            polygon(cavity_profile);
    }
}

// 5. Assembly — cup sits on the base platform (total_height from the base file)
translate([0, 0, total_height - seat_depth])
    trophy_cup();
