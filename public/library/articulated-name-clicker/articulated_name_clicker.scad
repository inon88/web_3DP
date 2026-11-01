// Articulated name clicker: one block per letter, each holding a Cherry MX
// (compatible) switch under a lettered keycap. The blocks are joined by
// print-in-place hinges with vertical pins, so the name bends left and right.
// Switches are bought separately; housings and keycaps print without supports.
// All dimensions are in millimetres.
//
// Hinge between block i (left) and block i+1 (right), axis A between them:
//   block i   : pin standing on the bed with a cone foot, held at the top by an
//               arm that bridges from block i to the pin
//   block i+1 : ring around the pin, below the arm and above the cone foot
// Both blocks are notched around A so the parts can turn without touching.
// Several names: separate them with commas. Each becomes its own chain (with its keycaps), laid out side by
// side on 256 mm plates; when a plate is full the next ones continue to the right (Export can write one file
// per plate).

/* [Name] */
// Up to 16 characters per name; a space gives a blank key. Commas separate names.
name = "NAME";
font_name = "Arial:style=Bold";
// Raised on the key, engraved into it, or a flush two-color inlay
letter_style = "Raised"; // ["Raised","Engraved","Flush inlay"]
// 0 = largest size that fits every letter on the key top
letter_size_mm = 0; // [0:0.5:16]
// Thickens thin strokes
letter_bold_mm = 0.2; // [0:0.05:1]
// Raised height, or depth for Engraved and Flush inlay
letter_depth_mm = 1; // [0.4:0.2:2]

/* [Print] */
// Assembled preview shows keys on switches for viewing only; do not print it
part = "All"; // ["All","Housings","Keycaps","Assembled preview"]
// Prints the chain along an arc (angle per hinge) so long names fit the bed
print_curve_deg = 0; // [0:1:25]
keyring = "Left"; // ["None","Left","Right"]

/* [Housing] */
// Block width along the name
block_width_mm = 19; // [17:0.5:26]
// Block depth (front to back)
block_depth_mm = 19; // [17:0.5:26]
// Rounded vertical corners; larger corners allow a deeper bend
block_corner_mm = 3; // [0.5:0.5:6]
// Closed protects the switch pins; Open is lower and lets the pins stick out
bottom_style = "Closed"; // ["Closed","Open"]
floor_mm = 1.2; // [0.8:0.2:3]

/* [Switch] */
// MX plate cutout; 14.0 is standard, add 0.1 to 0.2 for a tight printer
switch_hole_mm = 14; // [13.8:0.05:14.4]
// The clips need a 1.5 mm plate
plate_mm = 1.5; // [1.2:0.1:1.8]
// Room below the plate: 8.4 fits the switch body and pins (Closed bottom)
cavity_depth_mm = 8.4; // [5:0.2:12]

/* [Hinge] */
hinge_pin_mm = 2.2; // [1.6:0.1:4]
// Radial clearance between pin and ring; raise it if the hinge prints fused
hinge_clearance_mm = 0.35; // [0.2:0.05:0.7]
// Vertical gap above the ring
hinge_gap_mm = 0.4; // [0.2:0.05:0.8]
hinge_ring_wall_mm = 1.6; // [1:0.1:3]
hinge_arm_width_mm = 3; // [2:0.25:6]
hinge_arm_thickness_mm = 2; // [1.2:0.2:4]
// Smallest gap between neighbouring blocks (it grows when the hinge needs room)
min_block_gap_mm = 2; // [1:0.25:8]

/* [Keycap] */
keycap_size_mm = 18; // [15:0.25:19]
keycap_profile = "Chamfered"; // ["Flat","Chamfered","Rounded"]
// Thickness above the switch pocket
keycap_top_mm = 2; // [1.2:0.2:4]
// Pocket depth for the switch top housing (at least 4.4 so the key can travel fully)
keycap_pocket_depth_mm = 5; // [4.4:0.1:7]
// Arm width of the "+" stem socket; MX stems are 1.17 mm, FDM usually needs 1.25 to 1.35
stem_slot_width_mm = 1.3; // [1.15:0.01:1.5]
// Arm length of the "+" stem socket (MX stems are 4.0 mm)
stem_slot_length_mm = 4.1; // [3.9:0.05:4.4]

/* [Keyring] */
keyring_hole_mm = 4.5; // [2.5:0.5:8]
keyring_wall_mm = 2.2; // [1.2:0.2:5]
keyring_height_mm = 4; // [2:0.5:10]

/* [Plate layout] */
// Space between chains when several names are given
item_spacing = 6; // [2:0.5:30]
// Free border around each 256 mm plate
plate_margin = 5; // [0:0.5:30]
// 0 = all plates; 1, 2, … = only that plate, moved onto plate 1
export_plate = 0; // [0:1:20]
// Moves everything on the plate
move_x = 0; // [-400:0.5:400]
move_y = 0; // [-400:0.5:400]

/* [Colors] */
housing_color = "Black"; // ["Black","White","Gray","Silver","Red","Orange","Gold","Yellow","LimeGreen","Green","DodgerBlue","Navy","MediumPurple","HotPink","SaddleBrown"]
keycap_color = "White"; // ["Black","White","Gray","Silver","Red","Orange","Gold","Yellow","LimeGreen","Green","DodgerBlue","Navy","MediumPurple","HotPink","SaddleBrown"]
letter_color = "DodgerBlue"; // ["Black","White","Gray","Silver","Red","Orange","Gold","Yellow","LimeGreen","Green","DodgerBlue","Navy","MediumPurple","HotPink","SaddleBrown"]

// Preview resolution only; FormForge exports at maximum resolution.
$fa = 6;
$fs = 0.3;

// ---------------------------------------------------------------- derived ---

// Several names, separated by commas. Values that depend on one name ($key_chars, $count, $ring_x) are set by
// name_chain() for the chain being drawn.
function split_commas(t, i = 0, cur = "", out = []) =
    i >= len(t) ? concat(out, [cur])
  : t[i] == "," ? split_commas(t, i + 1, "", concat(out, [cur]))
  : split_commas(t, i + 1, str(cur, t[i]), out);
function substr(t, a, b) = a >= b ? "" : chr([for (i = [a : b - 1]) ord(t[i])]);
function first_solid(t, i = 0) = i < len(t) && t[i] == " " ? first_solid(t, i + 1) : i;
function last_solid(t, i) = i > 0 && t[i - 1] == " " ? last_solid(t, i - 1) : i;
function trim(t) = let(a = first_solid(t)) substr(t, a, max(a, last_solid(t, len(t))));
names_found = [for (w = split_commas(name)) let(t = trim(w)) if (len(t) > 0) t];
names = len(names_found) == 0 ? [""] : [for (i = [0 : min(len(names_found), 40) - 1]) names_found[i]];
function chars_of(nm) = len(nm) > 0 ? [for (index = [0 : min(len(nm), 16) - 1]) nm[index]] : [" "];
// All letters of all names: one letter size for every chain.
key_chars_all = [for (nm = names) each chars_of(nm)];
count_max = max([for (nm = names) len(chars_of(nm))]);

// MX switch: clips on the north/south faces need extra room below the plate.
cavity_x = switch_hole_mm + 0.4;
cavity_y = switch_hole_mm + 1.4;
housing_h = (bottom_style == "Closed" ? floor_mm : 0) + cavity_depth_mm + plate_mm;
cavity_bottom = bottom_style == "Closed" ? floor_mm : -1;

pin_r = hinge_pin_mm / 2;
foot_mm = 0.6;                                     // cone foot height (45 degrees)
ring_r = pin_r + hinge_clearance_mm + hinge_ring_wall_mm;
ring_top = housing_h - hinge_gap_mm - hinge_arm_thickness_mm;
side_wall = (block_width_mm - cavity_x) / 2;
// Axis distance from each block wall: the ring notch must leave 0.8 mm of wall
// next to the switch cavity.
axis_offset = max(min_block_gap_mm / 2, ring_r + hinge_clearance_mm - side_wall + 0.8);
pitch = block_width_mm + 2 * axis_offset;
// Radius swept by the arm (outside its own block) while the hinge turns.
arm_sweep = max(pin_r, sqrt(pow(axis_offset, 2) + pow(hinge_arm_width_mm / 2, 2)));

key_flat = keycap_size_mm - 2 * (keycap_profile == "Chamfered" ? 1 : keycap_profile == "Rounded" ? 1.5 : 0);
key_h = keycap_pocket_depth_mm + keycap_top_mm;
pocket_w = min(15.6, keycap_size_mm - 2.2);
// Written as expressions so they stay out of the parameter form.
// Height of the keycap underside above the housing top with an MX switch fitted.
key_rest_z = 62 / 10;
// Font size used to measure the letters before scaling them to the key.
probe = 5 * 2;
function probe_size(c) = textmetrics(c, size = probe, font = font_name).size;
visible = [for (c = key_chars_all) if (c != " ") c];
widest = len(visible) > 0 ? max([for (c = visible) probe_size(c).x]) : 1;
tallest = len(visible) > 0 ? max([for (c = visible) probe_size(c).y]) : 1;
letter_area = key_flat - 2 * (0.8 + letter_bold_mm);
letter_size = letter_size_mm > 0 ? letter_size_mm : probe * letter_area / max(widest, tallest, 0.01);

// Bend limit: the blocks are rounded rectangles, i.e. inner rectangles grown by
// the corner radius. Seen from the hinge axis, block i+1 turned by t stays clear
// of block i while the inner rectangles are at least 2 corner radii (plus the
// hinge clearance) apart; the distance is checked from every corner of each
// rectangle to the other rectangle.
rc = block_corner_mm;
r0 = [-axis_offset - block_width_mm + rc, -axis_offset - rc, -(block_depth_mm / 2 - rc), block_depth_mm / 2 - rc];
r1 = [axis_offset + rc, axis_offset + block_width_mm - rc, r0[2], r0[3]];
function corners(r) = [[r[0], r[2]], [r[1], r[2]], [r[0], r[3]], [r[1], r[3]]];
function turn(p, t) = [p[0] * cos(t) - p[1] * sin(t), p[0] * sin(t) + p[1] * cos(t)];
function to_rect(p, r) = norm([max(r[0] - p[0], 0, p[0] - r[1]), max(r[2] - p[1], 0, p[1] - r[3])]);
function block_gap(t) = min(concat([for (p = corners(r1)) to_rect(turn(p, t), r0)], [for (p = corners(r0)) to_rect(turn(p, -t), r1)])) - 2 * rc;
blocked = [for (t = [1 : 90]) if (block_gap(t) < hinge_clearance_mm) t];
bend_limit = len(blocked) > 0 ? blocked[0] - 1 : 90;
curve_deg = min(print_curve_deg, bend_limit);

// Keycaps print in rows of up to 8, below the chain.
function keys_per_row(n) = min(n, 8);
key_spacing = keycap_size_mm + 4;
keycap_row_y = -(block_depth_mm / 2 + keycap_size_mm / 2 + 5);
loop_r = keyring_hole_mm / 2 + keyring_wall_mm;   // keyring loop radius
function ring_x_of(n) = keyring == "Right" ? (n - 1) * pitch + block_width_mm / 2 + loop_r - 1.2
    : -(block_width_mm / 2 + loop_r - 1.2);
function chain_length_of(n) = (n - 1) * pitch + block_width_mm;
chain_length = chain_length_of(count_max);

echo(str("Key pitch ", pitch, " mm, longest straight chain ", chain_length, " mm, housing height ", housing_h,
    " mm, each hinge bends about +/-", bend_limit, " degrees", len(visible) > 0 ? str(", letter size ", letter_size, " mm") : ""));
if (chain_length > 250 && curve_deg == 0)
    echo("The straight chain is longer than 250 mm; raise print_curve_deg to print it along an arc.");
if (print_curve_deg > bend_limit)
    echo(str("print_curve_deg is limited to ", bend_limit, " degrees so neighbouring blocks stay apart."));
if (curve_deg > 0)
    echo(str("Printed along an arc of about ", round(pitch / sin(curve_deg / 2)), " mm diameter, turning up to ", (count_max - 1) * curve_deg, " degrees in total",
        (count_max - 1) * curve_deg > 270 ? " - too much: the ends will collide, lower print_curve_deg" : ""));

// -------------------------------------------------------------- housings ---

module rounded_square(w, d, r) { offset(r = r) square([w - 2 * r, d - 2 * r], center = true); }

module block_body() { linear_extrude(height = housing_h) rounded_square(block_width_mm, block_depth_mm, block_corner_mm); }

module switch_cutout() {
    translate([0, 0, housing_h - plate_mm - 0.01]) linear_extrude(height = plate_mm + 1) square(switch_hole_mm, center = true);
    translate([0, 0, cavity_bottom]) linear_extrude(height = housing_h - plate_mm - cavity_bottom) square([cavity_x, cavity_y], center = true);
}

// Pin with a 45-degree cone foot, plus the arm that bridges to block i (axis at x = 0).
module hinge_pin() {
    rotate_extrude() polygon([[0, 0], [pin_r + foot_mm, 0], [pin_r, foot_mm], [pin_r, housing_h], [0, housing_h]]);
    translate([-axis_offset - 0.8, -hinge_arm_width_mm / 2, ring_top + hinge_gap_mm])
        cube([axis_offset + 0.8, hinge_arm_width_mm, housing_h - ring_top - hinge_gap_mm]);
}

// Hole through the ring: the pin profile grown by the clearance; around the
// cone foot the gap is doubled so the 45-degree faces cannot fuse.
module hinge_ring_hole() {
    c = hinge_clearance_mm;
    rotate_extrude() polygon([[0, -1], [pin_r + c + foot_mm + c + 1, -1], [pin_r + c, foot_mm + c], [pin_r + c, housing_h + 1], [0, housing_h + 1]]);
}

module housing(i) {
    left_axis = (i - 0.5) * pitch;
    right_axis = (i + 0.5) * pitch;
    color(housing_color) union() {
        difference() {
            union() {
                translate([i * pitch, 0, 0]) block_body();
                if (i > 0) translate([left_axis, 0, 0]) cylinder(r = ring_r, h = ring_top);
                if (keyring == "Left" && i == 0 || keyring == "Right" && i == $count - 1)
                    translate([$ring_x, 0, 0]) cylinder(r = keyring_hole_mm / 2 + keyring_wall_mm, h = min(keyring_height_mm, housing_h));
            }
            translate([i * pitch, 0, 0]) switch_cutout();
            // Room for the neighbour's ring (right) and the neighbour's arm (left).
            if (i < $count - 1) translate([right_axis, 0, -1]) cylinder(r = ring_r + hinge_clearance_mm, h = ring_top + hinge_gap_mm / 2 + 1);
            if (i > 0) {
                translate([left_axis, 0, ring_top]) cylinder(r = arm_sweep + hinge_clearance_mm, h = housing_h);
                translate([left_axis, 0, 0]) hinge_ring_hole();
            }
            if (keyring == "Left" && i == 0 || keyring == "Right" && i == $count - 1)
                translate([$ring_x, 0, -1]) cylinder(d = keyring_hole_mm, h = housing_h + 2);
        }
        if (i < $count - 1) translate([right_axis, 0, 0]) hinge_pin();
    }
}

// --------------------------------------------------------------- keycaps ---

module key_shell() {
    s = keycap_size_mm;
    if (keycap_profile == "Chamfered") {
        e = 1;
        hull() {
            linear_extrude(height = key_h - e) rounded_square(s, s, 1);
            translate([0, 0, key_h - 0.01]) linear_extrude(height = 0.01) rounded_square(s - 2 * e, s - 2 * e, 0.5);
        }
    } else if (keycap_profile == "Rounded") {
        e = 1.5;
        hull() {
            linear_extrude(height = key_h - e) rounded_square(s, s, e);
            for (x = [-1, 1], y = [-1, 1]) translate([x * (s / 2 - e), y * (s / 2 - e), key_h - e]) sphere(r = e);
        }
    } else linear_extrude(height = key_h) rounded_square(s, s, 1);
}

module letter_2d(c) {
    m = textmetrics(c, size = letter_size, font = font_name);
    offset(r = letter_bold_mm)
        translate([-(m.position.x + m.size.x / 2), -(m.position.y + m.size.y / 2)])
            text(c, size = letter_size, font = font_name);
}

// Printed upright: the walls and the stem post start on the bed and the top
// bridges between them, so no supports are needed.
module keycap(c) {
    has_letter = c != " ";
    color(keycap_color) difference() {
        key_shell();
        translate([0, 0, -1]) linear_extrude(height = keycap_pocket_depth_mm + 1)
            difference() { square(pocket_w, center = true); circle(d = 5.5); }
        translate([0, 0, -1]) linear_extrude(height = min(4, keycap_pocket_depth_mm) + 1) union() {
            square([stem_slot_length_mm, stem_slot_width_mm], center = true);
            square([stem_slot_width_mm, stem_slot_length_mm], center = true);
        }
        if (has_letter && letter_style != "Raised")
            translate([0, 0, key_h - letter_depth_mm]) linear_extrude(height = letter_depth_mm + 1) letter_2d(c);
    }
    if (has_letter && letter_style == "Raised")
        color(letter_color) translate([0, 0, key_h - 0.01]) linear_extrude(height = letter_depth_mm + 0.01) letter_2d(c);
    if (has_letter && letter_style == "Flush inlay")
        color(letter_color) translate([0, 0, key_h - letter_depth_mm]) linear_extrude(height = letter_depth_mm) letter_2d(c);
}

// Simplified MX switch, shown only in the assembled preview.
module switch_ghost() {
    color("LightGray") {
        translate([0, 0, housing_h - plate_mm - 5]) linear_extrude(height = 5 + plate_mm) square(13.9, center = true);
        translate([0, 0, housing_h]) linear_extrude(height = 5.8, scale = 0.75) square(15.4, center = true);
    }
    color("Red") translate([0, 0, housing_h + 5.8]) linear_extrude(height = key_rest_z + 4 - 5.8) union() {
        square([4, 1.17], center = true);
        square([1.17, 4], center = true);
    }
}

// Bends block i by curve_deg at every hinge before it; curve_deg never exceeds
// the bend limit, so neighbouring blocks keep at least the hinge clearance.
module chain_place(i) {
    if (i <= 0 || curve_deg == 0) children();
    else chain_place(i - 1)
        translate([(i - 0.5) * pitch, 0, 0]) rotate(curve_deg) translate([-(i - 0.5) * pitch, 0, 0]) children();
}

// One name: its chain of housings and/or its keycaps (sets the per-name values the modules read).
module name_chain(nm) {
    $key_chars = chars_of(nm);
    $count = len($key_chars);
    $ring_x = ring_x_of($count);
    if (part != "Keycaps")
        for (i = [0 : $count - 1]) chain_place(i) housing(i);
    if (part == "All" || part == "Keycaps")
        for (i = [0 : $count - 1])
            translate([(i % keys_per_row($count)) * key_spacing, (part == "Keycaps" ? 0 : keycap_row_y) - floor(i / keys_per_row($count)) * key_spacing, 0])
                keycap($key_chars[i]);
    if (part == "Assembled preview")
        for (i = [0 : $count - 1]) translate([i * pitch, 0, 0]) {
            switch_ghost();
            translate([0, 0, housing_h + key_rest_z]) keycap($key_chars[i]);
        }
}

// Footprint [xmin, ymin, xmax, ymax] of one name: blocks as circles around their (placed) centres, so the
// box also holds when the chain is printed along an arc, plus the keycap rows.
function rot_about(p, c, t) = [c + (p[0] - c) * cos(t) - p[1] * sin(t), (p[0] - c) * sin(t) + p[1] * cos(t)];
function place_pt(p, i) = i <= 0 || curve_deg == 0 ? p : place_pt(rot_about(p, (i - 0.5) * pitch, curve_deg), i - 1);
function item_box(nm) =
    let(n = len(chars_of(nm)),
        r = norm([block_width_mm, block_depth_mm]) / 2,
        blocks = part == "Keycaps" ? []
            : part == "Assembled preview" ? [[-keycap_size_mm / 2 - 1, -block_depth_mm / 2], [(n - 1) * pitch + keycap_size_mm / 2 + 1, block_depth_mm / 2]]
            : [for (i = [0 : n - 1]) let(p = place_pt([i * pitch, 0], i))
                   each (curve_deg == 0 ? [[p[0] - block_width_mm / 2, -block_depth_mm / 2], [p[0] + block_width_mm / 2, block_depth_mm / 2]]
                                        : [p - [r, r], p + [r, r]])],
        ring = part == "Keycaps" || keyring == "None" ? []
            : let(p = place_pt([ring_x_of(n), 0], keyring == "Right" ? n - 1 : 0)) [p - [loop_r, loop_r], p + [loop_r, loop_r]],
        y0 = part == "Keycaps" ? 0 : keycap_row_y,
        rows = floor((n - 1) / 8),
        keys = part == "All" || part == "Keycaps"
            ? [[-keycap_size_mm / 2, y0 - rows * key_spacing - keycap_size_mm / 2],
               [(keys_per_row(n) - 1) * key_spacing + keycap_size_mm / 2, y0 + keycap_size_mm / 2]] : [],
        all = concat(blocks, ring, keys))
    [min([for (p = all) p[0]]), min([for (p = all) p[1]]), max([for (p = all) p[0]]), max([for (p = all) p[1]])];

// ------------------------------------------------- several names on plates ---

PLATE = 256;
PLATE_PITCH = 268;   // FormForge draws plates 12 mm apart; more plates continue to +X
usable = PLATE - 2 * plate_margin;
boxes = [for (nm = names) item_box(nm)];
// Shelf packing: side by side in a row, a new row when the plate width is used up, the next plate when the
// rows reach the bottom. Returns [plate, x, y] from the plate's top-left corner for every name.
function shelf(r = 0, plate = 0, x = 0, y = 0, row_h = 0, out = []) =
    r >= len(boxes) ? out
  : let(w = boxes[r][2] - boxes[r][0], d = boxes[r][3] - boxes[r][1],
        wrap = x > 0 && x + w > usable,
        x1 = wrap ? 0 : x, y1 = wrap ? y + row_h + item_spacing : y, h1 = wrap ? d : max(row_h, d),
        next = y1 > 0 && y1 + d > usable,
        p = next ? plate + 1 : plate, x2 = next ? 0 : x1, y2 = next ? 0 : y1, h2 = next ? d : h1)
    shelf(r + 1, p, x2 + w + item_spacing, y2, h2, concat(out, [[p, x2, y2]]));
slots = shelf();
plates_used = slots[len(slots) - 1][0] + 1;
only_plate = min(export_plate, plates_used);
// Tells FormForge how many plates there are: Export then offers one file per plate.
echo("formforge-plates", plates_used);
function shown(r) = only_plate == 0 || slots[r][0] == only_plate - 1;
// A single name stays centred on plate 1.
function item_offset(r) = len(names) == 1
    ? [move_x - (boxes[0][0] + boxes[0][2]) / 2, move_y - (boxes[0][1] + boxes[0][3]) / 2]
    : let(p = only_plate == 0 ? slots[r][0] : 0)
      [move_x + p * PLATE_PITCH - usable / 2 + slots[r][1] - boxes[r][0], move_y + usable / 2 - slots[r][2] - boxes[r][3]];
shown_items = [for (r = [0 : len(names) - 1]) if (shown(r)) r];

// ----------------------------------------------------------------- model ---

union() {
    for (r = shown_items) translate(item_offset(r)) name_chain(names[r]);
}
