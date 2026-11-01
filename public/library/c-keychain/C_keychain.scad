// Parametric teacher name keychain inspired by the supplied reference image.
// All dimensions are in millimetres. The raised color regions are separate
// overlapping solids so they can be assigned colors in a multi-material slicer.
// Several names: separate them with commas. Each becomes its own keychain, laid out side by side on 256 mm
// plates; when a plate is full the next ones continue to the right (Export can write one file per plate).

/* [Text] */
// Separate several names with commas
name = "JESSICA";
font_name = "Liberation Sans:style=Bold";
font_size_mm = 20; // [10:1:32]
letter_spacing = 0.95; // [0.8:0.05:1.4]
text_color = "White"; // ["White", "Purple", "Pink", "Black"]

/* [Icons] */
left_icon = "BOOK"; // ["BOOK", "PENCIL_CUP", "HEART", "STAR", "NONE"]
right_icon = "PENCIL_CUP"; // ["BOOK", "PENCIL_CUP", "HEART", "STAR", "NONE"]
show_top_heart = true;
show_keyring_hole = true;
icon_color = "HotPink"; // ["HotPink", "Magenta", "Purple", "White", "Yellow"]
heart_color = "HotPink"; // ["HotPink", "Magenta", "Purple", "White", "Yellow"]

/* [Ruler] */
ruler_style = "CLASSIC"; // ["CLASSIC", "DASHED", "PLAIN", "NONE"]
ruler_length_percent = 100; // [60:5:130]
ruler_color = "MediumPurple"; // ["MediumPurple", "HotPink", "White", "Black", "Yellow"]

/* [Dimensions] */
base_thickness_mm = 2.4; // [1.6:0.2:4]
detail_height_mm = 1.0; // [0.4:0.2:2]
border_width_mm = 1.7; // [1:0.1:3]
book_width_mm = 17; // [12:1:24]
book_height_mm = 23; // [16:1:30]
ruler_height_mm = 6; // [4:0.5:9]
keyring_hole_diameter_mm = 3.8; // [2:0.2:6]

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

$fn = 48;

// These estimates keep the side icons and ruler aligned as the name changes (per name).
function estimated_text_width(nm) = font_size_mm * 0.69 * len(nm) * letter_spacing;
icon_gap_mm = 3.0;
function book_x(nm) = -estimated_text_width(nm) / 2 - icon_gap_mm - book_width_mm / 2;
function cup_x(nm) = estimated_text_width(nm) / 2 + icon_gap_mm + 8.5;
text_y = 1.0;
ruler_y = -font_size_mm * 0.66;
function ruler_width_mm(nm) = estimated_text_width(nm) * ruler_length_percent / 100 + 5;
heart_y = font_size_mm * 0.66 + 4;
function ring_x(nm) = book_x(nm) - book_width_mm * 0.59;
ring_y = 1;

module rounded_rect_2d(w, h, r, center = true) {
    offset(r = r)
        square([max(0.1, w - 2 * r), max(0.1, h - 2 * r)], center = center);
}

module heart_2d(size = 5) {
    // Smooth heart silhouette formed from two lobes and a pointed base.
    scale([size / 10, size / 10])
        polygon(points = [
            [0, -5], [-4.6, -0.6], [-5, 1.3], [-4.7, 3.3],
            [-3.4, 4.7], [-1.7, 5], [0, 3.5], [1.7, 5],
            [3.4, 4.7], [4.7, 3.3], [5, 1.3], [4.6, -0.6]
        ]);
}

module pencil_2d(x, y, lean = 0, height = 15, width = 3.3) {
    translate([x, y])
        rotate(lean)
            union() {
                translate([-width / 2, 0]) square([width, height - 2]);
                polygon(points = [[-width / 2, height - 2], [width / 2, height - 2], [0, height]]);
                translate([-width / 2, 1]) square([width, 1.2]);
            }
}

module book_outline_2d(nm) {
    translate([book_x(nm), text_y])
        rounded_rect_2d(book_width_mm, book_height_mm, 2.1);
}

module star_2d(radius = 9) {
    polygon(points = [for (i = [0 : 9])
        let(a = 90 + i * 36, r = (i % 2 == 0) ? radius : radius * 0.46)
            [r * cos(a), r * sin(a)]]);
}

module icon_shape_2d(icon) {
    if (icon == "BOOK")
        rounded_rect_2d(book_width_mm - 2, book_height_mm - 2, 1.8);
    else if (icon == "PENCIL_CUP")
        union() {
            offset(r = 0.9)
                polygon(points = [[-7, -8], [7, -8], [5.5, 3], [-5.5, 3]]);
            pencil_2d(-5, 2, -17, 14, 2.8);
            pencil_2d(-1.8, 3, -6, 16, 3.0);
            pencil_2d(1.8, 3, 7, 15, 3.0);
            pencil_2d(5, 2, 17, 13, 2.8);
        }
    else if (icon == "HEART") heart_2d(16);
    else if (icon == "STAR") star_2d(9.5);
}

module ruler_outline_2d(nm) {
    if (ruler_style != "NONE")
        translate([0, ruler_y])
            rounded_rect_2d(ruler_width_mm(nm), ruler_height_mm, 1.0);
}

module side_icon_outline_2d(icon, x) {
    if (icon != "NONE")
        translate([x, text_y]) icon_shape_2d(icon);
}

module complete_outline_2d(nm) {
    // A small outline around all connected details makes the whole sign one body.
    offset(r = border_width_mm)
        union() {
            text(nm, size = font_size_mm, font = font_name, spacing = letter_spacing,
                 halign = "center", valign = "center");
            ruler_outline_2d(nm);
            side_icon_outline_2d(left_icon, book_x(nm));
            side_icon_outline_2d(right_icon, cup_x(nm));
            if (show_top_heart) translate([0, heart_y]) heart_2d(6.2);
            if (show_keyring_hole)
                translate([ring_x(nm), ring_y]) circle(d = 8.5);
        }
}

module base_body(nm) {
    color("Black")
        difference() {
            linear_extrude(height = base_thickness_mm)
                complete_outline_2d(nm);
            if (show_keyring_hole)
                translate([ring_x(nm), ring_y, -0.1])
                    cylinder(d = keyring_hole_diameter_mm, h = base_thickness_mm + 0.2);
        }
}

module raised_text(nm) {
    color(text_color)
        translate([0, text_y, base_thickness_mm])
            linear_extrude(height = detail_height_mm)
                text(nm, size = font_size_mm, font = font_name, spacing = letter_spacing,
                     halign = "center", valign = "center");
}

module raised_ruler(nm) {
    ruler_width_mm = ruler_width_mm(nm);
    if (ruler_style != "NONE")
        color(ruler_color)
            translate([0, ruler_y, base_thickness_mm])
                linear_extrude(height = detail_height_mm)
                    if (ruler_style == "PLAIN")
                        rounded_rect_2d(ruler_width_mm - 2, 1.8, 0.8);
                    else if (ruler_style == "DASHED")
                        union() {
                            rounded_rect_2d(ruler_width_mm, 0.9, 0.4);
                            for (i = [0 : floor((ruler_width_mm - 1) / 4)]) {
                                x = -ruler_width_mm / 2 + 1 + i * 4;
                                translate([x, 0]) square([1, ruler_height_mm], center = true);
                            }
                        }
                    else
                        union() {
                            translate([0, -ruler_height_mm / 2 + 0.5])
                                rounded_rect_2d(ruler_width_mm, 1.2, 0.5);
                            for (i = [0 : floor((ruler_width_mm + 1) / 3)]) {
                                x = -ruler_width_mm / 2 + i * 3;
                                tick_h = (i % 5 == 0) ? ruler_height_mm - 1 : ruler_height_mm * 0.55;
                                translate([x, -ruler_height_mm / 2 + tick_h / 2 + 0.3])
                                    square([0.65, tick_h], center = true);
                            }
                        }
}

module raised_side_icon(icon, x) {
    if (icon != "NONE") {
        color(icon_color)
            translate([x, text_y, base_thickness_mm])
                linear_extrude(height = detail_height_mm)
                    icon_shape_2d(icon);
        if (icon == "BOOK") {
            color("White")
                translate([x, text_y, base_thickness_mm + detail_height_mm])
                    linear_extrude(height = detail_height_mm * 0.55)
                        union() {
                            translate([0, 3.3]) rounded_rect_2d(8.2, 5.8, 0.9);
                            translate([0, 3.3]) rounded_rect_2d(5.2, 1.2, 0.4);
                            translate([0, 1.7]) rounded_rect_2d(5.2, 0.8, 0.3);
                        }
            color("Black")
                translate([x, text_y, base_thickness_mm + detail_height_mm * 1.56])
                    linear_extrude(height = 0.35)
                        heart_2d(5.5);
            color("White")
                translate([x - book_width_mm * 0.36, text_y, base_thickness_mm + detail_height_mm])
                    linear_extrude(height = detail_height_mm * 0.6)
                        for (y = [-8, -4, 0, 4, 8]) translate([0, y]) circle(d = 2.2);
        }
        else if (icon == "PENCIL_CUP")
            color("Black")
                translate([x, text_y, base_thickness_mm + detail_height_mm])
                    linear_extrude(height = detail_height_mm * 0.45)
                        heart_2d(6.2);
    }
}

module raised_side_icons(nm) {
    raised_side_icon(left_icon, book_x(nm));
    raised_side_icon(right_icon, cup_x(nm));
}

module raised_top_heart() {
    if (show_top_heart)
        color(heart_color)
            translate([0, heart_y, base_thickness_mm])
                linear_extrude(height = detail_height_mm)
                    heart_2d(5.0);
}

// Footprint [xmin, ymin, xmax, ymax] of one keychain around its own origin.
// Icon reach around its centre: [half width, top, bottom].
function icon_reach(icon) =
    icon == "BOOK" ? [book_width_mm / 2, book_height_mm / 2, book_height_mm / 2]
  : icon == "PENCIL_CUP" ? [9, 18.5, 8.5]
  : icon == "HEART" ? [8, 8, 8]
  : icon == "STAR" ? [9.5, 9.5, 9.5]
  : [0, 0, 0];
function item_box(nm) =
    let(tm = textmetrics(text = nm, size = font_size_mm, font = font_name, spacing = letter_spacing,
                         halign = "center", valign = "center"),
        rw = ruler_style != "NONE" ? ruler_width_mm(nm) / 2 : 0,
        l = icon_reach(left_icon), r = icon_reach(right_icon),
        e = border_width_mm + 0.5)
    [min(-tm.size.x / 2, -rw, left_icon != "NONE" ? book_x(nm) - l[0] : 0, show_keyring_hole ? ring_x(nm) - 4.25 : 0) - e,
     min(text_y - tm.size.y / 2, ruler_style != "NONE" ? ruler_y - ruler_height_mm / 2 : 0, text_y - max(l[2], r[2])) - e,
     max(tm.size.x / 2, rw, right_icon != "NONE" ? cup_x(nm) + r[0] : 0) + e,
     max(text_y + tm.size.y / 2, show_top_heart ? heart_y + 3.1 : 0, text_y + max(l[1], r[1])) + e];

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
// A single keychain stays where it always was: centred on its own origin, the app centres it on the plate.
function item_offset(r) = len(names) == 1
    ? [move_x - (boxes[0][0] + boxes[0][2]) / 2, move_y - (boxes[0][1] + boxes[0][3]) / 2]
    : let(p = only_plate == 0 ? slots[r][0] : 0)
      [move_x + p * PLATE_PITCH - usable / 2 + slots[r][1] - boxes[r][0], move_y + usable / 2 - slots[r][2] - boxes[r][3]];
shown_items = [for (r = [0 : len(names) - 1]) if (shown(r)) r];

// Keep one unconditional top-level union, following the working default
// keychain example. This guarantees geometry even if the app has stale values.
union() {
    for (r = shown_items) translate(item_offset(r)) {
        base_body(names[r]);
        raised_text(names[r]);
        raised_ruler(names[r]);
        raised_side_icons(names[r]);
        raised_top_heart();
    }
}
