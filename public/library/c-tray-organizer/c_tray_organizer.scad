// Parametric barber tray organizer inspired by the supplied reference image.
// All dimensions are in millimetres. The organizer prints as one connected part.

/* [Overall Size] */
organizer_width_mm = 230; // [180:5:300]
organizer_depth_mm = 170; // [130:5:240]
base_thickness_mm = 4; // [2:0.5:8]
wall_thickness_mm = 2.4; // [1.2:0.2:4]
corner_radius_mm = 7; // [2:0.5:14]

/* [Clipper Compartments] */
clipper_columns = 3; // [1:1:4]
clipper_rows = 2; // [1:1:3]
clipper_area_width_mm = 150; // [100:5:190]
clipper_area_depth_mm = 98; // [65:5:125]
clipper_wall_height_mm = 62; // [25:1:100]

/* [Scissor Holder] */
scissor_count = 6; // [1:1:12]
scissor_hole_diameter_mm = 17; // [10:0.5:28]
scissor_holder_width_mm = 66; // [45:1:90]
scissor_holder_depth_mm = 98; // [60:1:125]
scissor_holder_height_mm = 60; // [25:1:100]
scissor_hole_clearance_mm = 7; // [2:0.5:14]

/* [Comb Rack] */
comb_slots = 11; // [4:1:20]
comb_rack_width_mm = 145; // [90:5:185]
comb_rack_depth_mm = 42; // [25:1:65]
comb_rack_height_mm = 32; // [15:1:65]
comb_slot_width_mm = 3; // [1:0.5:8]

/* [Brush Cup] */
brush_box_width_mm = 66; // [45:1:90]
brush_box_depth_mm = 42; // [25:1:65]
brush_box_height_mm = 30; // [15:1:65]

/* [Name Plate] */
show_name_plate = true;
name_text = "PERSONALIZE";
// Choose a font installed on this device in the FormForge font menu.
font_name = "Liberation Serif:style=Bold";
name_size_mm = 13; // [6:0.5:22]
name_plate_width_mm = 150; // [90:5:190]
name_plate_height_mm = 30; // [15:1:50]
name_plate_thickness_mm = 3; // [1:0.5:6]
show_name_rules = true;

/* [Colors] */
organizer_color = "Black"; // [Black, Gray, White, Blue, Green, Red, Orange]
name_color = "White"; // [White, Black, Yellow, Blue, Green, Red]

$fn = 40;

module rounded_rect_2d(width, depth, radius) {
    offset(r = radius)
        square([max(0.1, width - 2 * radius), max(0.1, depth - 2 * radius)], center = true);
}

module rounded_prism(width, depth, height, radius) {
    linear_extrude(height = height)
        rounded_rect_2d(width, depth, min(radius, min(width, depth) / 2 - 0.1));
}

module open_bin(width, depth, height, radius = corner_radius_mm) {
    difference() {
        rounded_prism(width, depth, height, radius);
        translate([0, 0, base_thickness_mm])
            linear_extrude(height = height + 0.1)
                rounded_rect_2d(
                    width - 2 * wall_thickness_mm,
                    depth - 2 * wall_thickness_mm,
                    max(0.4, radius - wall_thickness_mm)
                );
    }
}

module clipper_bin() {
    inner_width = clipper_area_width_mm - 2 * wall_thickness_mm;
    inner_depth = clipper_area_depth_mm - 2 * wall_thickness_mm;
    cell_width = inner_width / clipper_columns;
    cell_depth = inner_depth / clipper_rows;

    union() {
        open_bin(clipper_area_width_mm, clipper_area_depth_mm, clipper_wall_height_mm);

        // Internal dividers form a configurable grid of storage bays.
        if (clipper_columns > 1)
            for (i = [1 : clipper_columns - 1])
                translate([-inner_width / 2 + i * cell_width - wall_thickness_mm / 2, -inner_depth / 2, base_thickness_mm])
                    cube([wall_thickness_mm, inner_depth, clipper_wall_height_mm - base_thickness_mm]);
        if (clipper_rows > 1)
            for (i = [1 : clipper_rows - 1])
                translate([-inner_width / 2, -inner_depth / 2 + i * cell_depth - wall_thickness_mm / 2, base_thickness_mm])
                    cube([inner_width, wall_thickness_mm, clipper_wall_height_mm - base_thickness_mm]);
    }
}

function grid_cols(count) = min(2, count);
function grid_rows(count) = ceil(count / grid_cols(count));

module scissor_holder() {
    cols = grid_cols(scissor_count);
    rows = grid_rows(scissor_count);
    usable_width = scissor_holder_width_mm - 2 * wall_thickness_mm;
    usable_depth = scissor_holder_depth_mm - 2 * wall_thickness_mm;
    pitch_x = cols > 1 ? min(scissor_hole_diameter_mm + scissor_hole_clearance_mm, usable_width / (cols - 1)) : 0;
    pitch_y = rows > 1 ? min(scissor_hole_diameter_mm + scissor_hole_clearance_mm, usable_depth / (rows - 1)) : 0;

    difference() {
        rounded_prism(scissor_holder_width_mm, scissor_holder_depth_mm, scissor_holder_height_mm, corner_radius_mm);
        for (i = [0 : scissor_count - 1]) {
            col = i % cols;
            row = floor(i / cols);
            x = (col - (cols - 1) / 2) * pitch_x;
            y = (row - (rows - 1) / 2) * pitch_y;
            translate([x, y, base_thickness_mm])
                cylinder(d = scissor_hole_diameter_mm,
                    h = max(1, scissor_holder_height_mm - base_thickness_mm + 0.1), $fn = 48);
        }
    }
}

module comb_rack() {
    inner_width = comb_rack_width_mm - 2 * wall_thickness_mm;
    inner_depth = comb_rack_depth_mm - 2 * wall_thickness_mm;
    rib_thickness = max(1.2, wall_thickness_mm * 0.7);
    rib_pitch = inner_width / comb_slots;

    union() {
        open_bin(comb_rack_width_mm, comb_rack_depth_mm, comb_rack_height_mm, min(4, corner_radius_mm));
        // Thin ribs divide the open trough into narrow comb slots.
        if (comb_slots > 1)
            for (i = [1 : comb_slots - 1])
                translate([-inner_width / 2 + i * rib_pitch - rib_thickness / 2, -inner_depth / 2, base_thickness_mm])
                    cube([rib_thickness, inner_depth, comb_rack_height_mm - base_thickness_mm]);
    }
}

module brush_box() {
    open_bin(brush_box_width_mm, brush_box_depth_mm, brush_box_height_mm, min(5, corner_radius_mm));
}

module name_plate() {
    if (show_name_plate) {
        plate_width = min(name_plate_width_mm, organizer_width_mm - 16);
        plate_height = min(name_plate_height_mm, organizer_depth_mm / 3);
        front_y = -organizer_depth_mm / 2;

        // The plate overlaps the base and the front accessories to print as one body.
        color(organizer_color)
            translate([0, front_y + name_plate_thickness_mm / 2, base_thickness_mm + plate_height / 2])
                cube([plate_width, name_plate_thickness_mm, plate_height], center = true);

        if (name_text != "")
            color(name_color)
                translate([0, front_y - 0.01, base_thickness_mm + plate_height / 2])
                    rotate([90, 0, 0])
                        linear_extrude(height = 0.8)
                            text(name_text, size = name_size_mm, font = font_name,
                                halign = "center", valign = "center", spacing = 1.05);

        if (show_name_rules)
            color(name_color)
                for (z_offset = [-plate_height * 0.34, plate_height * 0.34])
                    translate([0, front_y - 0.01, base_thickness_mm + plate_height / 2 + z_offset])
                        rotate([90, 0, 0])
                            linear_extrude(height = 0.8)
                                square([plate_width * 0.82, 0.9], center = true);
    }
}

// Shared positioning keeps the rear bays, front rack and cups inside the base.
clipper_x = -scissor_holder_width_mm / 2 - 7;
scissor_x = organizer_width_mm / 2 - scissor_holder_width_mm / 2 - 7;
rear_y = organizer_depth_mm / 2 - max(clipper_area_depth_mm, scissor_holder_depth_mm) / 2 - 7;
front_accessory_y = -organizer_depth_mm / 2 + max(comb_rack_depth_mm, brush_box_depth_mm) / 2 + 12;
comb_x = -organizer_width_mm / 2 + 7 + comb_rack_width_mm / 2;
brush_x = organizer_width_mm / 2 - brush_box_width_mm / 2 - 7;

union() {
    color(organizer_color)
        rounded_prism(organizer_width_mm, organizer_depth_mm, base_thickness_mm, corner_radius_mm);

    color(organizer_color) {
        translate([clipper_x, rear_y, base_thickness_mm]) clipper_bin();
        translate([scissor_x, rear_y, base_thickness_mm]) scissor_holder();
        translate([comb_x, front_accessory_y, base_thickness_mm]) comb_rack();
        translate([brush_x, front_accessory_y, base_thickness_mm]) brush_box();
    }

    name_plate();
}
