/* [Bowl] */
// Bowl diameter is measured across the top rim, in centimetres.
bowl_size_cm = 16; // [12:2:18]
model_part = "ALL"; // ["ALL", "BOWL", "TEXT", "LEFT_ICON", "RIGHT_ICON"]
feature_mode = "RAISED"; // ["RAISED", "ENGRAVED"]
show_rear_handle = true;

/* [Text] */
label_text = "LUNA";
font_name = "Liberation Sans:style=Bold";
text_size_mm = 10; // [4:0.5:24]
letter_spacing_mm = 0.5; // [0:0.25:3]
text_offset_x_mm = 0; // [-50:0.5:50]
text_offset_z_mm = 0; // [-8:0.5:8]

/* [Left icon] */
show_left_icon = true;
icon_left_file = "";
icon_left_size_mm = 18; // [6:1:30]
icon_left_scale = 1.0; // [0.2:0.05:2.5]
icon_left_offset_x_mm = -46; // [-70:0.5:70]
icon_left_offset_z_mm = 0; // [-8:0.5:8]

/* [Right icon] */
show_right_icon = true;
icon_right_file = "";
icon_right_size_mm = 18; // [6:1:30]
icon_right_scale = 1.0; // [0.2:0.05:2.5]
icon_right_offset_x_mm = 46; // [-70:0.5:70]
icon_right_offset_z_mm = 0; // [-8:0.5:8]

/* [Print details] */
relief_height_mm = 1; // [0.4:0.1:2]
engraving_depth_mm = 0.8; // [0.4:0.1:2]
feature_overlap_mm = 0.15; // [0.05:0.05:0.4]

/* [Colors] */
bowl_color = "Silver"; // ["Silver", "White", "Black", "Gray", "Red", "Orange", "Blue", "Green", "Purple"]
text_color = "Black"; // ["Black", "White", "Red", "Orange", "Blue", "Green", "Purple", "Silver"]
icon_left_color = "Red"; // ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Black", "White"]
icon_right_color = "Blue"; // ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Black", "White"]

$fn = 64;

scale_factor = bowl_size_cm * 10 / 144.852;
label_z_mm = 40 * scale_factor + text_offset_z_mm;

function source_z(world_z_mm) = world_z_mm / scale_factor - 80;
function wall_radius(world_z_mm) =
    scale_factor * (
        82.358 +
        (source_z(world_z_mm) + 70) * (75.32 - 82.358) / (-7.307 + 70)
    );

function glyph_width_factor(character) =
    character == " " ? 0.34 :
    (character == "i" || character == "l" || character == "I" ||
     character == "1" || character == "." || character == "," ||
     character == "!" || character == ":" || character == ";" ||
     character == "'" || character == "|") ? 0.34 :
    (character == "m" || character == "w" || character == "M" ||
     character == "W" || character == "@") ? 0.9 :
    (character == "f" || character == "r" || character == "t") ? 0.46 :
    0.62;

function glyph_advance(character) =
    text_size_mm * glyph_width_factor(character) + letter_spacing_mm;
function label_advance(index = 0) =
    index >= len(label_text) ? 0 :
    glyph_advance(label_text[index]) + label_advance(index + 1);

module bowl_geometry() {
    color(bowl_color)
        scale([scale_factor, scale_factor, scale_factor])
            difference() {
                rotate_extrude(convexity = 10)
                    polygon(points = [
                        [65.695, 10],
                        [60, 10],
                        [60, 0],
                        [72.358, 0],
                        [77.358, 1.34],
                        [81.018, 5],
                        [82.358, 10],
                        [75.32, 72.693],
                        [75.16, 73.38],
                        [74.84, 74.01],
                        [74.37, 74.54],
                        [73.8, 74.95],
                        [73.14, 75.2],
                        [72.426, 75.289],
                        [70.259, 75.289],
                        [70.263, 72.277],
                        [65.658, 72.277],
                        [73.62, 19.202],
                        [73.708, 18.014],
                        [72.63, 14.01],
                        [69.7, 11.07]
                    ]);
                if (show_rear_handle)
                    translate([0, 60, 45])
                        rotate([90, 0, 0])
                            linear_extrude(height = 60, center = true, convexity = 4)
                                hull() {
                                    translate([-29.302, 0]) circle(r = 13.006);
                                    translate([29.302, 0]) circle(r = 13.006);
                                }
            }
}

module text_glyph(character, angle_deg, height_mm, inset_mm, extrusion_mm) {
    radius = wall_radius(height_mm);
    translate([radius * sin(angle_deg), -radius * cos(angle_deg), height_mm])
        rotate([0, 0, angle_deg])
            rotate([90, 0, 0])
                translate([0, 0, -inset_mm])
                    linear_extrude(height = extrusion_mm, convexity = 10)
                        text(
                            character,
                            size = text_size_mm,
                            font = font_name,
                            halign = "center",
                            valign = "center"
                        );
}

module text_glyphs(index, cursor_mm, inset_mm, extrusion_mm) {
    if (index < len(label_text)) {
        character = label_text[index];
        advance_mm = glyph_advance(character);
        radius = wall_radius(label_z_mm);
        arc_mm = text_offset_x_mm + cursor_mm + advance_mm / 2;
        angle_deg = arc_mm / radius * 180 / PI;

        text_glyph(character, angle_deg, label_z_mm, inset_mm, extrusion_mm);
        text_glyphs(index + 1, cursor_mm + advance_mm, inset_mm, extrusion_mm);
    }
}

module text_object(cutter = false) {
    inset_mm = cutter ? engraving_depth_mm : feature_overlap_mm;
    extrusion_mm = cutter
        ? engraving_depth_mm + feature_overlap_mm
        : relief_height_mm + feature_overlap_mm;

    color(text_color)
        text_glyphs(0, -label_advance() / 2, inset_mm, extrusion_mm);
}

module icon_object(icon_file, icon_color, size_mm, scale_factor_value, offset_x_mm, offset_z_mm, cutter = false) {
    if (icon_file != "" && file_exists(icon_file)) {
        height_mm = label_z_mm + offset_z_mm;
        radius = wall_radius(height_mm);
        angle_deg = offset_x_mm / radius * 180 / PI;
        inset_mm = cutter ? engraving_depth_mm : feature_overlap_mm;
        extrusion_mm = cutter
            ? engraving_depth_mm + feature_overlap_mm
            : relief_height_mm + feature_overlap_mm;
        import_scale = (size_mm * scale_factor_value) / 100;

        color(icon_color)
            translate([radius * sin(angle_deg), -radius * cos(angle_deg), height_mm])
                rotate([0, 0, angle_deg])
                    rotate([90, 0, 0])
                        rotate([0, 180, 0])
                            translate([0, 0, -inset_mm])
                                linear_extrude(height = extrusion_mm, convexity = 10)
                                    scale([import_scale, import_scale])
                                        import(file = icon_file, center = true, dpi = 96);
    }
}

module left_icon(cutter = false) {
    if (show_left_icon)
        icon_object(
            icon_left_file, icon_left_color, icon_left_size_mm, icon_left_scale,
            icon_left_offset_x_mm, icon_left_offset_z_mm, cutter
        );
}

module right_icon(cutter = false) {
    if (show_right_icon)
        icon_object(
            icon_right_file, icon_right_color, icon_right_size_mm, icon_right_scale,
            icon_right_offset_x_mm, icon_right_offset_z_mm, cutter
        );
}

module engraved_bowl() {
    difference() {
        bowl_geometry();
        if (label_text != "") text_object(true);
        left_icon(true);
        right_icon(true);
    }
}

if (model_part == "BOWL") {
    if (feature_mode == "ENGRAVED")
        engraved_bowl();
    else
        bowl_geometry();
} else if (model_part == "TEXT") {
    if (label_text != "") text_object();
} else if (model_part == "LEFT_ICON") {
    left_icon();
} else if (model_part == "RIGHT_ICON") {
    right_icon();
} else if (feature_mode == "ENGRAVED") {
    engraved_bowl();
} else {
    bowl_geometry();
    if (label_text != "") text_object();
    left_icon();
    right_icon();
}
