# OpenSCAD – General FDM 3D Printing Prompt

> Use this prompt for any OpenSCAD work targeting FDM (Fused Deposition Modelling) printers.

## Language Rules

OpenSCAD is a **functional CSG modelling language**, not a general-purpose programming language. Follow these rules exactly:

- **Do NOT use mutable variables** — compute all values at parse time
- **Do NOT use `for()` as control flow** — use it as a geometric generator only
- **Do NOT write functions that return values** — modules produce geometry, not data
- **Use `hull()` for fillets and smooth transitions**, not manual chamfer math
- **Use `let()` for named intermediate values** inside expressions
- **Use `each` to flatten nested lists** in list comprehensions
- **Use `children()`** when a module must operate on geometry passed to it
- **`difference()`, `union()`, `intersection()`** are the core boolean CSG operations — prefer these over complex nested geometry
- **`translate()`, `rotate()`, `scale()`** are transforms — always applied to children, never standalone
- **`$fn` controls curve smoothness** — always set it explicitly; never rely on the default

## FDM Design Principles

### Orientation matters
- The **flat, largest face should sit on the build plate** whenever possible.
- Minimise the need for support material by avoiding large unsupported overhangs.
- Vertical cylindrical holes print well; horizontal ones may need tear-drop or bridging profiles.

### Strength considerations
- **Layer lines are weakest in tension along Z.** Design load-bearing features so forces act across (XY) rather than between layers.
- Add fillets at the base of vertical features to distribute stress and reduce stress-risers.
- Prefer rounded transitions over sharp internal corners to avoid stress concentration.

### Printability guidelines
- Avoid very thin walls (< 2 × nozzle diameter). Typical minimum wall thickness: **0.8–1.2 mm** for a 0.4 mm nozzle.
- Bridging spans should stay under **~50 mm** without support.
- Overhangs up to **~45°** from vertical generally print without support; steeper angles may need chamfers or supports.
- Design snap-fits and living hinges with grain direction (layer orientation) in mind.

## OpenSCAD Cheatsheet

https://openscad.org/cheatsheet/

## Common Patterns

### Rounded rectangle (cube with round XY edges)
```openscad
module rounded_rect(size, r) {
    hull() {
        for (x = [r, size.x - r], y = [r, size.y - r])
            translate([x, y, 0])
                cylinder(r = r, h = size.z);
    }
}
```

### Fillet at base of a vertical feature
```openscad
module base_fillet(r, h) {
    difference() {
        cube([r, r, h]);
        translate([r, r, -0.01])
            cylinder(r = r, h = h + 0.02);
    }
}
```

### Chamfered hole (countersink / printer-friendly top)
```openscad
module chamfered_hole(d, h, chamfer = 0.6) {
    union() {
        cylinder(d = d, h = h);
        translate([0, 0, h - chamfer])
            cylinder(d1 = d, d2 = d + 2 * chamfer, h = chamfer + 0.01);
    }
}
```

### Shell / hollow box
```openscad
module shell(outer, wall) {
    difference() {
        cube(outer);
        translate([wall, wall, wall])
            cube([outer.x - 2*wall, outer.y - 2*wall, outer.z]);
    }
}
```

### Slot (elongated hole)
```openscad
module slot(length, d, h) {
    hull() {
        cylinder(d = d, h = h);
        translate([length, 0, 0])
            cylinder(d = d, h = h);
    }
}
```

### Counterbore hole
```openscad
module counterbore_hole(d_through, d_head, h_total, h_head) {
    union() {
        cylinder(d = d_through, h = h_total + 0.01);
        translate([0, 0, h_total - h_head])
            cylinder(d = d_head, h = h_head + 0.01);
    }
}
```

### Text / label emboss or deboss
```openscad
// Debossed (engraved) text on top surface
module debossed_label(txt, size, depth, font = "Liberation Sans:style=Bold") {
    translate([0, 0, -depth])
        linear_extrude(depth + 0.01)
            text(txt, size = size, font = font, halign = "center", valign = "center");
}
```

### Circular pattern (polar array)
```openscad
module polar_array(n, r) {
    for (i = [0 : n - 1])
        rotate([0, 0, i * 360 / n])
            translate([r, 0, 0])
                children();
}
```

## Tolerances for FDM 3D Printing

| Fit Type | Tolerance | Example |
|----------|-----------|---------|
| Press-fit (tight interference) | +0.1–0.2 mm on ID | `insert_od + 0.15` |
| Snug / sliding fit | +0.2–0.4 mm | `shaft_d + 0.3` |
| Loose / clearance fit | +0.5–1.0 mm | `cable_d + 0.6` |
| Screw through-hole | +0.3–0.5 mm | `M4 → 4.4 mm hole` |
| Self-threading (screw into plastic) | ~85% of nominal | `M4 → 3.4 mm hole` |
| Mating flat surfaces (stacking) | +0.2 mm per axis | offset to prevent binding |
| Lid / cap fit | +0.3–0.5 mm radial clearance | on diameter |

## Recommended `$fn` Values

| Feature | `$fn` | Notes |
|---------|-------|-------|
| Small holes (< 6 mm) | 24–32 | Keeps file size small, holes still round |
| Medium cylinders (6–30 mm) | 48–64 | Good visual smoothness |
| Large curves / decorative | 96–128 | For visible surfaces |
| Hex shapes | 6 | `cylinder(..., $fn=6)` gives a hexagon |
| Quick preview / development | 16–24 | Faster render while iterating |
| Final export | 64–128 | Use higher values for production STL |

## CSG Best Practices

- Always extend cut volumes by **0.01 mm** (epsilon) beyond the surface to avoid z-fighting / coincident faces.
- Keep geometry **manifold** — no zero-thickness walls, no self-intersecting volumes.
- Use `render()` sparingly; it forces CGAL evaluation and slows preview.
- Name modules descriptively (e.g., `mounting_tab()`, `drain_slot()`) and parametrise dimensions at the top of the file.
- Group related constants together and comment units: `wall = 2.5; // mm`.
- Use `assert()` to guard against invalid parameter combinations.

## File Organisation

```
// 1. Constants & parameters
// 2. Derived dimensions
// 3. Helper / utility modules
// 4. Component modules
// 5. Assembly (top-level geometry)
```

Keep the top-level geometry at the **bottom** of the file so that reading top-to-bottom flows from parameters → helpers → final shape.
