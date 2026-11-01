// Parametric Gridfinity-style hex tray inspired by the supplied reference.
// Dimensions are in millimetres. The tray has a closed floor and optional
// tapered feet; hexagonal openings can be enabled on all four upright walls.

/* [Tray Size] */
// Number of 42 mm Gridfinity cells across the tray.
grid_x = 5; // [1:1:10]
// Number of 42 mm Gridfinity cells from front to back.
grid_y = 2; // [1:1:10]
// Overall height from the build plate to the top rim, including the feet.
height_mm = 35; // [14:7:70]

/* [Walls] */
wall_style = "Hexagonal"; // [Hexagonal, Solid]
wall_thickness_mm = 1.2; // [0.8:0.1:3]
// Maximum width across each hexagonal opening.
hex_opening_mm = 8; // [4:0.5:14]
// Minimum material left between neighbouring openings.
hex_spacing_mm = 3.5; // [1:0.5:8]
// Increase the number of hex openings while keeping the tray dimensions fixed.
// Higher values make each opening and its spacing proportionally smaller.
hex_multiplier = 1; // [1:1:4]
// Solid border above the floor and below the rim.
wall_border_mm = 4; // [2:0.5:10]

/* [Floor] */
floor_thickness_mm = 1.2; // [0.8:0.1:4]
corner_radius_mm = 3.75; // [1:0.25:8]

/* [Gridfinity Feet] */
show_gridfinity_feet = true;
foot_height_mm = 4.75; // [0:0.25:8]
foot_bottom_inset_mm = 2.0; // [0:0.25:5]
foot_corner_radius_mm = 3.75; // [1:0.25:8]

/* [Colors] */
tray_color = "Teal"; // [Teal, White, Black, Gray, Blue, Green, Orange, Red]

$fn = 32;

cell_pitch_mm = 42;
outer_width_mm = grid_x * cell_pitch_mm;
outer_depth_mm = grid_y * cell_pitch_mm;
actual_foot_height_mm = show_gridfinity_feet ? min(foot_height_mm, max(0, height_mm - floor_thickness_mm - 1)) : 0;
floor_z_mm = actual_foot_height_mm + floor_thickness_mm;
wall_height_mm = max(1, height_mm - floor_z_mm);
actual_corner_radius_mm = min(corner_radius_mm, min(outer_width_mm, outer_depth_mm) / 2 - 0.1);

module rounded_rect_2d(width, depth, radius) {
    offset(r = radius)
        square([max(0.1, width - 2 * radius), max(0.1, depth - 2 * radius)], center = true);
}

module tray_shell() {
    difference() {
        // Outer walls rise from the closed floor to the full tray height.
        translate([0, 0, floor_z_mm])
            linear_extrude(height = wall_height_mm)
                rounded_rect_2d(outer_width_mm, outer_depth_mm, actual_corner_radius_mm);

        // Hollow interior. Starting just below the wall keeps the floor closed.
        translate([0, 0, floor_z_mm - 0.05])
            linear_extrude(height = wall_height_mm + 0.1)
                rounded_rect_2d(
                    outer_width_mm - 2 * wall_thickness_mm,
                    outer_depth_mm - 2 * wall_thickness_mm,
                    max(0.2, actual_corner_radius_mm - wall_thickness_mm)
                );

        if (wall_style == "Hexagonal") hex_wall_openings();
    }
}

module hex_wall_openings() {
    base_opening = min(hex_opening_mm, max(2, min(cell_pitch_mm, height_mm) - 2 * wall_border_mm));
    count_multiplier = max(1, hex_multiplier);
    opening = base_opening / count_multiplier;
    step = (base_opening + hex_spacing_mm) / count_multiplier;
    usable_height = max(0, height_mm - floor_z_mm - 2 * wall_border_mm);
    rows = max(0, floor(usable_height / step));
    long_count = max(0, floor((outer_width_mm - 2 * wall_border_mm) / step));
    short_count = max(0, floor((outer_depth_mm - 2 * wall_border_mm) / step));

    // Hexagonal punches through the front and back walls.
    for (row = [0 : rows])
        for (col = [0 : long_count]) {
            x = (col - long_count / 2) * step + ((row % 2) * step / 2);
            z = floor_z_mm + wall_border_mm + opening / 2 + row * step;
            if (abs(x) <= outer_width_mm / 2 - wall_border_mm && z + opening / 2 <= height_mm - wall_border_mm)
                for (side = [-1, 1])
                    translate([x, side * (outer_depth_mm / 2), z])
                        rotate([90, 0, 0])
                            cylinder(d = opening, h = wall_thickness_mm + 2, center = true, $fn = 6);
        }

    // Hexagonal punches through the left and right end walls.
    for (row = [0 : rows])
        for (col = [0 : short_count]) {
            y = (col - short_count / 2) * step + ((row % 2) * step / 2);
            z = floor_z_mm + wall_border_mm + opening / 2 + row * step;
            if (abs(y) <= outer_depth_mm / 2 - wall_border_mm && z + opening / 2 <= height_mm - wall_border_mm)
                for (side = [-1, 1])
                    translate([side * (outer_width_mm / 2), y, z])
                        rotate([0, 90, 0])
                            cylinder(d = opening, h = wall_thickness_mm + 2, center = true, $fn = 6);
        }
}

module gridfinity_foot(x, y) {
    foot_width = cell_pitch_mm - 0.5;
    bottom_width = max(foot_width - 2 * foot_bottom_inset_mm, 20);
    radius = min(foot_corner_radius_mm, foot_width / 4);
    if (actual_foot_height_mm > 0)
        color(tray_color)
            hull() {
                translate([x, y, 0])
                    linear_extrude(height = 0.05)
                        rounded_rect_2d(bottom_width, bottom_width, min(radius, bottom_width / 4));
                translate([x, y, actual_foot_height_mm - 0.05])
                    linear_extrude(height = 0.05)
                        rounded_rect_2d(foot_width, foot_width, radius);
            }
}

module feet() {
    if (show_gridfinity_feet)
        for (x_index = [0 : grid_x - 1])
            for (y_index = [0 : grid_y - 1])
                gridfinity_foot(
                    (x_index - (grid_x - 1) / 2) * cell_pitch_mm,
                    (y_index - (grid_y - 1) / 2) * cell_pitch_mm
                );
}

union() {
    color(tray_color) {
        // Closed bottom sits directly above the feet.
        translate([0, 0, actual_foot_height_mm])
            linear_extrude(height = floor_thickness_mm)
                rounded_rect_2d(outer_width_mm, outer_depth_mm, actual_corner_radius_mm);
        tray_shell();
    }
    feet();
}
