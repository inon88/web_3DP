// Articulated name: one solid tile per letter, joined by print-in-place hinges
// with vertical pins so the name bends left and right. No switches or extra
// parts; the whole chain prints in one piece without supports.
// Tile shapes: Square (keycap style), Round, Hexagon, Letter outline (the glyph
// itself grown into a tile), or Icon (a built-in shape or your own image).
// All dimensions are in millimetres.
//
// Hinge between tile i (left) and tile i+1 (right), axis A between them:
//   tile i   : pin standing on the bed with a cone foot, held at the top by an
//              arm that bridges from tile i to the pin
//   tile i+1 : ring around the pin (with a neck to the tile), below the arm and
//              above the cone foot
// A spine along the hinge line runs through every tile, so any tile shape stays
// connected to its hinges; both tiles are notched around A so the parts can turn.
// Several names: separate them with commas. Each becomes its own chain, laid out side by side on 256 mm plates;
// when a plate is full the next ones continue to the right (Export can write one file per plate).

/* [Name] */
// Up to 20 characters per name; a space gives a blank tile (a short link for Letter outline). Commas separate names.
name = "NAME";
font_name = "Arial:style=Bold";
letter_style = "Raised"; // ["Raised","Engraved","Flush inlay"]
// 0 = automatic (largest size that fits the tile; for Letter outline the font size equals the tile size)
letter_size_mm = 0; // [0:0.5:40]
// Thickens thin strokes
letter_bold_mm = 0.2; // [0:0.05:1.5]
// Raised height, or depth for Engraved and Flush inlay
letter_depth_mm = 1; // [0.4:0.2:3]

/* [Tile] */
tile_shape = "Square"; // ["Square","Round","Hexagon","Letter outline","Icon"]
// Square/Round: width; Hexagon: flat-to-flat height; Icon: longest side; Letter outline: font size
tile_size_mm = 22; // [12:0.5:50]
tile_thickness_mm = 6; // [4:0.5:15]
// Square and Hexagon corners
corner_radius_mm = 5; // [0:0.5:10]
// Letter outline: border around the glyph
outline_mm = 2.5; // [1:0.25:6]
// Letter outline: closes gaps such as the dot of i and j (fills holes too)
outline_fill_mm = 2; // [0:0.25:6]

/* [Icon tile] */
// Choose image: SVG, PNG, JPG, or WebP (traced images use their full silhouette). Empty uses the built-in shape.
icon_left_file = "";
tile_icon = "Heart"; // ["Heart","Star","Flower","Diamond","Crown","Balloon","Shield","Cloud"]
// Letter size as a share of the icon size
icon_letter_scale = 0.5; // [0.2:0.05:0.8]
// Moves the letter up (+) or down (-) on the icon, as a share of the icon size
icon_letter_offset = 0; // [-0.3:0.01:0.3]

/* [Hinge] */
hinge_pin_mm = 2.2; // [1.6:0.1:4]
// Radial clearance between pin and ring; raise it if the hinge prints fused
hinge_clearance_mm = 0.35; // [0.2:0.05:0.7]
// Vertical gap above the ring
hinge_gap_mm = 0.4; // [0.2:0.05:0.8]
hinge_ring_wall_mm = 1.6; // [1:0.1:3]
hinge_arm_width_mm = 3; // [2:0.25:6]
hinge_arm_thickness_mm = 2; // [1.2:0.2:4]
// Gap between neighbouring tiles; a wider gap and rounder corners let the name bend further
tile_gap_mm = 3; // [1:0.25:10]

/* [Print] */
keyring = "Left"; // ["None","Left","Right"]
keyring_hole_mm = 4.5; // [2.5:0.5:8]
keyring_wall_mm = 2.2; // [1.2:0.2:5]
// Prints the chain along an arc (angle per hinge) so long names fit the bed
print_curve_deg = 0; // [0:1:30]

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
tile_color = "White"; // ["Black","White","Gray","Silver","Red","Orange","Gold","Yellow","LimeGreen","Green","DodgerBlue","Navy","MediumPurple","HotPink","SaddleBrown"]
letter_color = "DodgerBlue"; // ["Black","White","Gray","Silver","Red","Orange","Gold","Yellow","LimeGreen","Green","DodgerBlue","Navy","MediumPurple","HotPink","SaddleBrown"]

// Preview resolution only; FormForge exports at maximum resolution.
$fa = 6;
$fs = 0.3;

// ---------------------------------------------------------------- derived ---

// Written as expressions so they stay out of the parameter form.
probe = 5 * 2;            // font size used to measure letters
PHANTOM = 100 * 1000;     // helper offset for fitting icons by their longest side

// Several names, separated by commas. Values that depend on one name ($tile_chars, $count, $hw, $cx, $axes,
// $curve_deg, $loop_x) are set by name_chain() for the chain being drawn.
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
function chars_of(nm) = len(nm) > 0 ? [for (index = [0 : min(len(nm), 20) - 1]) nm[index]] : [" "];
// All letters of all names: one letter size for every chain.
tile_chars_all = [for (nm = names) each chars_of(nm)];
is_outline = tile_shape == "Letter outline";
H = tile_thickness_mm;

// Hinge
pin_r = hinge_pin_mm / 2;
foot_mm = 3 / 5;                                        // cone foot height (45 degrees)
arm_t = min(hinge_arm_thickness_mm, (H - hinge_gap_mm) / 2);
ring_top = H - hinge_gap_mm - arm_t;
ring_r = pin_r + hinge_clearance_mm + hinge_ring_wall_mm;
a = tile_gap_mm / 2;                                    // axis distance from each tile
// Radius swept by the arm or the ring neck outside its own tile while turning.
link_r = max(ring_r, sqrt(pow(a, 2) + pow(hinge_arm_width_mm / 2, 2)));
spine_w = hinge_arm_width_mm + 2;

// Letters
function probe_size(c) = textmetrics(c, size = probe, font = font_name).size;
visible = [for (c = tile_chars_all) if (c != " ") c];
widest = len(visible) > 0 ? max([for (c = visible) probe_size(c).x]) : 1;
tallest = len(visible) > 0 ? max([for (c = visible) probe_size(c).y]) : 1;
letter_size = letter_size_mm > 0 ? letter_size_mm
    : is_outline ? tile_size_mm
    : tile_shape == "Square" ? probe * (tile_size_mm - 2 * (0.3 * corner_radius_mm + 1.5 + letter_bold_mm)) / max(widest, tallest)
    : tile_shape == "Icon" ? probe * tile_size_mm * icon_letter_scale / max(widest, tallest)
    // Round, and Hexagon by its inscribed circle: the letter box diagonal must fit.
    : probe * (tile_size_mm - 2 * (1.5 + letter_bold_mm)) / norm([widest, tallest]);
function lm(c) = textmetrics(c, size = letter_size, font = font_name);
cap = lm("H").size.y;
space_mm = max(spine_w, letter_size * 0.3);

// Tile extents around its centre (x) and around the hinge line (y).
function half_w(c) = !is_outline
    ? (tile_shape == "Hexagon" ? tile_size_mm / cos(30) / 2 : tile_size_mm / 2)
    : c == " " ? space_mm / 2 : lm(c).size.x / 2 + outline_mm + letter_bold_mm;
function y_lo(c) = !is_outline ? -tile_size_mm / 2
    : c == " " ? -spine_w / 2 : min(-spine_w / 2, -cap / 2 + lm(c).position.y - outline_mm - letter_bold_mm);
function y_hi(c) = !is_outline ? tile_size_mm / 2
    : c == " " ? spine_w / 2 : max(spine_w / 2, -cap / 2 + lm(c).position.y + lm(c).size.y + outline_mm + letter_bold_mm);

// Per name: tile half widths, tile centres, hinge axes, straight length.
function hw_of(tc) = [for (c = tc) half_w(c)];
function centers_of(hw, i = 0, x = 0) = i >= len(hw) ? [] : concat([x], centers_of(hw, i + 1, i + 1 < len(hw) ? x + hw[i] + 2 * a + hw[i + 1] : x));
function axes_of(hw, cx) = [for (i = [0 : max(0, len(hw) - 2)]) cx[i] + hw[i] + a];
function chain_length_of(hw, cx) = cx[len(hw) - 1] + hw[len(hw) - 1] + hw[0];

// Bend limit per hinge from the tiles' bounding boxes (a tile never leaves its
// box, so this is safe). Boxes are rounded rectangles: inner rectangles grown
// by rc; they stay apart while the inner rectangles are 2 rc (plus the hinge
// clearance) apart, checked from every corner of each rectangle to the other.
rc = tile_shape == "Square" ? min(corner_radius_mm, tile_size_mm / 2)
    : tile_shape == "Round" ? tile_size_mm / 2
    : tile_shape == "Hexagon" ? tile_size_mm / 4
    : 0;
function corners(r) = [[r[0], r[2]], [r[1], r[2]], [r[0], r[3]], [r[1], r[3]]];
function turn(p, t) = [p[0] * cos(t) - p[1] * sin(t), p[0] * sin(t) + p[1] * cos(t)];
function to_rect(p, r) = norm([max(r[0] - p[0], 0, p[0] - r[1]), max(r[2] - p[1], 0, p[1] - r[3])]);
function left_box(tc, hw, i) = [-a - 2 * hw[i] + rc, -a - rc, y_lo(tc[i]) + rc, y_hi(tc[i]) - rc];
function right_box(tc, hw, i) = [a + rc, a + 2 * hw[i] - rc, y_lo(tc[i]) + rc, y_hi(tc[i]) - rc];
function box_gap(l, r, t) = min(concat([for (p = corners(r)) to_rect(turn(p, t), l)], [for (p = corners(l)) to_rect(turn(p, -t), r)])) - 2 * rc;
function hinge_limit(tc, hw, j) = let(blocked = [for (t = [1 : 90]) if (box_gap(left_box(tc, hw, j), right_box(tc, hw, j + 1), t) < hinge_clearance_mm) t])
    len(blocked) > 0 ? blocked[0] - 1 : 90;
function bend_limit_of(tc, hw) = len(tc) > 1 ? min([for (j = [0 : len(tc) - 2]) hinge_limit(tc, hw, j)]) : 90;

loop_r = keyring_hole_mm / 2 + keyring_wall_mm;
function loop_x_of(hw, cx) = keyring == "Right" ? cx[len(hw) - 1] + hw[len(hw) - 1] + loop_r - 1.2 : -hw[0] - loop_r + 1.2;

// Everything name_chain() needs for one name: [tile chars, half widths, centres, axes, bend limit, curve, loop x].
function chain_data(nm) =
    let(tc = chars_of(nm), hw = hw_of(tc), cx = centers_of(hw), ax = axes_of(hw, cx), limit = bend_limit_of(tc, hw))
    [tc, hw, cx, ax, limit, min(print_curve_deg, limit), loop_x_of(hw, cx)];

for (nm = names) let(d = chain_data(nm), length = chain_length_of(d[1], d[2])) {
    echo(str(nm, ": straight length ", round(length * 10) / 10, " mm, each hinge bends at least +/-", d[4],
        " degrees", len(visible) > 0 ? str(", letter size ", round(letter_size * 100) / 100, " mm") : ""));
    if (length > 250 && d[5] == 0)
        echo("The straight chain is longer than 250 mm; raise print_curve_deg to print it along an arc.");
    if (print_curve_deg > d[4])
        echo(str("print_curve_deg is limited to ", d[4], " degrees so neighbouring tiles stay apart."));
    if (d[5] > 0 && (len(d[0]) - 1) * d[5] > 270)
        echo("The arc turns more than 270 degrees; the ends may collide. Lower print_curve_deg.");
}

// ------------------------------------------------------------ 2D shapes ---

module rounded_square(w, d, r) { offset(r = r) square([max(0.01, w - 2 * r), max(0.01, d - 2 * r)], center = true); }
module closing(r) { if (r > 0) offset(r = -r) offset(r = r) children(); else children(); }

module builtin_icon(icon) {
    // Drawn at 100 mm so curves keep enough segments after resizing.
    scale([100, 100])
        if (icon == "Star")
            polygon(points = [for (i = [0 : 9]) let(t = 90 + i * 36, r = (i % 2 == 0) ? 0.5 : 0.25) [r * cos(t), r * sin(t)]]);
        else if (icon == "Flower")
            union() { for (t = [0 : 60 : 300]) rotate(t) translate([0, 0.25]) circle(d = 0.48, $fn = 64); circle(d = 0.6, $fn = 64); }
        else if (icon == "Diamond")
            polygon(points = [[0, 0.5], [0.42, 0], [0, -0.5], [-0.42, 0]]);
        else if (icon == "Crown")
            polygon(points = [[-0.48, -0.38], [-0.38, 0.3], [-0.12, 0.02], [0, 0.48], [0.14, 0.02], [0.4, 0.3], [0.48, -0.38]]);
        else if (icon == "Balloon")
            union() { translate([0, 0.08]) scale([1, 1.1]) circle(d = 0.76, $fn = 96); polygon(points = [[-0.1, -0.33], [0.1, -0.33], [0, -0.48]]); }
        else if (icon == "Shield")
            polygon(points = concat([[-0.42, 0.5], [0.42, 0.5]], [for (t = [0 : 10 : 180]) [0.42 * cos(t), -0.05 - 0.45 * sin(t)]]));
        else if (icon == "Cloud")
            union() { translate([-0.22, -0.08]) circle(d = 0.5, $fn = 64); translate([0.08, 0.05]) circle(d = 0.62, $fn = 64); translate([0.3, -0.1]) circle(d = 0.4, $fn = 64); translate([0, -0.2]) square([0.9, 0.24], center = true); }
        else // Heart
            scale(0.58) translate([0, -0.78]) rotate(45) union() {
                square(1);
                translate([0.5, 1]) circle(d = 1, $fn = 96);
                translate([1, 0.5]) circle(d = 1, $fn = 96);
            }
}

// Scales centred artwork so its longest side equals size: the artwork is
// resized together with a far-away copy turned 90 degrees (resize scales about
// the origin), then the copy is cut away.
module fit_longest(size) {
    intersection() {
        square(2 * size, center = true);
        resize([0, size], auto = true) { children(); translate([PHANTOM, 0]) rotate(90) children(); }
    }
}

module icon_shape_2d() {
    fill() closing(1) fit_longest(tile_size_mm)
        if (icon_left_file != "") import(file = icon_left_file, center = true);
        else builtin_icon(tile_icon);
}

// Letter centred on its own box (tiles), or on the shared baseline with the
// hinge line at half the cap height (Letter outline).
module letter_2d(c) {
    m = lm(c);
    offset(r = letter_bold_mm)
        if (is_outline) translate([-(m.position.x + m.size.x / 2), -cap / 2]) text(c, size = letter_size, font = font_name);
        else translate([-(m.position.x + m.size.x / 2), -(m.position.y + m.size.y / 2) + (tile_shape == "Icon" ? icon_letter_offset * tile_size_mm : 0)])
            text(c, size = letter_size, font = font_name);
}

module tile_shape_2d(c) {
    if (tile_shape == "Square") rounded_square(tile_size_mm, tile_size_mm, min(corner_radius_mm, tile_size_mm / 2 - 0.01));
    else if (tile_shape == "Round") circle(d = tile_size_mm);
    else if (tile_shape == "Hexagon") {
        cr = min(corner_radius_mm, tile_size_mm / 4);
        // $fn = 6 puts corners at the hinge sides and flat edges top and bottom.
        offset(r = cr) offset(delta = -cr) circle(d = tile_size_mm / cos(30), $fn = 6);
    }
    else if (tile_shape == "Icon") icon_shape_2d();
    else if (c != " ") fill() closing(outline_fill_mm) offset(r = outline_mm) letter_2d(c);
}

// Tile outline plus the spine along the hinge line. Inside the tile's convex
// hull the spine ties every part of the shape together; it only continues to
// the box edge on sides that have a hinge or the keyring, so end tiles keep
// their shape (a space tile in Letter outline mode is the spine itself).
module tile_2d(i) {
    c = $tile_chars[i];
    left = i > 0 || (keyring == "Left" && i == 0) || c == " ";
    right = i < $count - 1 || (keyring == "Right" && i == $count - 1) || c == " ";
    union() {
        tile_shape_2d(c);
        intersection() {
            translate([-$hw[i], -spine_w / 2]) square([2 * $hw[i], spine_w]);
            hull() tile_shape_2d(c);
        }
        if (left) translate([-$hw[i], -spine_w / 2]) square([$hw[i], spine_w]);
        if (right) translate([0, -spine_w / 2]) square([$hw[i], spine_w]);
    }
}

// ---------------------------------------------------------------- hinges ---

// Pin with a 45-degree cone foot, plus the arm that bridges to the left tile (axis at x = 0).
module hinge_pin() {
    rotate_extrude() polygon([[0, 0], [pin_r + foot_mm, 0], [pin_r, foot_mm], [pin_r, H], [0, H]]);
    translate([-a - 0.8, -hinge_arm_width_mm / 2, ring_top + hinge_gap_mm])
        cube([a + 0.8, hinge_arm_width_mm, H - ring_top - hinge_gap_mm]);
}

// Ring around the pin with a neck to the right tile (axis at x = 0).
module hinge_ring() {
    cylinder(r = ring_r, h = ring_top);
    translate([0, -hinge_arm_width_mm / 2, 0]) cube([a + 0.8, hinge_arm_width_mm, ring_top]);
}

// The pin profile grown by the clearance; doubled around the cone foot so the
// 45-degree faces cannot fuse.
module hinge_ring_hole() {
    c = hinge_clearance_mm;
    rotate_extrude() polygon([[0, -1], [pin_r + c + foot_mm + c + 1, -1], [pin_r + c, foot_mm + c], [pin_r + c, H + 1], [0, H + 1]]);
}

// Room for the right neighbour's ring and neck (on tile i) or the left
// neighbour's arm (on tile i+1).
module ring_notch() { translate([0, 0, -1]) cylinder(r = link_r + hinge_clearance_mm, h = ring_top + hinge_gap_mm / 2 + 1); }
module arm_notch() { translate([0, 0, ring_top]) cylinder(r = link_r + hinge_clearance_mm, h = H + letter_depth_mm + 2); }

// ----------------------------------------------------------------- tiles ---

function has_loop(i) = keyring == "Left" && i == 0 || keyring == "Right" && i == $count - 1;

module tile_cuts(i) {
    if (i < $count - 1) translate([$axes[i], 0, 0]) ring_notch();
    if (i > 0) translate([$axes[i - 1], 0, 0]) { arm_notch(); hinge_ring_hole(); }
    if (has_loop(i)) translate([$loop_x, 0, -1]) cylinder(d = keyring_hole_mm, h = H + 2);
}

module tile(i) {
    c = $tile_chars[i];
    has_letter = c != " ";
    color(tile_color) union() {
        difference() {
            union() {
                translate([$cx[i], 0, 0]) linear_extrude(height = H) tile_2d(i);
                if (i > 0) translate([$axes[i - 1], 0, 0]) hinge_ring();
                if (has_loop(i)) {
                    translate([$loop_x, 0, 0]) cylinder(r = loop_r, h = min(H, 4));
                    translate([min($loop_x, $cx[i]), -spine_w / 2, 0]) cube([abs($loop_x - $cx[i]), spine_w, min(H, 4)]);
                }
            }
            tile_cuts(i);
            if (has_letter && letter_style != "Raised")
                translate([$cx[i], 0, H - letter_depth_mm]) linear_extrude(height = letter_depth_mm + 1) letter_2d(c);
        }
        if (i < $count - 1) translate([$axes[i], 0, 0]) hinge_pin();
    }
    if (has_letter && letter_style != "Engraved")
        color(letter_color) difference() {
            translate([$cx[i], 0, letter_style == "Raised" ? H - 0.01 : H - letter_depth_mm])
                linear_extrude(height = letter_depth_mm + (letter_style == "Raised" ? 0.01 : 0)) letter_2d(c);
            tile_cuts(i);
        }
}

// Bends tile i by $curve_deg at every hinge before it; $curve_deg never exceeds
// the bend limit, so neighbouring tiles keep at least the hinge clearance.
module chain_place(i) {
    if (i <= 0 || $curve_deg == 0) children();
    else chain_place(i - 1)
        translate([$axes[i - 1], 0, 0]) rotate($curve_deg) translate([-$axes[i - 1], 0, 0]) children();
}

// One chain: sets the per-name values the tile and hinge modules read.
module name_chain(nm) {
    d = chain_data(nm);
    $tile_chars = d[0];
    $count = len(d[0]);
    $hw = d[1];
    $cx = d[2];
    $axes = d[3];
    $curve_deg = d[5];
    $loop_x = d[6];
    for (i = [0 : $count - 1]) chain_place(i) tile(i);
}

// Footprint [xmin, ymin, xmax, ymax] of one chain: every tile as a circle around its (placed) centre, so the
// box also holds when the chain is printed along an arc.
function rot_about(p, c, t) = [c + (p[0] - c) * cos(t) - p[1] * sin(t), (p[0] - c) * sin(t) + p[1] * cos(t)];
function place_pt(p, i, ax, t) = i <= 0 || t == 0 ? p : place_pt(rot_about(p, ax[i - 1], t), i - 1, ax, t);
function item_box(nm) =
    let(d = chain_data(nm), tc = d[0], hw = d[1], cx = d[2], ax = d[3], t = d[5], n = len(tc),
        straight = t == 0,
        ylo = min([for (c = tc) y_lo(c)]), yhi = max([for (c = tc) y_hi(c)]),
        pts = [for (i = [0 : n - 1]) let(p = place_pt([cx[i], 0], i, ax, t), r = norm([hw[i], max(-y_lo(tc[i]), y_hi(tc[i]))]))
                   each (straight ? [[cx[i] - hw[i], ylo], [cx[i] + hw[i], yhi]] : [p - [r, r], p + [r, r]])],
        ring = keyring == "None" ? [] : let(i = keyring == "Right" ? n - 1 : 0, p = place_pt([d[6], 0], i, ax, t))
                   [p - [loop_r, loop_r], p + [loop_r, loop_r]],
        all = concat(pts, ring))
    [min([for (p = all) p[0]]), min([for (p = all) p[1]]), max([for (p = all) p[0]]), max([for (p = all) p[1]])];

// ------------------------------------------------- several names on plates ---

PLATE = 256;
PLATE_PITCH = 268;   // FormForge draws plates 12 mm apart; more plates continue to +X
usable = PLATE - 2 * plate_margin;
boxes = [for (nm = names) item_box(nm)];
// Shelf packing: side by side in a row, a new row when the plate width is used up, the next plate when the
// rows reach the bottom. Returns [plate, x, y] from the plate's top-left corner for every chain.
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
// A single chain stays centred on plate 1.
function item_offset(r) = len(names) == 1
    ? [move_x - (boxes[0][0] + boxes[0][2]) / 2, move_y - (boxes[0][1] + boxes[0][3]) / 2]
    : let(p = only_plate == 0 ? slots[r][0] : 0)
      [move_x + p * PLATE_PITCH - usable / 2 + slots[r][1] - boxes[r][0], move_y + usable / 2 - slots[r][2] - boxes[r][3]];
shown_items = [for (r = [0 : len(names) - 1]) if (shown(r)) r];

// ----------------------------------------------------------------- model ---

union() {
    for (r = shown_items) translate(item_offset(r)) name_chain(names[r]);
}
