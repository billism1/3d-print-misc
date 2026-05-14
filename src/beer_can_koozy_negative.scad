// Beer Can Koozy – Interior Negative / Full Body
//
// Generates the void to subtract from a koozy body with difference().
// Sized for a standard 12 oz (355 ml) aluminium can.

// ── Parameters ────────────────────────────────────────────────────────────────
show_koozy       = false;  // true = full koozy body; false = negative only

can_od           = 66.0;  // mm – nominal 12 oz can outer diameter
can_h            = 122.0; // mm – nominal 12 oz can height
radial_clearance = 0.2;   // mm – added to radius; snug sliding fit
bottom_clearance = 1.5;   // mm – extra depth below can bottom (accounts for base dome)
dome_d           = 38.0;  // mm – diameter of inset dome on can base
dome_h           = 5.0;   // mm – depth of dome recess needed
bottom_fillet_r  = 4.0;   // mm – radius of rounded bottom edge on main bore

wall             = 2.0;   // mm – radial wall and floor thickness
koozy_h          = 118.0; // mm – total koozy outer height
outer_fillet_r   = 6.0;   // mm – radius of rounded outer bottom edge
bottom_hole_d    = 12.0;  // mm – centre drain hole through koozy floor (0 = none)

$fn = 180;

// ── Derived ───────────────────────────────────────────────────────────────────
cutout_d = can_od + 2 * radial_clearance;
cutout_h = can_h  + bottom_clearance;
koozy_od = cutout_d + 2 * wall;

assert(radial_clearance >= 0.2,          "radial_clearance too tight – can won't insert");
assert(dome_d < cutout_d,                "dome_d must be smaller than cutout_d");
assert(bottom_fillet_r < cutout_d / 2,  "bottom_fillet_r must be smaller than bore radius");
assert(outer_fillet_r < koozy_od / 2,   "outer_fillet_r must be smaller than koozy outer radius");
assert(outer_fillet_r > 0,              "outer_fillet_r must be positive");

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

// ── Koozy Body ────────────────────────────────────────────────────────────────
//
// Outer shell with rounded bottom edge. Interior cavity shifted up by floor
// thickness (wall) so the bottom plate is solid. Top is open – the negative
// extends above koozy_h so difference() exits cleanly.

module can_koozy() {
    difference() {
        // Outer shell with rounded bottom edge
        hull() {
            translate([0, 0, outer_fillet_r])
                cylinder(d = koozy_od, h = koozy_h - outer_fillet_r);
            rotate_extrude()
                translate([koozy_od / 2 - outer_fillet_r, outer_fillet_r])
                    circle(r = outer_fillet_r);
        }

        // Interior cavity shifted up by floor thickness
        translate([0, 0, wall])
            can_koozy_negative();

        // Centre drain hole through floor
        if (bottom_hole_d > 0)
            translate([0, 0, -0.01])
                cylinder(d = bottom_hole_d, h = wall + 0.02);
    }
}

// ── Render ────────────────────────────────────────────────────────────────────
if (show_koozy) can_koozy();
else            can_koozy_negative();
