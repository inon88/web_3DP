// Articulated cube keychain — one solid cube per letter, printed in place as a flexible chain.
//
// Joints copy the "Flexible Keychain" (MakerWorld) principle: two round links at right angles, hooked into each
// other in the gap between the cubes, like the links of a chain.
//   +X side of a cube: a round D-shaped link lying flat (XY plane). Its legs taper at 45° from the face; its thin
//   front is a short bridge between them.
//   -X side of a cube: a round D-shaped link standing upright (XZ plane). Its underside follows a 45° line that
//   touches the round front, and its hole is a teardrop, so nothing overhangs more than 45°.
// Each face has a pocket where the partner link moves, so the chain bends up/down and sideways and twists.
// Several keychains: separate the words with commas — every word becomes its own chain with its own key ring.
// They are laid out side by side on 256 mm plates; when a plate is full the next ones continue to the right
// (show them with the Plates menu of the viewport, e.g. "3 plates · 3 × 1", and export them one at a time).
// 3MF export: cubes and letters are separate parts (two filaments).
// @formforge-3mf-objects

/* [Text] */
// One cube per character (max 20 per word). Commas make separate keychains (max 40); a space makes a blank cube, * makes a heart
text_chars = "ensavent, I*U, LOVE, MOM, DAD";
font_name = "Liberation Sans:style=Bold";
// Letter height as a share of the cube size
letter_ratio = 0.62; // [0.3:0.01:0.85]
letter_style = "Raised"; // ["Raised","Inlay"]
// Raised height, or inlay depth
letter_relief = 1; // [0.4:0.1:3]
// Turns the letters to read from the side instead of along the chain
letter_rotation = 0; // [0:90:270]

/* [Cubes] */
cube_size = 14; // [10:0.5:30]
// Gap between neighbouring cubes
cube_gap = 1.8; // [1:0.1:5]
corner_radius = 1; // [0:0.1:4]
/* [Plate layout] */
// Space between keychains, beside and above each other
row_spacing = 6; // [2:0.5:30]
// Free border around each 256 mm plate
plate_margin = 5; // [0:0.5:30]
// 0 = all plates; 1, 2, … = only that plate, moved onto plate 1 (export plates one at a time)
export_plate = 0; // [0:1:20]
// Moves everything on the plate
move_x = 0; // [-400:0.5:400]
move_y = 0; // [-400:0.5:400]

/* [Links] */
// Clearance between the links and everything around them (0.3–0.5 for most printers)
clearance = 0.4; // [0.2:0.05:0.8]
// Extra room on top of the clearance: a looser, more flexible chain
link_play = 0.3; // [0:0.05:2]
// Size of the links (1 = proportions of the reference model)
link_size = 1; // [0.6:0.05:1.4]

/* [Key ring] */
key_ring = "Ring"; // ["None","Ring"]
ring_outer_diameter = 11; // [6:0.5:24]
ring_hole_diameter = 5.5; // [2:0.5:16]
ring_thickness = 3; // [1.5:0.1:8]

/* [Colors] */
cube_color = "#D9C2A0";
letter_color = "#FFFFFF";

$fa = 6;
$fs = 0.4;

// --- Words --------------------------------------------------------------------------------------------------
EPS = 0.01;
function split_commas(t, i = 0, cur = "", out = []) =
    i >= len(t) ? concat(out, [cur])
  : t[i] == "," ? split_commas(t, i + 1, "", concat(out, [cur]))
  : split_commas(t, i + 1, str(cur, t[i]), out);
function substr(t, a, b) = a >= b ? "" : chr([for (i = [a : b - 1]) ord(t[i])]);
function first_solid(t, i = 0) = i < len(t) && t[i] == " " ? first_solid(t, i + 1) : i;
function last_solid(t, i) = i > 0 && t[i - 1] == " " ? last_solid(t, i - 1) : i;
function trim(t) = let(a = first_solid(t)) substr(t, a, last_solid(t, len(t)));
function chars_of(t) = [for (i = [0 : 1 : min(len(t), 20) - 1]) t[i]];
found = [for (w = split_commas(text_chars)) let(t = trim(w)) if (len(t) > 0) chars_of(t)];
words = len(found) == 0 ? [[" "]] : [for (i = [0 : min(len(found), 40) - 1]) found[i]];

// --- Link geometry ------------------------------------------------------------------------------------------
s = cube_size;
pitch = s + cube_gap;
row_pitch = s + row_spacing;
zc = s / 2;                      // links sit at mid height
G = clearance + link_play;       // free space around every link
// Link proportions follow the cube, limited so the pockets keep at least 1 mm of cube above, below and beside them.
k_wanted = s / 14 * link_size;
k = min(k_wanted,
        (s / 2 - 1 - (clearance + link_play) * (1 + sqrt(2))) / (1.6 * sqrt(2) + 1.8),
        (s / 2 - 1 - 2 * (clearance + link_play)) / 3.45);
wire = 1.8 * k;                  // thickness of the link wire
hb = 1.6 * k;                    // half height of the flat link's front (3.2 mm, as in the reference)
vy = 1.65 * k;                   // half width of the upright link (3.3 mm, as in the reference)
floor_z = -(s / 2 - 1.2);        // lowest point a link may reach (relative to zc)
inlay = letter_style == "Inlay" ? min(letter_relief, 1.6) : 0;
R2 = sqrt(2);

// Joint frame: x = 0 in the middle of the gap, cube i on the -X side, cube i + 1 on the +X side, z = 0 at zc.
face_i = -cube_gap / 2;
face_j = cube_gap / 2;
// Upright link (cube i + 1): round front centred on xc, wire between radii vz0 and vz1.
xv1 = -G / 2;                                // inner edge of its front at z = 0
vz0 = hb + G;
vz1 = vz0 + wire;
xc = xv1 + vz0;
xv0 = xc - vz1;                              // outer edge of its front (reaches into cube i)
xv_in = xc - sqrt(vz0 * vz0 - hb * hb);      // inner edge where the flat link's front passes (|z| = hb)
v_top = vz0 * sqrt(2) + wire;                // top of the upright link: full wire above its teardrop hole
// Flat link (cube i): round front centred on xhc, wire between radii hy0 and hy1. Centring it on xv_in keeps the
// gap G to the upright link everywhere along the curve.
hy0 = vy + G;
hy1 = hy0 + wire;
xhc = xv_in;
xh1 = xhc + hy1;                             // tip (reaches into cube i + 1)
back_i = xv0 - G;                            // back wall of the pocket in cube i
back_j = xh1 + G;                            // back wall of the pocket in cube i + 1
root_j = back_j + wire;                      // the upright link is rooted this deep in cube i + 1
// Half height of the flat link's legs: 45° taper from cube i down to the tip.
function h_half(x) = min(hb + max(0, xh1 - x), s / 2 - 0.6);
// Underside of the upright link: 45° line touching its round front, never below the floor.
function v_line(x) = max(floor_z, -(x - xc) - vz1 * R2);

if (k < k_wanted - 0.01) echo(str("Links reduced to ", round(100 * k / k_wanted), "% to fit the cube; use a larger cube or less clearance/play for stronger links."));

function fit_text(t, w, h) = let(m = textmetrics(text = t, size = 10, font = font_name))
    10 * min(w / max(m.size[0], EPS), h / max(m.size[1], EPS));

// --- Links (joint frame) ------------------------------------------------------------------------------------
module flat_link() {
    root = face_i - 1;
    // D shape: two straight legs from the root plus a half-ring front.
    module ring_2d() {
        for (sy = [-1, 1]) translate([root, sy > 0 ? hy0 : -hy1]) square([xhc - root + EPS, wire]);
        intersection() {
            translate([xhc, 0]) difference() { circle(r = hy1); circle(r = hy0); }
            translate([xhc, -hy1 - 1]) square([hy1 + 1, 2 * hy1 + 2]);
        }
    }
    // Sides (|y| >= hy0): tapered at 45°.
    intersection() {
        translate([0, 0, -s]) linear_extrude(height = 2 * s) ring_2d();
        translate([0, hy1 + 1, 0]) rotate([90, 0, 0]) linear_extrude(height = 2 * hy1 + 2)
            polygon([[root, -h_half(root)], [xh1 + 1, -h_half(xh1 + 1)], [xh1 + 1, h_half(xh1 + 1)], [root, h_half(root)]]);
        for (sy = [-1, 1]) translate([root - 1, sy > 0 ? hy0 : -hy1 - 1, -s]) cube([xh1 - root + 2, hy1 + 1 - hy0, 2 * s]);
    }
    // Front (|y| < hy0): thin, it passes through the upright link.
    intersection() {
        translate([0, 0, -hb]) linear_extrude(height = 2 * hb) ring_2d();
        translate([root - 1, -hy0, -hb - 1]) cube([xh1 - root + 2, 2 * hy0, 2 * hb + 2]);
    }
}

module upright_link() {
    t = [xc - vz1 / R2, -vz1 / R2];          // where the 45° line touches the round front
    x_f = xc - vz1 * R2 - floor_z;           // where the line reaches the floor
    support = concat([t], x_f < root_j ? [[x_f, floor_z]] : [], [[root_j, v_line(root_j)], [root_j, 0], [t[0], 0]]);
    tip = vz0 * R2;                          // top of the teardrop hole
    top = v_top;                             // the wire stays full thickness above it
    translate([0, vy, 0]) rotate([90, 0, 0]) linear_extrude(height = 2 * vy) difference() {
        union() {
            hull() { translate([xc, 0]) circle(r = vz1); translate([xc, top - 0.01]) square([0.01, 0.01]); }
            translate([xc, -vz1]) square([root_j - xc, vz1 + top]);
            polygon(support);
        }
        hull() { translate([xc, 0]) circle(r = vz0); translate([xc, tip]) circle(r = 0.01); }
        translate([xc, -vz0]) square([back_j - xc, 2 * vz0]);
    }
}

// Pockets: a box for the partner link, with a 45° flared mouth so the cubes can bend and swing.
// Box: from the face to `back`, half sizes hy / hz; the mouth grows by `flare` at the face.
// The flare stops 0.8 mm short of the cube's outside.
module pocket(face, back, hy, hz) {
    dir = sign(back - face);          // into the cube
    fy = max(0, min(flare, s / 2 - 0.8 - hy));
    fz = max(0, min(flare, s / 2 - 0.8 - hz));
    module slab(x, ey, ez) translate([x - EPS / 2, -ey, -ez]) cube([EPS, 2 * ey, 2 * ez]);
    hull() { slab(face - dir, hy, hz); slab(back, hy, hz); }
    hull() { slab(face - dir, hy + fy, hz + fz); slab(face, hy + fy, hz + fz); slab(face + dir * flare, hy, hz); }
}
flare = 1.5 * k;

// Pocket in cube i for the upright link of cube i + 1.
module pocket_i() { pocket(face_i, back_i, vy + G, v_top + G); }

// Pocket in cube i + 1 for the flat link of cube i.
module pocket_j() { pocket(face_j, back_j, hy1 + G, h_half(face_j) + G); }

// --- Cubes --------------------------------------------------------------------------------------------------
module rounded_square(size, r) {
    if (r > 0) offset(r = r) square(size - 2 * r, center = true);
    else square(size, center = true);
}

module heart_2d(size) {
    scale(size) for (q = [-1, 1]) hull() { translate([q * 0.23, 0.18]) circle(r = 0.27, $fs = $fs / size); translate([0, -0.45]) circle(r = 0.02); }
}

module letter_2d(ch) {
    h = s * letter_ratio;
    rotate(letter_rotation)
        if (ch == "*") heart_2d(h);
        else if (ch != " ") let(size = fit_text(ch, s - 3, h), m = textmetrics(text = ch, size = size, font = font_name))
            translate(-(m.position + m.size / 2)) text(ch, size = size, font = font_name);
}

module key_ring_part() {
    translate([-s / 2 - ring_outer_diameter / 2 + 1.2, 0, 0]) linear_extrude(height = ring_thickness) difference() {
        union() {
            circle(d = ring_outer_diameter);
            translate([0, -ring_outer_diameter / 4]) square([ring_outer_diameter / 2, ring_outer_diameter / 2]);
        }
        circle(d = ring_hole_diameter);
    }
}

// Cube i of a word (centred on x = 0) with both of its links.
module piece_local(word, i) {
    n = len(word);
    difference() {
        linear_extrude(height = s) rounded_square(s, corner_radius);
        if (i < n - 1) translate([pitch / 2, 0, zc]) pocket_i();
        if (i > 0) translate([-pitch / 2, 0, zc]) pocket_j();
        if (inlay > 0) translate([0, 0, s - inlay]) linear_extrude(height = inlay + 1) offset(delta = 0.1) letter_2d(word[i]);
    }
    if (i < n - 1) translate([pitch / 2, 0, zc]) flat_link();
    if (i > 0) translate([-pitch / 2, 0, zc]) upright_link();
    if (i == 0 && key_ring == "Ring") key_ring_part();
}

// --- Plate layout -------------------------------------------------------------------------------------------
// Shelf packing: keychains side by side in a row while they fit the plate width, then the next row, then the
// next plate. Plates are 256 mm, PLATE_PITCH apart along +X — the same grid as the viewport's Plates menu
// (plate 1 is centred on the origin).
PLATE = 256;
PLATE_PITCH = 268;
usable = PLATE - 2 * plate_margin;
ring_left = key_ring == "Ring" ? ring_outer_diameter - 1.2 : 0;   // the key ring sticks out left of cube 0
function chain_width(r) = ring_left + (len(words[r]) - 1) * pitch + s;
rows_per_plate = max(1, floor((usable + row_spacing) / row_pitch));
// [plate, row, x] for every keychain.
function shelf(r = 0, plate = 0, row = 0, x = 0, out = []) =
    r >= len(words) ? out
  : let(w = chain_width(r),
        wrap = x > 0 && x + w > usable,
        row1 = wrap ? row + 1 : row,
        next_plate = row1 >= rows_per_plate,
        p = next_plate ? plate + 1 : plate,
        rw = next_plate ? 0 : row1,
        x1 = wrap ? 0 : x)
    shelf(r + 1, p, rw, x1 + w + row_spacing, concat(out, [[p, rw, x1]]));
slots = shelf();
plates_used = slots[len(slots) - 1][0] + 1;
echo(str("Keychains: ", len(words), " on ", plates_used, " plate(s)"));
// Tells FormForge how many plates there are: Export then offers one file per plate (rendered with export_plate = 1…n).
echo("formforge-plates", plates_used);
for (r = [0 : len(words) - 1]) if (chain_width(r) > usable)
    echo(str("Keychain ", r + 1, " is ", round(chain_width(r)), " mm long and does not fit a plate; use a smaller cube_size."));

only_plate = min(export_plate, plates_used);   // a plate number past the last one shows the last plate
function shown(r) = only_plate == 0 || slots[r][0] == only_plate - 1;
// Centre of cube 0 of keychain r.
function chain_origin(r) =
    let(p = only_plate == 0 ? slots[r][0] : 0)
    [move_x + p * PLATE_PITCH - usable / 2 + slots[r][2] + ring_left + s / 2,
     move_y + usable / 2 - s / 2 - slots[r][1] * row_pitch];

module chain_piece(r, i) { translate(concat(chain_origin(r) + [i * pitch, 0], [0])) piece_local(words[r], i); }

module chain_letters(r) {
    word = words[r];
    for (i = [0 : len(word) - 1]) if (word[i] != " ")
        translate(concat(chain_origin(r) + [i * pitch, 0], [s - inlay - (inlay > 0 ? 0 : EPS)]))
            linear_extrude(height = inlay > 0 ? inlay : letter_relief + EPS) letter_2d(word[i]);
}

visible = [for (r = [0 : len(words) - 1]) if (shown(r)) r];

// Two top-level statements = two 3MF parts.
color(cube_color) for (r = visible) for (i = [0 : len(words[r]) - 1]) chain_piece(r, i);
if (len([for (r = visible) for (ch = words[r]) if (ch != " ") ch]) > 0)
    color(letter_color) for (r = visible) chain_letters(r);
