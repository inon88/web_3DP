// Decorated font — a large hollow initial (up to 4 letters) with a name, birth details and decorations.
//
// The letter is a shell: face + walls of `wall_mm`, open at the back. It prints upside down (face on the
// plate, open side up) without infill. A thin bottom cover — the letter outline offset inwards — drops into
// the opening and rests on a stepped seat inside the walls (45° chamfer underneath, so no supports).
// Name, badges and decorations are separate flat pieces glued onto the face.
//
// Viewport: click the name, a badge or a decoration, then press G (move), R (rotate) or S (scale).
// 3MF export: every color is its own part, grouped as one object.
// @formforge-3mf-objects

/* [Main letter] */
// Up to 4 characters
main_text = "E";
font_name = "Liberation Sans:style=Bold";
// Height of the letters (mm)
letter_height = 200; // [60:1:250]
// Limits the total width (0 = off), e.g. 250 to keep 4 letters on one plate
letter_max_width = 0; // [0:1:600]
letter_spacing = 1; // [0.6:0.01:1.4]
// Rounds the outer corners of the letters
corner_radius = 3; // [0:0.5:10]
// Total depth of the letter body
depth_mm = 22; // [6:1:60]
// Thickness of the face and the walls
wall_mm = 2; // [1:0.1:5]
letter_color = "#C2185B";

/* [Bottom cover] */
show_cover = true;
cover_thickness = 1.6; // [0.8:0.2:4]
// Gap between the cover and the walls
cover_clearance = 0.2; // [0:0.05:0.8]
// Width of the step the cover rests on
seat_width = 1.6; // [0.8:0.2:4]
// Keyhole slot in the cover for hanging on a nail
hanger = "Keyhole"; // ["None","Keyhole"]
// Position of the keyhole (must be inside the letter)
hanger_x = 0; // [-120:1:120]
hanger_y = 84; // [-120:1:120]
cover_color = "#C2185B";

/* [Name] */
name_text = "Elizabet";
name_font = "Segoe Script:style=Bold";
name_size = 36; // [8:1:120]
name_x = 12; // [-128:0.5:128]
name_y = -66; // [-128:0.5:128]
name_rot = 10; // [-180:1:180]
name_thickness = 4; // [1:0.2:12]
// Thickens the letters so a script name stays in one piece
name_bold = 1.2; // [0:0.1:5]
name_color = "#FFF5F8";

/* [Birth date] */
show_date = true;
// YYYY-MM-DD (also accepts DD-MM-YYYY, with -, / or .)
birth_date = "2025-01-25";
date_format = "YYYY.MM.DD."; // ["YYYY.MM.DD.","DD.MM.YYYY","DD Mon YYYY"]
date_two_lines = true;
date_x = 44; // [-128:0.5:128]
date_y = 84; // [-128:0.5:128]
date_rot = -6; // [-180:1:180]
date_size = 44; // [20:1:110]

/* [Birth time] */
show_time = true;
birth_time = "03:52";
time_x = -14; // [-128:0.5:128]
time_y = 10; // [-128:0.5:128]
time_rot = 0; // [-180:1:180]
time_size = 38; // [16:1:100]

/* [Weight] */
show_weight = true;
weight_text = "2990g";
weight_x = 38; // [-128:0.5:128]
weight_y = 10; // [-128:0.5:128]
weight_rot = 0; // [-180:1:180]
weight_size = 30; // [16:1:100]

/* [Length] */
show_length = true;
length_text = "49 cm";
length_x = -55; // [-128:0.5:128]
length_y = 32; // [-128:0.5:128]
length_rot = 90; // [-180:1:180]
length_size = 60; // [20:1:140]

/* [Shio] */
show_shio = false;
// Auto reads the birth date (Chinese New Year table 1990–2035, otherwise 4 February)
shio = "Auto"; // ["Auto","Rat","Ox","Tiger","Rabbit","Dragon","Snake","Horse","Goat","Monkey","Rooster","Dog","Pig"]
// Optional picture for the shio badge (replaces the coin emblem)
icon_right_file = "";
shio_x = -55; // [-128:0.5:128]
shio_y = -38; // [-128:0.5:128]
shio_rot = 90; // [-180:1:180]
shio_size = 50; // [24:1:120]

/* [Zodiac] */
show_zodiac = false;
zodiac = "Auto"; // ["Auto","Aries","Taurus","Gemini","Cancer","Leo","Virgo","Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"]
// Optional picture for the zodiac badge (replaces the drawn symbol)
icon_left_file = "";
zodiac_x = 4; // [-128:0.5:128]
zodiac_y = 84; // [-128:0.5:128]
zodiac_rot = 0; // [-180:1:180]
zodiac_size = 40; // [24:1:120]

/* [Badge style] */
label_language = "Indonesia"; // ["Indonesia","English"]
badge_thickness = 2; // [1:0.2:6]
// Height of the raised text and details on a badge
badge_relief = 0.8; // [0.4:0.2:3]
badge_color = "#F8BBD0";
badge_text_color = "#FFFFFF";

/* [Decorations] */
// Elements of the tree can be dragged in the viewport. A Rainbow icon always uses rainbow colors.
// @formforge-nested-tree max-depth=3 icons=Rainbow,Cloud,Star,Heart,Moon,Sun,Balloon,Crown,Flower
// @formforge-nested-default [{"type":"Icon","icon":"Rainbow","x":-50,"y":88,"size":64,"thickness":2.4,"color":"#ffffff","children":[{"type":"Icon","icon":"Cloud","x":-26,"y":-13,"size":24,"thickness":1.6,"color":"#ffffff"},{"type":"Icon","icon":"Cloud","x":26,"y":-13,"size":24,"thickness":1.6,"color":"#ffffff"}]}]
decorative_layers = [];

/* [Layout] */
// Assembled shows the finished piece; Print plates puts the body, the cover and the decorations on plates 1–3
layout = "Assembled"; // ["Assembled","Print plates"]
export_part = "All"; // ["All","Letter body","Bottom cover","Decorations"]
// Moves the whole design on the plate
move_x = 0; // [-400:0.5:400]
move_y = 0; // [-400:0.5:400]

$fa = 6;
$fs = 0.8;

// --- Constants --------------------------------------------------------------------------------------------
PLATE_PITCH = 268;   // FormForge draws 256 mm plates 12 mm apart
PHANTOM = 100 * 1000;  // offset of the helper copy used to fit custom images
EPS = 0.01;
RAINBOW = ["#E53935", "#FB8C00", "#FDD835", "#43A047", "#1E88E5", "#8E24AA"];
SHIO_EN = ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"];
SHIO_ID = ["Tikus", "Kerbau", "Macan", "Kelinci", "Naga", "Ular", "Kuda", "Kambing", "Monyet", "Ayam", "Anjing", "Babi"];
ZODIAC_EN = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"];
ZODIAC_ID = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagitarius", "Capricorn", "Aquarius", "Pisces"];
MONTHS_EN = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
MONTHS_ID = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"];
// Chinese New Year [month, day] for 1990..2035
CNY = [[1,27],[2,15],[2,4],[1,23],[2,10],[1,31],[2,19],[2,7],[1,28],[2,16],
       [2,5],[1,24],[2,12],[2,1],[1,22],[2,9],[1,29],[2,18],[2,7],[1,26],
       [2,14],[2,3],[1,23],[2,10],[1,31],[2,19],[2,8],[1,28],[2,16],[2,5],
       [1,25],[2,12],[2,1],[1,22],[2,10],[1,29],[2,17],[2,6],[1,26],[2,13],
       [2,3],[1,23],[2,11],[1,31],[2,19],[2,8]];
// Day of the month on which the next sun sign starts, January..December
ZODIAC_CUT = [20, 19, 21, 20, 21, 21, 23, 23, 23, 23, 22, 22];

// --- Text and date helpers ----------------------------------------------------------------------------------
function digit_groups(s, i = 0, cur = "", out = []) =
    i >= len(s) ? (cur == "" ? out : concat(out, [cur]))
    : let(c = s[i], d = ord(c) >= 48 && ord(c) <= 57)
      d ? digit_groups(s, i + 1, str(cur, c), out)
        : digit_groups(s, i + 1, "", cur == "" ? out : concat(out, [cur]));
function to_int(s, i = 0, acc = 0) = i >= len(s) ? acc : to_int(s, i + 1, acc * 10 + ord(s[i]) - 48);
function pad2(n) = n < 10 ? str("0", n) : str(n);
function clamp(v, lo, hi) = min(hi, max(lo, v));
function first_chars(s, n) = len(s) == 0 ? "" : chr([for (i = [0 : 1 : min(n, len(s)) - 1]) ord(s[i])]);

date_groups = digit_groups(birth_date);
date_ymd = len(date_groups) < 3 ? [2025, 1, 1]
    : len(date_groups[0]) == 4 ? [to_int(date_groups[0]), to_int(date_groups[1]), to_int(date_groups[2])]
    : [to_int(date_groups[2]), to_int(date_groups[1]), to_int(date_groups[0])];
birth_year = date_ymd[0];
birth_month = clamp(date_ymd[1], 1, 12);
birth_day = clamp(date_ymd[2], 1, 31);

months = label_language == "English" ? MONTHS_EN : MONTHS_ID;
date_lines =
    date_format == "DD.MM.YYYY" ? (date_two_lines ? [str(pad2(birth_day), ".", pad2(birth_month), "."), str(birth_year)]
                                                  : [str(pad2(birth_day), ".", pad2(birth_month), ".", birth_year)])
  : date_format == "DD Mon YYYY" ? (date_two_lines ? [str(birth_day, " ", months[birth_month - 1]), str(birth_year)]
                                                   : [str(birth_day, " ", months[birth_month - 1], " ", birth_year)])
  : (date_two_lines ? [str(birth_year, "."), str(pad2(birth_month), ".", pad2(birth_day), ".")]
                    : [str(birth_year, ".", pad2(birth_month), ".", pad2(birth_day), ".")]);

cny = birth_year >= 1990 && birth_year <= 2035 ? CNY[birth_year - 1990] : [2, 4];
lunar_year = (birth_month < cny[0] || (birth_month == cny[0] && birth_day < cny[1])) ? birth_year - 1 : birth_year;
shio_index = shio == "Auto" ? ((lunar_year - 4) % 12 + 12) % 12 : search([shio], SHIO_EN)[0];
zodiac_index = zodiac == "Auto"
    ? (birth_day >= ZODIAC_CUT[birth_month - 1] ? (birth_month + 9) % 12 : (birth_month + 8) % 12)
    : search([zodiac], ZODIAC_EN)[0];
shio_label = (label_language == "English" ? SHIO_EN : SHIO_ID)[shio_index];
zodiac_label = (label_language == "English" ? ZODIAC_EN : ZODIAC_ID)[zodiac_index];

// Text size so that `t` is at most `w` wide and `h` tall.
function fit_text(t, f, w, h) =
    let(m = textmetrics(text = t, size = 10, font = f))
    10 * min(w / max(m.size[0], EPS), h / max(m.size[1], EPS));

// --- Geometry helpers ---------------------------------------------------------------------------------------
function rot2(v, a) = [v[0] * cos(a) - v[1] * sin(a), v[0] * sin(a) + v[1] * cos(a)];
function arc(c, r, a0, a1, n = 18) = [for (i = [0 : n]) c + r * [cos(a0 + (a1 - a0) * i / n), sin(a0 + (a1 - a0) * i / n)]];

module stroke(points, w) {
    for (i = [0 : len(points) - 2]) hull() { translate(points[i]) circle(d = w); translate(points[i + 1]) circle(d = w); }
}

// Scales unit-size artwork; $fs is divided too, so curves get the resolution of the final size.
module unit_scale(s) { scale(s) let($fs = $fs / s) children(); }

module rounded_rect(w, h, r) {
    offset(r = r) square([max(w - 2 * r, EPS), max(h - 2 * r, EPS)], center = true);
}

module fit_longest(size) {
    intersection() {
        square(2 * size, center = true);
        resize([0, size], auto = true) {
            children();
            translate([PHANTOM, 0]) rotate(90) children();
        }
    }
}

module text_lines(lines, f, w, h) {
    n = len(lines);
    s = min([for (l = lines) fit_text(l, f, w, h / n / 1.25)]);
    for (i = [0 : n - 1])
        translate([0, (n - 1) / 2 * s * 1.3 - i * s * 1.3]) text(lines[i], size = s, font = f, halign = "center", valign = "center");
}

// --- Main letter --------------------------------------------------------------------------------------------
letters = len(main_text) > 0 ? first_chars(main_text, 4) : "A";
letter_metrics = textmetrics(text = letters, size = 100, font = font_name, spacing = letter_spacing);
letter_scale = min(letter_height / max(letter_metrics.size[1], EPS),
                   letter_max_width > 0 ? letter_max_width / max(letter_metrics.size[0], EPS) : 1e9);

module letter_2d() {
    r = corner_radius;
    offset(r = r) offset(delta = -r)
        scale(letter_scale)
            translate(-(letter_metrics.position + letter_metrics.size / 2))
                text(letters, size = 100, font = font_name, spacing = letter_spacing);
}

// Shell standing on its open side: walls from z = 0, face on top at z = depth.
module letter_body() {
    difference() {
        linear_extrude(height = depth_mm) letter_2d();
        translate([0, 0, -1]) linear_extrude(height = depth_mm - wall_mm + 1) offset(delta = -wall_mm) letter_2d();
    }
    // Seat for the cover: a ledge just above it, tapering to the wall at 45° (printable upside down).
    steps = max(2, ceil(seat_width / 0.3));
    for (i = [0 : steps - 1])
        translate([0, 0, cover_thickness + i * seat_width / steps])
            linear_extrude(height = seat_width / steps + EPS)
                difference() {
                    offset(delta = -wall_mm + EPS) letter_2d();
                    offset(delta = -wall_mm - seat_width * (1 - i / steps)) letter_2d();
                }
}

module letter_cover() {
    difference() {
        linear_extrude(height = cover_thickness) offset(delta = -wall_mm - cover_clearance) letter_2d();
        if (hanger == "Keyhole")
            translate([hanger_x, hanger_y, -1]) linear_extrude(height = cover_thickness + 2) {
                circle(d = 9);
                translate([-2.25, 0]) square([4.5, 9]);
                translate([0, 9]) circle(d = 4.5);
            }
    }
}

// --- Icons (unit size, centered) ----------------------------------------------------------------------------
module heart_2d() {
    for (s = [-1, 1]) hull() { translate([s * 0.23, 0.18]) circle(r = 0.27); translate([0, -0.45]) circle(r = 0.02); }
}
module star_2d() { polygon([for (i = [0 : 9]) let(a = 90 + i * 36, r = i % 2 == 0 ? 0.5 : 0.22) [r * cos(a), r * sin(a)]]); }
module cloud_2d() {
    translate([0, -0.05]) {
        translate([-0.24, -0.02]) circle(r = 0.18);
        translate([0.02, 0.08]) circle(r = 0.24);
        translate([0.27, -0.03]) circle(r = 0.17);
        hull() { translate([-0.3, -0.12]) circle(r = 0.12); translate([0.32, -0.12]) circle(r = 0.12); }
    }
}
module moon_2d() { difference() { circle(r = 0.47); translate([0.22, 0.14]) circle(r = 0.4); } }
module sun_2d() {
    circle(r = 0.26);
    for (a = [0 : 30 : 330]) rotate(a) translate([0.36, 0]) square([0.2, 0.07], center = true);
}
module balloon_2d() {
    translate([0, 0.12]) scale([0.82, 1]) circle(d = 0.76);
    polygon([[-0.07, -0.26], [0.07, -0.26], [0, -0.34]]);
    stroke([[0, -0.33], [0.05, -0.4], [-0.02, -0.46], [0.03, -0.5]], 0.035);
}
module crown_2d() { polygon([[-0.48, -0.32], [-0.46, 0.3], [-0.22, 0.04], [0, 0.42], [0.22, 0.04], [0.46, 0.3], [0.48, -0.32]]); }
module flower_2d() { for (a = [0 : 60 : 300]) rotate(a) translate([0, 0.25]) circle(d = 0.46); circle(d = 0.3); }
// One band (0 = outer, red) of a rainbow; the full rainbow is 1 wide and 0.5 tall.
module rainbow_band_2d(b) {
    bw = 0.07;
    translate([0, -0.25]) intersection() {
        difference() { circle(r = 0.5 - b * bw); circle(r = 0.5 - (b + 1) * bw); }
        translate([-1, 0]) square([2, 1]);
    }
}
module decor_icon_2d(name) {
    if (name == "Cloud") cloud_2d();
    else if (name == "Star") star_2d();
    else if (name == "Heart") heart_2d();
    else if (name == "Moon") moon_2d();
    else if (name == "Sun") sun_2d();
    else if (name == "Balloon") balloon_2d();
    else if (name == "Crown") crown_2d();
    else if (name == "Flower") flower_2d();
    else if (name == "Rainbow") for (b = [0 : 5]) rainbow_band_2d(b);
    else circle(d = 0.8);
}
function icon_box(name) = name == "Rainbow" ? [1, 0.5] : name == "Cloud" ? [1, 0.62] : [1, 1];

module foot_2d() {
    hull() { translate([0, -0.24]) circle(r = 0.15); translate([0.03, 0.1]) circle(r = 0.19); }
    for (t = [[-0.11, 0.4, 0.085], [0.03, 0.45, 0.07], [0.15, 0.41, 0.06], [0.24, 0.33, 0.05], [0.3, 0.24, 0.045]])
        translate([t[0], t[1]]) circle(r = t[2]);
}
module feet_2d() {
    translate([-0.24, 0]) mirror([1, 0]) foot_2d();
    translate([0.24, 0.06]) foot_2d();
}
module coin_2d() {
    difference() { circle(r = 0.5); circle(r = 0.42); }
    difference() { square(0.34, center = true); square(0.22, center = true); }
}
// Stylized zodiac symbols drawn as strokes.
module zodiac_symbol_2d(i, w = 0.09) {
    if (i == 0) { stroke([[0, -0.45], [0, 0.2]], w); stroke(arc([-0.2, 0.2], 0.2, 0, 210), w); stroke(arc([0.2, 0.2], 0.2, 180, -30), w); }
    else if (i == 1) { stroke(arc([0, -0.17], 0.25, 0, 360, 28), w); stroke(arc([0, 0.45], 0.4, 200, 340), w); }
    else if (i == 2) { for (x = [-0.17, 0.17]) stroke([[x, -0.38], [x, 0.38]], w); stroke([[-0.4, 0.44], [0, 0.36], [0.4, 0.44]], w); stroke([[-0.4, -0.44], [0, -0.36], [0.4, -0.44]], w); }
    else if (i == 3) for (s = [1, -1]) scale([s, s]) { stroke(arc([-0.2, 0.14], 0.12, 0, 360, 20), w); stroke([[-0.2, 0.26], [0.02, 0.32], [0.25, 0.3], [0.42, 0.2]], w); }
    else if (i == 4) { stroke(arc([-0.22, -0.18], 0.14, 0, 360, 20), w); stroke([[-0.12, -0.08], [-0.15, 0.15], [-0.02, 0.35], [0.18, 0.36], [0.28, 0.2], [0.2, 0], [0.12, -0.2], [0.18, -0.38], [0.32, -0.38], [0.4, -0.28]], w); }
    else if (i == 5 || i == 7) {
        stroke([[-0.4, 0.3], [-0.4, -0.4]], w);
        stroke([[-0.4, 0.2], [-0.3, 0.32], [-0.2, 0.2], [-0.2, -0.4]], w);
        stroke([[-0.2, 0.2], [-0.1, 0.32], [0, 0.2], [0, -0.4]], w);
        stroke([[0, 0.2], [0.1, 0.32], [0.2, 0.2], [0.2, -0.3]], w);
        if (i == 5) stroke([[0.2, -0.05], [0.38, 0.05], [0.4, -0.15], [0.25, -0.32], [0.08, -0.45]], w);
        else { stroke([[0.2, -0.3], [0.28, -0.4], [0.44, -0.4]], w); stroke([[0.35, -0.31], [0.44, -0.4], [0.35, -0.49]], w); }
    }
    else if (i == 6) { stroke([[-0.42, -0.3], [0.42, -0.3]], w); stroke(concat([[-0.42, -0.05], [-0.15, -0.05]], arc([0, 0.05], 0.18, 214, -34), [[0.15, -0.05], [0.42, -0.05]]), w); }
    else if (i == 8) { stroke([[-0.38, -0.38], [0.38, 0.38]], w); stroke([[0.1, 0.38], [0.38, 0.38], [0.38, 0.1]], w); stroke([[-0.25, 0.05], [0.05, -0.25]], w); }
    else if (i == 9) {
        stroke([[-0.42, 0.32], [-0.32, 0.36], [-0.24, 0.24], [-0.24, -0.35]], w);
        stroke([[-0.24, 0.24], [-0.12, 0.38], [0.02, 0.3], [0.06, 0], [0.08, -0.2], [0.05, -0.38], [-0.05, -0.45]], w);
        stroke(arc([0.22, -0.15], 0.13, 0, 360, 20), w);
    }
    else if (i == 10) for (dy = [0.14, -0.14]) translate([0, dy]) stroke([[-0.42, -0.07], [-0.28, 0.08], [-0.14, -0.07], [0, 0.08], [0.14, -0.07], [0.28, 0.08], [0.42, -0.07]], w);
    else { stroke(arc([-0.8, 0], 0.5, -55, 55), w); stroke(arc([0.8, 0], 0.5, 125, 235), w); stroke([[-0.34, 0], [0.34, 0]], w); }
}

// --- Badges -------------------------------------------------------------------------------------------------
// [id, show, x, y, rotation, size]
BADGES = [
    ["date", show_date, date_x, date_y, date_rot, date_size],
    ["time", show_time, time_x, time_y, time_rot, time_size],
    ["weight", show_weight, weight_x, weight_y, weight_rot, weight_size],
    ["length", show_length, length_x, length_y, length_rot, length_size],
    ["shio", show_shio, shio_x, shio_y, shio_rot, shio_size],
    ["zodiac", show_zodiac, zodiac_x, zodiac_y, zodiac_rot, zodiac_size]
];
badges = [for (b = BADGES) if (b[1]) b];

// Footprint (width, height) of a badge of size s.
function badge_box(id, s) =
    id == "date" ? [s, 0.9 * s] : id == "time" ? [s, s] : id == "weight" ? [s, 0.84 * s]
  : id == "length" ? [s, 0.3 * s] : [s, 0.42 * s];

module badge_plate_2d(id, s) {
    if (id == "date") {
        translate([0, -0.05 * s]) rounded_rect(s, 0.8 * s, 0.08 * s);
        for (x = [-0.28, 0, 0.28]) translate([x * s, 0.36 * s]) rounded_rect(0.12 * s, 0.18 * s, 0.05 * s);
    } else if (id == "time") {
        translate([0, -0.04 * s]) circle(d = 0.8 * s);
        for (sx = [-1, 1]) {
            translate([sx * 0.3 * s, 0.3 * s]) circle(d = 0.3 * s);
            hull() { translate([sx * 0.2 * s, -0.3 * s]) circle(d = 0.1 * s); translate([sx * 0.32 * s, -0.46 * s]) circle(d = 0.08 * s); }
        }
        translate([0, 0.44 * s]) circle(d = 0.1 * s);
    } else if (id == "weight") rounded_rect(s, 0.84 * s, 0.14 * s);
    else if (id == "length") rounded_rect(s, 0.3 * s, 0.03 * s);
    else rounded_rect(s, 0.42 * s, 0.21 * s);
}

module badge_detail_2d(id, s) {
    f = font_name;
    if (id == "date") {
        translate([0, 0.2 * s]) square([0.84 * s, 0.035 * s], center = true);
        for (x = [-0.28, 0, 0.28]) translate([x * s, 0.36 * s]) circle(d = 0.06 * s);
        translate([0, -0.1 * s]) text_lines(date_lines, f, 0.82 * s, 0.5 * s);
    } else if (id == "time") {
        translate([0, -0.04 * s]) difference() { circle(d = 0.7 * s); circle(d = 0.64 * s); }
        translate([0, -0.04 * s]) text_lines([birth_time], f, 0.5 * s, 0.3 * s);
    } else if (id == "weight") {
        translate([0, 0.15 * s]) unit_scale(0.42 * s) feet_2d();
        translate([0, -0.24 * s]) text_lines([weight_text], f, 0.84 * s, 0.26 * s);
    } else if (id == "length") {
        n = 20;
        for (i = [1 : n - 1]) translate([-0.5 * s + i * s / n, -0.15 * s]) square([0.012 * s + 0.15, (i % 5 == 0 ? 0.11 : 0.06) * s], center = false);
        translate([0, 0.03 * s]) text_lines([length_text], f, 0.7 * s, 0.17 * s);
    } else {
        picture = id == "shio" ? icon_right_file : icon_left_file;
        translate([-0.29 * s, 0]) {
            if (picture != "") fit_longest(0.32 * s) import(file = picture, center = true);
            else if (id == "shio") unit_scale(0.32 * s) coin_2d();
            else unit_scale(0.32 * s) zodiac_symbol_2d(zodiac_index);
        }
        translate([0.13 * s, 0]) text_lines([id == "shio" ? shio_label : zodiac_label], f, 0.56 * s, 0.24 * s);
    }
}

// --- Decoration tree ----------------------------------------------------------------------------------------
// Element: [type, text, font, icon, svgPath, x, y, size, thickness, bold, placement, inset, children, color, rotation].
// Children sit in the parent's frame (position and rotation) on top of the parent.
function flat_tree(nodes, origin, prot, ptop, pth, path) =
    len(nodes) == 0 ? [] :
    [for (i = [0 : 1 : len(nodes) - 1])
        let(n = nodes[i],
            r = is_undef(n[14]) ? 0 : n[14],
            pos = origin + rot2([n[5], n[6]], prot),
            z = ptop + pth - (n[10] == "Inset" ? min(n[11], pth) : 0),
            p = path == "" ? str(i) : str(path, ".", i))
        each concat([[n, pos, prot + r, z, p]], flat_tree(n[12], pos, prot + r, z, n[8], p))];

module element_2d(n, band = -1) {
    module shape() {
        if (n[0] == "Text") text(n[1], size = n[7], font = n[2], halign = "center", valign = "center");
        else if (n[0] == "Icon" && band >= 0) unit_scale(n[7]) rainbow_band_2d(band);
        else if (n[0] == "Icon") unit_scale(n[7]) decor_icon_2d(n[3]);
        else if (n[0] == "SVG" && n[4] != "") fit_longest(n[7]) import(file = n[4], center = true);
    }
    if (n[9] > 0) offset(r = n[9]) shape(); else shape();
}

// Footprint [center, size] of an element in its own frame.
function element_box(n) =
    n[0] == "Text" ? let(m = textmetrics(text = n[1], size = n[7], font = n[2], halign = "center", valign = "center"))
                     [m.position + m.size / 2, m.size + [2, 2] * n[9]]
  : n[0] == "Icon" ? [[0, 0], icon_box(n[3]) * n[7] + [2, 2] * n[9]]
  : [[0, 0], [n[7], n[7]]];

// --- Layout -------------------------------------------------------------------------------------------------
print = layout == "Print plates";
shift = [move_x, move_y];
// Decorations sit on the face when assembled, on plate 3 when laid out for printing.
decor_shift = shift + (print ? [2 * PLATE_PITCH, 0] : [0, 0]);
decor_z = print ? 0 : depth_mm;
flat = flat_tree(decorative_layers, [0, 0], 0, decor_z, 0, "");

want_body = export_part == "All" || export_part == "Letter body";
want_cover = show_cover && (export_part == "All" || export_part == "Bottom cover");
want_decor = export_part == "All" || export_part == "Decorations";
has_name = len(name_text) > 0;

// One entry per color part: [kind, color, index, band].
PARTS = concat(
    want_body ? [["body", letter_color, 0, -1]] : [],
    want_cover ? [["cover", cover_color, 0, -1]] : [],
    want_decor && has_name ? [["name", name_color, 0, -1]] : [],
    want_decor && len(badges) > 0 ? [["badge", badge_color, 0, -1], ["detail", badge_text_color, 0, -1]] : [],
    want_decor ? [for (i = [0 : 1 : len(flat) - 1]) each
        (flat[i][0][0] == "Icon" && flat[i][0][3] == "Rainbow")
            ? [for (b = [0 : 5]) ["element", RAINBOW[b], i, b]]
            : [["element", flat[i][0][13], i, -1]]] : []
);

module place(xy, a) { translate([xy[0], xy[1]]) rotate(a) children(); }

module part_geometry(p) {
    if (p[0] == "body") {
        if (print) translate([shift[0], shift[1], depth_mm]) rotate([180, 0, 0]) letter_body();
        else translate(shift) letter_body();
    } else if (p[0] == "cover") {
        translate(shift + (print ? [PLATE_PITCH, 0] : [0, 0])) letter_cover();
    } else if (p[0] == "name") {
        translate([0, 0, decor_z]) place(decor_shift + [name_x, name_y], name_rot)
            linear_extrude(height = name_thickness) offset(r = name_bold)
                text(name_text, size = name_size, font = name_font, halign = "center", valign = "center");
    } else if (p[0] == "badge") {
        for (b = badges) translate([0, 0, decor_z]) place(decor_shift + [b[2], b[3]], b[4])
            linear_extrude(height = badge_thickness) badge_plate_2d(b[0], b[5]);
    } else if (p[0] == "detail") {
        for (b = badges) translate([0, 0, decor_z + badge_thickness - EPS]) place(decor_shift + [b[2], b[3]], b[4])
            linear_extrude(height = badge_relief + EPS) intersection() {
                badge_plate_2d(b[0], b[5]);
                badge_detail_2d(b[0], b[5]);
            }
    } else if (p[0] == "element") {
        e = flat[p[2]];
        translate([0, 0, e[3]]) place(decor_shift + e[1], e[2]) linear_extrude(height = e[0][8]) element_2d(e[0], p[3]);
    }
}

// Each iteration is one top-level object, so every color becomes its own 3MF part.
for (p = PARTS) color(p[1]) part_geometry(p);

// Movable items for the FormForge viewport: id, center x/y, top z, width, depth, rotation.
if (want_decor) {
    if (has_name) let(m = textmetrics(text = name_text, size = name_size, font = name_font, halign = "center", valign = "center"),
                      c = decor_shift + [name_x, name_y] + rot2(m.position + m.size / 2, name_rot))
        echo("formforge-item", "name", c[0], c[1], decor_z + name_thickness, m.size[0] + 2 * name_bold, m.size[1] + 2 * name_bold, name_rot);
    for (b = badges) let(c = decor_shift + [b[2], b[3]], box = badge_box(b[0], b[5]))
        echo("formforge-item", b[0], c[0], c[1], decor_z + badge_thickness + badge_relief, box[0], box[1], b[4]);
    for (e = flat) let(box = element_box(e[0]), c = decor_shift + e[1] + rot2(box[0], e[2]))
        echo("formforge-item", str("decorative_layers:", e[4]), c[0], c[1], e[3] + e[0][8], box[1][0], box[1][1], e[2]);
}
