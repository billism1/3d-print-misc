// Simple Cup Trophy
// A complete trophy design using the trophy base module
// Features a simple cup/goblet shape mounted on the scotia base
// Created: 2026-05-16

use <trophy_base.scad>

// ============================================================================
// PARAMETERS - Customize the cup trophy
// ============================================================================

// Base parameters
base_width = 80;
base_height = 50;

// Cup/Goblet parameters
cup_height = 80;           // Height of the cup portion
cup_outer_diameter = 50;   // Outer diameter at the top
cup_inner_diameter = 42;   // Inner diameter of the cup opening
cup_wall_thickness = 4;    // Wall thickness of the cup
cup_base_diameter = 35;    // Diameter where cup meets the base

// Stem/connection parameters
stem_diameter = 12;        // Diameter of the stem connecting cup to base
stem_height = 20;          // Height of the connecting stem

// Smoothness
$fn = 100;

// ============================================================================
// MAIN MODULE
// ============================================================================

module simple_cup_trophy(
    base_w = base_width,
    base_h = base_height,
    cup_h = cup_height,
    cup_outer_d = cup_outer_diameter,
    cup_inner_d = cup_inner_diameter,
    wall_thick = cup_wall_thickness,
    cup_base_d = cup_base_diameter,
    stem_d = stem_diameter,
    stem_h = stem_height
) {
    
    // Trophy base (scotia profile, rotated)
    trophy_base(
        base_w = base_w,
        top_w = base_w * 0.75,
        height = base_h
    );
    
    // Stem connecting base to cup
    translate([0, 0, base_h]) {
        cylinder(h = stem_h, d = stem_d, $fn = $fn);
    }
    
    // Cup body
    translate([0, 0, base_h + stem_h]) {
        cup_goblet(
            height = cup_h,
            outer_d = cup_outer_d,
            inner_d = cup_inner_d,
            wall_thickness = wall_thick
        );
    }
}

// ============================================================================
// CUP/GOBLET MODULE
// ============================================================================

module cup_goblet(
    height = cup_height,
    outer_d = cup_outer_diameter,
    inner_d = cup_inner_diameter,
    wall_thickness = cup_wall_thickness
) {
    
    // Calculate radii
    outer_r = outer_d / 2;
    inner_r = inner_d / 2;
    
    // Create cup by difference of outer and inner cylinders with slight taper
    difference() {
        // Outer tapered cup shape
        hull() {
            // Bottom of cup (wider)
            cylinder(h = 0.1, r = outer_r, $fn = $fn);
            // Top of cup (slightly narrower for taper)
            translate([0, 0, height])
                cylinder(h = 0.1, r = outer_r * 0.95, $fn = $fn);
        }
        
        // Inner cavity (hollow cup)
        translate([0, 0, wall_thickness]) {
            hull() {
                // Inner bottom
                cylinder(h = 0.1, r = inner_r, $fn = $fn);
                // Inner top
                translate([0, 0, height - wall_thickness])
                    cylinder(h = 0.1, r = inner_r * 0.98, $fn = $fn);
            }
        }
        
        // Cut off the top to create an open cup
        translate([0, 0, height - wall_thickness])
            cube([outer_d * 2, outer_d * 2, wall_thickness + 5], center = true);
    }
    
    // Add a subtle rim at the top
    translate([0, 0, height - wall_thickness * 0.5]) {
        difference() {
            cylinder(h = wall_thickness, r = outer_r * 0.98, $fn = $fn);
            cylinder(h = wall_thickness, r = inner_r * 1.02, $fn = $fn);
        }
    }
}

// ============================================================================
// EXAMPLE USAGE
// ============================================================================

// Standard simple cup trophy
simple_cup_trophy();

// Custom scaled version
// translate([200, 0, 0])
// simple_cup_trophy(
//     base_w = 100,
//     base_h = 60,
//     cup_h = 100,
//     cup_outer_d = 60,
//     cup_inner_d = 50,
//     wall_thick = 5,
//     stem_d = 15,
//     stem_h = 25
// );

// Large award trophy
// translate([-200, 0, 0])
// simple_cup_trophy(
//     base_w = 120,
//     base_h = 70,
//     cup_h = 120,
//     cup_outer_d = 70,
//     cup_inner_d = 58,
//     wall_thick = 6,
//     stem_d = 18,
//     stem_h = 30
// );
