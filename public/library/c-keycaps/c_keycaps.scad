// Parametric keycap inspired by the reference Keycap Generator video.
// Dimensions are approximations; check stem fit against your keyboard switch before printing.

/* [Keycap] */
// Keyboard key size. The spacebar option is 6.25u.
key_size = "1u"; // [1u:1u, 1.25u:1.25u, 1.5u:1.5u, 1.75u:1.75u, 2u:2u, 2.25u:2.25u, 2.75u:2.75u, 6.25u Spacebar:6.25u Spacebar]
// Choose the overall keycap shape.
shape = "Standard"; // [Standard, Choc v1, Low, Thock, Round, Round tapered, Square]
// Key legend rendering style.
legend_style = "Raised"; // [Raised, Engraved, Flush, Shine-through]

/* [Legend] */
// Text printed on the keycap top.
legend = "Esc";
// Select a font installed on this device in the FormForge font menu.
font_name = "Liberation Sans:style=Bold";
font_size = 6.0; // [2:0.5:14]
legend_rotation = 0; // [-180:1:180]
legend_x = 0; // [-30:0.5:30]
legend_y = 0; // [-10:0.5:10]

/* [Colors] */
keycap_color = "blue"; // [white, black, red, orange, yellow, green, blue, purple, pink, gray]
legend_color = "white"; // [white, black, red, orange, yellow, green, blue, purple, pink, gray]

/* [Dimensions] */
wall_thickness = 1.2; // [0.8:0.1:2.0]
top_thickness = 1.3; // [0.8:0.1:2.5]
corner_radius = 1.8; // [0.5:0.1:4]
raised_height = 0.7; // [0.2:0.1:1.5]
engrave_depth = 0.5; // [0.2:0.1:1.0]
flush_depth = 0.6; // [0.2:0.1:1.0]

/* [Stem] */
// MX cross socket dimensions use common Cherry MX style approximations.
stem_clearance = 0.15; // [0:0.05:0.4]
stem_depth = 4.2; // [2:0.2:6]

$fn = 32;

size_u = key_size == "1u" ? 1 :
    key_size == "1.25u" ? 1.25 :
    key_size == "1.5u" ? 1.5 :
    key_size == "1.75u" ? 1.75 :
    key_size == "2u" ? 2 :
    key_size == "2.25u" ? 2.25 :
    key_size == "2.75u" ? 2.75 : 6.25;
key_width = size_u * 19.05 - 1.5;
key_depth = key_size == "6.25u Spacebar" ? 18.6 : 18;
cap_height = shape == "Choc v1" ? 5.2 :
    shape == "Low" ? 5.8 :
    shape == "Thock" ? 11 :
    shape == "Round" ? 8 :
    shape == "Round tapered" ? 9 : 9;
taper = shape == "Square" ? 0.6 :
    shape == "Choc v1" ? 1.0 :
    shape == "Round" ? 2.4 :
    shape == "Round tapered" ? 3.0 : 2.0;
top_width = max(key_width - taper, 5);
top_depth = max(key_depth - min(taper, 2.4), 5);
base_radius = shape == "Square" ? 0.7 : min(corner_radius, min(key_width, key_depth) / 3);
top_radius = shape == "Round" ? min(5, min(top_width, top_depth) / 3) : min(base_radius, min(top_width, top_depth) / 3);
actual_stem_depth = min(stem_depth, max(1, cap_height - top_thickness - 0.5));

module rounded_rect_2d(width, depth, radius) {
    offset(r = radius)
        square([width - 2 * radius, depth - 2 * radius], center = true);
}

module outer_cap() {
    hull() {
        translate([0, 0, 0])
            linear_extrude(height = 0.05)
                rounded_rect_2d(key_width, key_depth, base_radius);
        translate([0, 0, cap_height - 0.8])
            linear_extrude(height = 0.05)
                rounded_rect_2d(top_width + 0.8, top_depth + 0.6, top_radius);
        translate([0, 0, cap_height])
            linear_extrude(height = 0.05)
                rounded_rect_2d(top_width, top_depth, top_radius);
    }
}

module inner_cavity() {
    inner_width = key_width - 2 * wall_thickness;
    inner_depth = key_depth - 2 * wall_thickness;
    translate([0, 0, -0.1])
        linear_extrude(
            height = max(0.5, cap_height - top_thickness + 0.1),
            scale = [top_width / inner_width, top_depth / inner_depth]
        )
            rounded_rect_2d(inner_width, inner_depth, max(0.5, base_radius - wall_thickness));
}

module legend_2d() {
    rotate(legend_rotation)
        text(legend,
            size = font_size,
            font = font_name,
            halign = "center",
            valign = "center");
}

module legend_recess(depth) {
    translate([legend_x, legend_y, cap_height - depth])
        linear_extrude(height = depth + 0.1)
            legend_2d();
}

module mx_socket_2d() {
    arm_length = 4.1 + stem_clearance;
    arm_width = 1.3 + stem_clearance;
    union() {
        square([arm_length, arm_width], center = true);
        square([arm_width, arm_length], center = true);
    }
}

module cap_shell() {
    difference() {
        outer_cap();
        inner_cavity();
        if (legend_style == "Engraved") legend_recess(engrave_depth);
        if (legend_style == "Flush") legend_recess(flush_depth);
        if (legend_style == "Shine-through")
            legend_recess(top_thickness + 0.15);
    }
}

module stem_boss() {
    difference() {
        translate([0, 0, cap_height - top_thickness - actual_stem_depth])
            cylinder(d = 7.4, h = actual_stem_depth);
        translate([0, 0, cap_height - top_thickness - actual_stem_depth - 0.1])
            linear_extrude(height = actual_stem_depth + 0.2)
                mx_socket_2d();
        if (legend_style == "Engraved") legend_recess(engrave_depth);
        if (legend_style == "Flush") legend_recess(flush_depth);
        if (legend_style == "Shine-through")
            legend_recess(top_thickness + 0.15);
    }
}

union() {
    color(keycap_color) {
        cap_shell();
        stem_boss();
    }

    if (legend_style == "Raised")
        color(legend_color)
            translate([legend_x, legend_y, cap_height])
                linear_extrude(height = raised_height)
                    legend_2d();

    if (legend_style == "Flush")
        color(legend_color)
            translate([legend_x, legend_y, cap_height - flush_depth])
                linear_extrude(height = flush_depth)
                    legend_2d();
}
