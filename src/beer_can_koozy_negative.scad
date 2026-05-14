// Beer Can Koozy – Interior Negative
//
// Generates the void to subtract from a koozy body with difference().
// Sized for a standard 12 oz (355 ml) aluminium can.

// ── Parameters ────────────────────────────────────────────────────────────────
can_od           = 66.0;  // mm – nominal 12 oz can outer diameter
can_h            = 122.0; // mm – nominal 12 oz can height
radial_clearance = 0.8;   // mm – added to radius; easy insert/remove
bottom_clearance = 1.5;   // mm – extra depth below can bottom (accounts for base dome)
dome_d           = 38.0;  // mm – diameter of inset dome on can base
dome_h           = 5.0;   // mm – depth of dome recess needed
bottom_fillet_r  = 4.0;   // mm – radius of rounded bottom edge on main bore

$fn = 164;

// ── Derived ───────────────────────────────────────────────────────────────────
cutout_d = can_od + 2 * radial_clearance;
cutout_h = can_h  + bottom_clearance;

assert(radial_clearance >= 0.5,          "radial_clearance too tight – can won't insert");
assert(dome_d < cutout_d,                "dome_d must be smaller than cutout_d");
assert(bottom_fillet_r < cutout_d / 2,  "bottom_fillet_r must be smaller than bore radius");

// ── Negative Volume ───────────────────────────────────────────────────────────
//
// Main bore: full-height cylinder, bottom edge rounded via hull() with a
//            rotate_extrude quarter-circle profile.
// Dome relief: centred recess at the floor so the base ring of the can seats
//              flush against the koozy floor rather than riding on the dome.

module can_koozy_negative() {
    union() {
        // Bore with rounded bottom edge
        hull() {
            translate([0, 0, bottom_fillet_r])
                cylinder(d = cutout_d, h = cutout_h - bottom_fillet_r);
            rotate_extrude()
                translate([cutout_d / 2 - bottom_fillet_r, bottom_fillet_r])
                    circle(r = bottom_fillet_r);
        }

        // Dome relief – extends slightly below z=0 so difference() cuts clean
        translate([0, 0, -0.01])
            cylinder(d = dome_d, h = dome_h + 0.01);
    }
}

can_koozy_negative();
