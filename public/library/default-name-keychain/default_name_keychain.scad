// Parametric name keychain
// Recreated from the MakerWorld link title "Default Name Keychain.scad".
// The source page could not be loaded in this session; this is an editable
// name-tag style interpretation with a rounded plate, ring hole, and raised text.
// Several names: separate them with commas. Each becomes its own keychain, laid out side by side on 256 mm
// plates; when a plate is full the next ones continue to the right (Export can write one file per plate).

// ---------- Parameters ----------
/* [Text] */
// Name embossed on the keychain; separate several names with commas
name = "Default Name";
// Select from fonts installed on this device in the FormForge font menu.
font_name = "Liberation Sans:style=Bold";
font_size = 12;
text_spacing = 1.0;

/* [Colors] */
// Keychain plate/background color.
plate_color = "orange"; // [white, black, red, orange, yellow, green, blue, purple, pink, gray]
// Raised text color.
text_color = "black"; // [white, black, red, orange, yellow, green, blue, purple, pink, gray]

/* [Dimensions] */
plate_height = 2.4;
text_height = 0.8;
// Overall horizontal length of the plate, in millimeters; 0 fits each name automatically.
plate_length = 0; // [0:1:200]
// Space left and right of the name when the length is automatic
plate_margin_x = 4; // [1:0.5:20]
plate_margin_y = 3.0;
corner_radius = 2.2;

ring_outer_diameter = 10.0;
ring_hole_diameter = 5.0;
ring_overlap = 1.2;

/* [Plate layout] */
// Space between keychains when several names are given
item_spacing = 6; // [2:0.5:30]
// Free border around each 256 mm plate
plate_margin = 5; // [0:0.5:30]
// 0 = all plates; 1, 2, … = only that plate, moved onto plate 1
export_plate = 0; // [0:1:20]
// Moves everything on the plate
move_x = 0; // [-400:0.5:400]
move_y = 0; // [-400:0.5:400]

$fn = 64;

plate_depth = font_size + 2 * plate_margin_y;

// Plate length for one name: the fixed length, or the name's width plus margins.
function plate_width(nm) = plate_length > 0 ? plate_length
    : max(20, textmetrics(text = nm, size = font_size, font = font_name, spacing = text_spacing).size.x + 2 * plate_margin_x);
function ring_center_x(nm) = -plate_width(nm) / 2 - ring_outer_diameter / 2 + ring_overlap;

module rounded_plate_2d(width, depth, radius) {
    // Offset keeps the plate corners rounded while retaining a flat bottom.
    offset(r = radius)
        square([width - 2 * radius, depth - 2 * radius], center = true);
}

module tag_outline_2d(nm) {
    union() {
        rounded_plate_2d(plate_width(nm), plate_depth, corner_radius);
        // Integrated eyelet boss, joined to the left edge of the name plate.
        translate([ring_center_x(nm), 0])
            circle(d = ring_outer_diameter);
    }
}

module tag_base(nm) {
    difference() {
        linear_extrude(height = plate_height)
            tag_outline_2d(nm);

        // Hole passes through the eyelet boss.
        translate([ring_center_x(nm), 0, -0.1])
            cylinder(d = ring_hole_diameter, h = plate_height + 0.2);
    }
}

module raised_name(nm) {
    translate([0, 0, plate_height])
        linear_extrude(height = text_height)
            text(nm,
                size = font_size,
                font = font_name,
                spacing = text_spacing,
                halign = "center",
                valign = "center");
}

// Footprint [xmin, ymin, xmax, ymax] of one keychain around its own origin.
function item_box(nm) = [ring_center_x(nm) - ring_outer_diameter / 2, -plate_depth / 2, plate_width(nm) / 2, plate_depth / 2];

// ---------- Several names on 256 mm plates ----------
function split_commas(t, i = 0, cur = "", out = []) =
    i >= len(t) ? concat(out, [cur])
  : t[i] == "," ? split_commas(t, i + 1, "", concat(out, [cur]))
  : split_commas(t, i + 1, str(cur, t[i]), out);
function substr(t, a, b) = a >= b ? "" : chr([for (i = [a : b - 1]) ord(t[i])]);
function first_solid(t, i = 0) = i < len(t) && t[i] == " " ? first_solid(t, i + 1) : i;
function last_solid(t, i) = i > 0 && t[i - 1] == " " ? last_solid(t, i - 1) : i;
function trim(t) = let(a = first_solid(t)) substr(t, a, max(a, last_solid(t, len(t))));
names_found = [for (w = split_commas(name)) let(t = trim(w)) if (len(t) > 0) t];
names = len(names_found) == 0 ? [" "] : [for (i = [0 : min(len(names_found), 40) - 1]) names_found[i]];

PLATE = 256;
PLATE_PITCH = 268;   // FormForge draws plates 12 mm apart; more plates continue to +X
usable = PLATE - 2 * plate_margin;
boxes = [for (nm = names) item_box(nm)];
// Shelf packing: side by side in a row, a new row when the plate width is used up, the next plate when the
// rows reach the bottom. Returns [plate, x, y] from the plate's top-left corner for every keychain.
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
// A single keychain stays centred on plate 1.
function item_offset(r) = len(names) == 1
    ? [move_x - (boxes[0][0] + boxes[0][2]) / 2, move_y - (boxes[0][1] + boxes[0][3]) / 2]
    : let(p = only_plate == 0 ? slots[r][0] : 0)
      [move_x + p * PLATE_PITCH - usable / 2 + slots[r][1] - boxes[r][0], move_y + usable / 2 - slots[r][2] - boxes[r][3]];
shown_items = [for (r = [0 : len(names) - 1]) if (shown(r)) r];

union() {
    for (r = shown_items) translate(item_offset(r)) {
        color(plate_color) tag_base(names[r]);
        color(text_color) raised_name(names[r]);
    }
}
