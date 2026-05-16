// trophy_base_scotia.scad
// Classic trophy base with a scotia profile: flat rectangular step ->
// concave cove -> convex bead -> top platform. Solid of revolution.
// FDM-friendly: largest flat face sits on the build plate.

$fn = 100;

// 1. Constants & parameters
base_width   = 80;  // mm, diameter at bottom
top_width    = 50;  // mm, diameter at top platform
total_height = 40;  // mm

step_frac    = 0.18;  // bottom flat rectangular step, fraction of height
cove_frac    = 0.42;  // concave curve, fraction of height
bead_frac    = 0.28;  // convex curve, fraction of height
// remaining fraction -> top platform

waist_inset  = 6;   // mm the cove pinches inward past the top radius
arc_steps    = 48;  // points generated per curved segment

// 2. Derived dimensions
base_r = base_width / 2;
top_r  = top_width  / 2;

step_h     = total_height * step_frac;
cove_h     = total_height * cove_frac;
bead_h     = total_height * bead_frac;
platform_h = total_height - step_h - cove_h - bead_h;

waist_r = top_r - waist_inset;

assert(base_r > top_r,    "base_width must be greater than top_width");
assert(platform_h >= 0,   "step+cove+bead fractions exceed 1.0");
assert(waist_r > 0,       "waist_inset too large: waist radius <= 0");

// 3. Component module
module trophy_base_scotia() {
    // Cove: concave quarter-ellipse, vertical tangent at the step,
    // horizontal tangent at the waist. Radius shrinks base_r -> waist_r.
    cove_pts = [ for (i = [0 : arc_steps])
        let (a = i * 90 / arc_steps)
        [ waist_r + (base_r - waist_r) * cos(a),
          step_h + cove_h * sin(a) ] ];

    // Bead: convex quarter-ellipse, vertical tangent at the waist,
    // horizontal tangent at the platform. Radius grows waist_r -> top_r.
    bead_pts = [ for (i = [1 : arc_steps])
        let (a = i * 90 / arc_steps)
        [ waist_r + (top_r - waist_r) * sin(a),
          step_h + cove_h + bead_h * (1 - cos(a)) ] ];

    profile = concat(
        [ [0, 0], [base_r, 0] ],          // axis -> base, flat bottom
        cove_pts,                          // first point is (base_r, step_h)
        bead_pts,
        [ [top_r, total_height],           // platform wall
          [0, total_height] ]              // close along the axis
    );

    rotate_extrude($fn = 100)
        polygon(profile);
}

// 4. Assembly
//    `show_base` is set by trophy_cup.scad when this file is `include`d.
//    Undefined here means the file is opened standalone -> render.
if (is_undef(show_base) || show_base)
    trophy_base_scotia();
