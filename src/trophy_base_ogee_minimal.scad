// trophy_base_ogee_minimal.scad
// Square trophy base with an ogee side profile. Bottom-up the side reads:
// ogee S-curve (convex then concave) -> straight riser -> convex top
// molding -> straight inward ledge -> smaller convex molding -> flat
// platform. Square footprint, symmetrical about both XY axes.
// FDM-friendly: largest flat face on the build plate, profile narrows
// monotonically with height so there are no overhangs.

$fn = 100;

// 1. Constants & parameters
base_width   = 60;  // mm, square side at the bottom
total_height = 27.5;  // mm

ogee_h       = 10;  // mm, height of the bottom S-curve
ogee_inset   = 7;   // mm each side pulls in across the ogee

riser_h      = 10;  // mm, straight vertical shaft above the ogee

top1_h       = 4.5; // mm, first (larger) convex top molding height
top1_inset   = 4.5; // mm each side pulls in across that molding

ledge_inset  = 1.5; // mm straight horizontal step inward (the shelf)

top2_h       = 3;   // mm, second (smaller) convex molding height
top2_inset   = 3;   // mm each side pulls in across that molding
// remaining height -> flat top platform

arc_steps    = 48;  // segments generated per curved profile section

// 2. Derived dimensions
hw0    = base_width / 2;        // half-width at the base
hw1    = hw0 - ogee_inset;     // half-width of the riser
hw_mid = hw0 - ogee_inset / 2; // half-width at the ogee inflection
z_mid  = ogee_h / 2;           // z of the ogee inflection
hw2 = hw1 - top1_inset;        // half-width after the first molding
hw3 = hw2 - ledge_inset;       // half-width after the ledge
hw4 = hw3 - top2_inset;        // half-width of the platform

z_riser   = ogee_h;                       // ogee ends / riser begins
z_top1    = z_riser + riser_h;            // riser ends / molding 1 begins
z_ledge   = z_top1 + top1_h;              // molding 1 ends / ledge + molding 2
z_top2    = z_ledge + top2_h;             // molding 2 ends / platform begins
platform_h = total_height - z_top2;

assert(hw4 > 0,         "insets too large: platform half-width <= 0");
assert(platform_h >= 0, "height too small: sections exceed total_height");

// 3. Profile (list of [half-width, z], bottom -> top)
//    Ogee bottom convex: quarter-arc, vertical tangent at base → horizontal
//    at inflection. Same formula as the upper moldings — tighter curve.
ogee_conv_pts = [ for (i = [0 : arc_steps])
    let (a = 90 * i / arc_steps)
    [ hw0 - (ogee_inset / 2) * (1 - cos(a)), z_mid * sin(a) ] ];

//    Ogee upper concave: quarter-arc, horizontal tangent at inflection →
//    vertical at riser (smooth blend into the straight shaft).
ogee_conc_pts = [ for (i = [1 : arc_steps])
    let (a = 90 * i / arc_steps)
    [ hw_mid - (ogee_inset / 2) * sin(a), z_mid + z_mid * (1 - cos(a)) ] ];

//    Convex molding 1: vertical tangent at the riser, horizontal at ledge.
top1_pts = [ for (i = [1 : arc_steps])
    let (a = 90 * i / arc_steps)
    [ hw1 - top1_inset * (1 - cos(a)), z_top1 + top1_h * sin(a) ] ];

//    Convex molding 2: horizontal tangent at the ledge, vertical at platform.
top2_pts = [ for (i = [1 : arc_steps])
    let (a = 90 * i / arc_steps)
    [ hw3 - top2_inset * (1 - cos(a)), z_ledge + top2_h * sin(a) ] ];

profile = concat(
    ogee_conv_pts,                  // convex lower arc, ends at [hw_mid, z_mid]
    ogee_conc_pts,                  // concave upper arc, ends at [hw1, z_riser]
    [ [hw1, z_top1] ],              // straight riser
    top1_pts,                       // first convex molding, ends [hw2, z_ledge]
    [ [hw3, z_ledge] ],             // straight inward ledge (horizontal step)
    top2_pts,                       // second convex molding, ends [hw4, z_top2]
    [ [hw4, total_height] ]         // flat platform
);

// 4. Component module
//    Each profile pair extrudes a centered square frustum; stacking the
//    frustums sweeps the profile around the square footprint. Horizontal
//    pairs (the ledge) are skipped — their inward step forms the shelf.
module trophy_base_ogee_minimal() {
    for (i = [0 : len(profile) - 2])
        if (profile[i + 1].y > profile[i].y)
            translate([0, 0, profile[i].y])
                linear_extrude(height = profile[i + 1].y - profile[i].y,
                               scale  = profile[i + 1].x / profile[i].x)
                    square(2 * profile[i].x, center = true);
}

// 5. Assembly
trophy_base_ogee_minimal();
