// Trophy Base with Scotia Profile
// A classic trophy base featuring a smooth scotia (cove) and bead profile
// Created: 2026-05-16

// ============================================================================
// PARAMETERS - Adjust these to customize the trophy base
// ============================================================================

// Overall dimensions
base_width = 80;        // Width of the base platform (bottom)
top_width = 60;         // Width of the top platform
total_height = 50;      // Total height of the base

// Profile proportions (as fractions of total height)
step_height = 0.12;     // Height of the bottom rectangular step
cove_height = 0.25;     // Height of the concave cove section
bead_height = 0.20;     // Height of the convex bead section
platform_height = 0.13; // Height of the top platform

// Curve parameters
cove_depth = 5;         // Maximum depth of the cove curve
bead_height_profile = 4; // Maximum height of the bead curve

// Smoothness
$fn = 100;              // Fragment count for smooth curves

// ============================================================================
// MAIN MODULE
// ============================================================================

module trophy_base(
    base_w = base_width,
    top_w = top_width,
    height = total_height,
    step_h = step_height,
    cove_h = cove_height,
    bead_h = bead_height,
    platform_h = platform_height,
    cove_d = cove_depth,
    bead_h_prof = bead_height_profile
) {
    // Calculate absolute heights from parameters
    step_abs = height * step_h;
    cove_abs = height * cove_h;
    bead_abs = height * bead_h;
    platform_abs = height * platform_h;
    
    // Validate heights sum to reasonable total
    total_profile_height = step_abs + cove_abs + bead_abs + platform_abs;
    
    // Create the 2D profile
    profile_points = create_profile_points(
        base_w, top_w,
        step_abs, cove_abs, bead_abs, platform_abs,
        cove_d, bead_h_prof
    );
    
    // Rotate the profile around the Z-axis to create a 3D trophy base
    rotate_extrude(angle=360, $fn=$fn) {
        polygon(profile_points);
    }
}

// ============================================================================
// PROFILE CREATION FUNCTION
// ============================================================================

function create_profile_points(
    base_w, top_w,
    step_h, cove_h, bead_h, platform_h,
    cove_d, bead_h_prof
) = let(
    // Calculate radii for smooth transitions
    // Base width is diameter, so radius = width / 2
    base_r = base_w / 2,
    top_r = top_w / 2,
    
    // Horizontal transition distance
    horizontal_taper = (base_r - top_r) / 2,
    
    // Current Y position as we build the profile
    y0 = 0,
    y1 = y0 + step_h,
    y2 = y1 + cove_h,
    y3 = y2 + bead_h,
    y4 = y3 + platform_h,
    
    // Cove parameters (concave curve)
    cove_radius = (cove_h * cove_h + cove_d * cove_d) / (2 * cove_d),
    cove_center_x = base_r - horizontal_taper * step_h / step_h - cove_d + cove_radius,
    cove_center_y = y1 + cove_radius,
    
    // Bead parameters (convex curve)
    bead_radius = (bead_h * bead_h + bead_h_prof * bead_h_prof) / (2 * bead_h_prof),
    bead_center_x = top_r + horizontal_taper * (step_h + cove_h) / (step_h + cove_h) - bead_h_prof + bead_radius,
    bead_center_y = y2 + bead_radius,
    
    // Generate points for each section
    // Bottom step
    p0 = [base_r, y0],
    p1 = [base_r, y1],
    
    // Cove (concave) section - quarter circle curving inward and upward
    cove_points = [
        for (i = [0 : $fn / 4])
            let (
                angle = i * 90 / ($fn / 4),
                rad = radians(angle),
                x = cove_center_x + cove_radius * cos(90 + angle),
                y = cove_center_y - cove_radius + cove_radius * sin(angle)
            )
            [x, y]
    ],
    
    // Bead (convex) section - quarter circle curving outward and upward
    bead_points = [
        for (i = [0 : $fn / 4])
            let (
                angle = i * 90 / ($fn / 4),
                x = bead_center_x - bead_h_prof + bead_h_prof * cos(angle),
                y = bead_center_y - bead_radius + bead_radius * sin(angle)
            )
            [x, y]
    ],
    
    // Top platform
    p_top_inner = [top_r, y4],
    p_top_outer = [top_r, y4],
    p_top_inner_bot = [top_r, y3 + platform_h * 0.1],
    
    // Inner edge points (for solid profile)
    inner_top = [0, y4],
    inner_mid = [0, y0],
    
    // Build complete point list
    all_points = concat(
        [[0, y0]],           // Center bottom
        [p0],                // Outer bottom
        [p1],                // Bottom of cove
        cove_points,         // Cove curve
        bead_points,         // Bead curve
        [[top_r, y4]],       // Top outer
        [[0, y4]],           // Top center
        [[0, y0]]            // Close profile
    )
) all_points;

// ============================================================================
// ALTERNATIVE: LINEAR EXTRUDE VERSION (flat trophy base)
// ============================================================================

module trophy_base_flat(
    base_w = base_width,
    top_w = top_width,
    height = total_height,
    depth = 100,           // Depth when using linear extrude
    step_h = step_height,
    cove_h = cove_height,
    bead_h = bead_height,
    platform_h = platform_height,
    cove_d = cove_depth,
    bead_h_prof = bead_height_profile
) {
    linear_extrude(height = depth, $fn = $fn) {
        polygon(create_profile_2d(
            base_w, top_w,
            height * step_h,
            height * cove_h,
            height * bead_h,
            height * platform_h,
            cove_d,
            bead_h_prof
        ));
    }
}

function create_profile_2d(
    base_w, top_w,
    step_h, cove_h, bead_h, platform_h,
    cove_d, bead_h_prof
) = let(
    // Y positions
    y0 = 0,
    y1 = y0 + step_h,
    y2 = y1 + cove_h,
    y3 = y2 + bead_h,
    y4 = y3 + platform_h,
    
    // X positions (width)
    x_base = base_w / 2,
    x_top = top_w / 2,
    
    // Transition width
    transition = (x_base - x_top) / 2,
    
    // Cove curve parameters
    cove_radius = (cove_h * cove_h + cove_d * cove_d) / (2 * cove_d),
    cove_x_start = x_base - transition * (step_h / (step_h + cove_h + bead_h)),
    
    // Bead curve parameters
    bead_radius = (bead_h * bead_h + bead_h_prof * bead_h_prof) / (2 * bead_h_prof),
    
    // Generate cove points (concave)
    cove_pts = [
        for (i = [0 : $fn / 4])
            let(
                angle = i * 90 / ($fn / 4),
                x = cove_x_start - cove_d + cove_d * cos(angle),
                y = y1 + cove_h * sin(angle)
            )
            [x, y]
    ],
    
    // Generate bead points (convex)
    bead_start_x = x_top + transition * (cove_h / (cove_h + bead_h)),
    bead_pts = [
        for (i = [0 : $fn / 4])
            let(
                angle = i * 90 / ($fn / 4),
                x = bead_start_x - bead_h_prof * sin(angle),
                y = y2 + bead_h_prof * cos(angle)
            )
            [x, y]
    ]
) concat(
    [[x_base, y0]],     // Bottom outer
    [[x_base, y1]],     // Start of cove
    cove_pts,            // Cove curve
    bead_pts,            // Bead curve
    [[x_top, y4]],      // Top outer
    [[x_top, y0]]       // Close profile
);

// ============================================================================
// EXAMPLE USAGE
// ============================================================================

// Uncomment one of these to see the result:

// Standard trophy base (rotated around center axis)
trophy_base();

// Flat version (good for testing profile shape)
// translate([150, 0, 0])
// trophy_base_flat(depth = 120);

// Custom scaled version
// translate([300, 0, 0])
// trophy_base(
//     base_w = 100,
//     top_w = 70,
//     height = 60,
//     cove_d = 8,
//     bead_h_prof = 6
// );
