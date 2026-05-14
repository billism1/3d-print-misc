// ============================================================
// Flashlight Shim / Tail Holder
// Wraps tail end of flashlight; inserts into 18.92 mm bore.
// Split in half along XZ plane before printing; join two halves
// around the physical flashlight after printing.
//
// Orientation: flange (tail/button end) at z=0,
//              insertion tip (light end) at z=top.
// ============================================================

// --- 1. Parameters ---

// Flashlight body sections (tail toward light end)
fl_tail_dia  = 15.0;  // mm — tail section outer dia
fl_tail_len  = 14.0;  // mm — axial length of tail section
fl_fwd_dia   = 14.0;  // mm — forward (light-side) section outer dia
fl_fwd_grip  =  5.0;  // mm — axial grip on forward section

// Receiving cylinder
bore_id      = 18.92; // mm — inner dia of cylinder shim inserts into
bore_wall    =  3.3;  // mm — wall thickness of receiving cylinder (reference)

// Fit allowances
fl_gap       =  0.2;  // mm — diametric clearance on flashlight body
bore_gap     =  0.3;  // mm — diametric clearance for shim inside bore

// Flange — sits on bore entry face, prevents shim from falling in
flange_od    = 22.0;  // mm — must exceed bore_id
flange_h     =  3.0;  // mm — axial thickness

// Lead-in chamfer at insertion tip
chamfer      =  0.5;  // mm — outer edge chamfer depth at forward tip

// Inner bore step taper
bore_taper_deg = 30;  // degrees from Z axis; replaces 90° ledge for printability

// Half-model for printing (cut along XZ plane, Y≥0 half kept)
half_model   = true;  // true = one half; false = full shim

// --- 2. Derived dimensions ---
shim_od   = bore_id - bore_gap;         // 18.62 mm — insertable body OD
inner_big = fl_tail_dia + fl_gap;       // 15.4  mm — bore for tail section
inner_sml = fl_fwd_dia  + fl_gap;       // 14.4  mm — bore for forward section
body_len  = fl_tail_len + fl_fwd_grip;  // 21    mm — total insertable body length
step_r    = (inner_big - inner_sml) / 2;               // 0.5  mm — bore radius delta
step_h    = step_r / tan(bore_taper_deg);              // ~0.866 mm — taper axial height

$fn = 64;

// --- 3. Guards ---
assert(flange_od > bore_id,  "flange_od must exceed bore_id to act as stop");
assert(shim_od   < bore_id,  "shim OD must fit inside bore");
assert(shim_od   > inner_big,"shim wall thickness must be positive");

// --- 4. Shim module ---
module flashlight_shim() {
    difference() {
        // Outer solid
        union() {
            // Flange — bears on entry face of receiving cylinder
            cylinder(d = flange_od, h = flange_h);

            // Cylindrical body — inserts into bore
            translate([0, 0, flange_h])
                cylinder(d = shim_od, h = body_len - chamfer);

            // Lead-in chamfer at insertion tip (eases entry into bore)
            translate([0, 0, flange_h + body_len - chamfer])
                cylinder(d1 = shim_od, d2 = shim_od - 2 * chamfer,
                         h = chamfer + 0.01);
        }

        // Inner bore — stepped to match flashlight profile
        // Tail section bore (wider, up to taper start)
        translate([0, 0, -0.01])
            cylinder(d = inner_big,
                     h = flange_h + fl_tail_len - step_h + 0.01);

        // 30° taper: inner_big → inner_sml over step_h
        translate([0, 0, flange_h + fl_tail_len - step_h])
            cylinder(d1 = inner_big, d2 = inner_sml, h = step_h + 0.01);

        // Forward section bore (narrower) — shoulder catches flashlight step
        translate([0, 0, flange_h + fl_tail_len - 0.01])
            cylinder(d = inner_sml,
                     h = fl_fwd_grip + 0.02);
    }
}

// --- 5. Assembly ---
if (half_model) {
    // Keep Y≥0 half; flat face sits on build plate after rotating 90°
    intersection() {
        flashlight_shim();
        translate([-flange_od, 0, -0.01])
            cube([flange_od * 2, flange_od, flange_h + body_len + 0.02]);
    }
} else {
    flashlight_shim();
}
