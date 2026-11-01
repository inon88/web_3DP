// Pet bowl stand: a tilted, tapered stand that holds a stainless steel bowl,
// sitting on the post of a separate base tray with a spill moat, with the
// pet's name and two icons on the front wall.
// Rebuilt from the 14 cm design (UKURAN_14.step: stand, 14_BAWAH.stp: tray)
// and scaled by bowl size (diameter of the bowl body just below its flange x depth):
//   S 14 x 4.9 cm, M 16 x 5.3 cm, L 18 x 6.1 cm, XL 20 x 6.4 cm.
// All dimensions are in millimetres. Front = -Y (the low side of the tilt);
// the hand slot is at the back. Both parts print upright without supports.
// 3MF export: stand, decoration and base tray are separate objects, so a
// multi-material slicer can give each part its own filament.
// @formforge-3mf-objects

/* [Bowl size] */
// Steel bowl the stand is made for (body diameter below the flange x depth)
bowl_size = "S"; // ["S":"S - 14 x 4.9 cm","M":"M - 16 x 5.3 cm","L":"L - 18 x 6.1 cm","XL":"XL - 20 x 6.4 cm","Custom":"Custom"]
// Custom only: diameter of the bowl body just below its flange
custom_bowl_diameter_mm = 140; // [80:1:320]
// Custom only: depth of the steel bowl
custom_bowl_depth_mm = 49; // [20:1:150]
// Width of the bowl's flat flange (it rests on the ledge)
bowl_flange_mm = 12; // [4:0.5:25]
// Gap between the bowl body and the opening
hole_clearance_mm = 6.3; // [1:0.1:15]
// Depth of the recess the flange sits in
flange_recess_mm = 3; // [0:0.5:6]

/* [Stand] */
// Height of the flange ledge at the centre; 0 = auto (88.4 mm for 14 cm, scaled with the bowl)
stand_height_mm = 0; // [0:1:250]
// Top leans toward the pet (front side lower)
tilt_deg = 6.25; // [0:0.25:15]
// Rounding of the top outer edge
top_edge_round_mm = 2; // [0:0.25:4]
// Wall lean; the stand is wider at the bottom
taper_deg = 8.8; // [0:0.1:20]
// Width of the top surface outside the flange recess
top_border_mm = 4.1; // [1.5:0.1:15]
// Rounding of the bottom outer edge
foot_round_mm = 7.5; // [0:0.5:15]
// Rounding where the foot meets the inner wall
inner_round_mm = 20; // [0:1:40]
// Gap between the socket and the tray's post
socket_clearance_mm = 0.5; // [0.1:0.05:1.5]
// Slot at the back for lifting the stand
hand_slot = true;
hand_slot_width_mm = 80; // [30:1:180]
hand_slot_height_mm = 24.8; // [10:0.2:50]

/* [Base tray] */
show_base = true;
// Height of the post shoulder the stand rests on; 0 = auto (65 mm for 14 cm, scaled)
post_height_mm = 0; // [0:1:200]
// Height of the tray rim; 0 = auto (40 mm for 14 cm, scaled)
rim_height_mm = 0; // [0:1:150]
rim_width_mm = 8; // [3:0.5:30]
base_floor_mm = 10; // [2:0.5:20]
// Locating ring that goes into the stand's socket
spigot_height_mm = 10; // [3:0.5:20]
post_wall_mm = 8.7; // [3:0.1:20]
// Rounding of the outer bottom edge and of the moat
tray_round_mm = 15; // [0:0.5:25]
// Arched opening in the post so water inside it drains to the moat
drain_window = true;

/* [Name] */
name_text = "Mochi";
font_name = "Liberation Sans:style=Bold";
// 0 = auto (scaled with the bowl)
name_size_mm = 0; // [0:0.5:60]
letter_spacing_mm = 0.5; // [-2:0.1:6]
// Height on the front wall: 0 = above the foot rounding, 100 = top
name_height_percent = 50; // [10:1:90]
// Turns the name and icons around the stand; 0 = front
decor_turn_deg = 0; // [-180:1:180]

/* [Left icon] */
// Built-in icon; a chosen image below replaces it (None hides the icon)
left_icon = "Dog"; // ["None","Paw","Bone","Fish","Heart","Crown","Star","Dog","Cat","Custom image"]
// Choose image: replaces the built-in icon. SVG is used as-is; PNG/JPG/WebP become a silhouette
icon_left_file = "";
// Size relative to the capital letter height of the name
left_icon_size_percent = 130; // [30:5:300]
// Moves the icon up (+) or down (-)
left_icon_raise_mm = 0; // [-40:0.5:40]

/* [Right icon] */
// Built-in icon; a chosen image below replaces it (None hides the icon)
right_icon = "Paw"; // ["None","Paw","Bone","Fish","Heart","Crown","Star","Dog","Cat","Custom image"]
// Choose image: replaces the built-in icon. SVG is used as-is; PNG/JPG/WebP become a silhouette
icon_right_file = "";
right_icon_size_percent = 110; // [30:5:300]
right_icon_raise_mm = 0; // [-40:0.5:40]

/* [Decoration] */
// Flush inlay: name and icons sit level with the wall in their own color
decor_style = "Raised"; // ["Raised","Engraved","Flush inlay"]
// Raised height, or depth for Engraved and Flush inlay
decor_depth_mm = 1; // [0.4:0.1:3]
// Gap between the name and each icon
icon_gap_mm = 4; // [0:0.5:30]
// Thickens (+) or thins (-) the name and icons
decor_bold_mm = 0; // [-0.5:0.05:1.5]

/* [Layout] */
// Print plate puts the stand and the tray side by side
layout = "Assembled"; // ["Assembled","Print plate"]
// Render one part only (for single-color STL). Engraved has no separate decoration, so Decoration then shows the engraved stand
export_part = "All"; // ["All","Stand","Decoration","Base tray"]
// Silver stand-in for the steel bowl; preview only, turn it off before export
show_steel_bowl = false;

/* [Colors] */
stand_color = "White"; // ["White","Ivory","PeachPuff","BurlyWood","Chocolate","SaddleBrown","DarkOliveGreen","OliveDrab","Teal","DarkCyan","SteelBlue","LightPink","HotPink","Gray","Black"]
decor_color = "Teal"; // ["White","Ivory","PeachPuff","BurlyWood","Chocolate","SaddleBrown","DarkOliveGreen","OliveDrab","Teal","DarkCyan","SteelBlue","LightPink","HotPink","Gray","Black"]
base_color = "Teal"; // ["White","Ivory","PeachPuff","BurlyWood","Chocolate","SaddleBrown","DarkOliveGreen","OliveDrab","Teal","DarkCyan","SteelBlue","LightPink","HotPink","Gray","Black"]

// Preview resolution (export always overrides it). $fa decides the segment
// count of every large round part, so the stand and the cones used to clip
// the decoration share the same facets and inlays stay exactly flush.
$fa = 4;
$fs = 1;

// ---------------------------------------------------------------- derived ---

// Written as expressions so they stay out of the parameter form.
SIZES = [["S", 140, 49], ["M", 160, 53], ["L", 180, 61], ["XL", 200, 64]];
REF_D = 14 * 10;       // the 14 cm design all auto heights are scaled from
BIG = 2 * 1000;
PHANTOM = 100 * 1000;  // offset of the helper copy used to fit custom images

size_row = [for (s = SIZES) if (s[0] == bowl_size) s];
bowl_d = len(size_row) > 0 ? size_row[0][1] : custom_bowl_diameter_mm;
bowl_depth = len(size_row) > 0 ? size_row[0][2] : custom_bowl_depth_mm;
grow = bowl_d / REF_D;

// Stand. z = 0 at its foot; the ledge plane passes through the axis at ledge_h.
recess_r = bowl_d / 2 + bowl_flange_mm + 0.2;
hole_r = min(bowl_d / 2 + hole_clearance_mm, recess_r - 2);
// The hanging bowl must stay clear of the socket floor.
ledge_h = max(stand_height_mm > 0 ? stand_height_mm : 88.4 * grow, bowl_depth + 25);
k = tan(taper_deg);
top_outer_r = recess_r + top_border_mm;             // outer wall at ledge height
foot_r = top_outer_r + ledge_h * k;                  // outer wall at z = 0
function outer_r(z) = foot_r - z * k;
function inner_r(z) = hole_r + (ledge_h - z) * k;    // inner wall, parallel to the outer one
socket_r = bowl_d / 2;
socket_h = spigot_height_mm;
foot_round = min(foot_round_mm, socket_h + 2);
front_top = ledge_h + flange_recess_mm - top_outer_r * tan(tilt_deg);
slot_z = 0.646 * ledge_h;

// The tilted top cuts the cone in an ellipse that sits off the axis (toward
// the front). Measured in the ledge frame: q = half-width across, edge_r =
// half-length front to back, edge_y = centre. The flange recess and the edge
// rounding follow it so the top border is equally wide all around.
tt = tan(tilt_deg);
top_rc = flange_recess_mm / cos(tilt_deg);
q = foot_r - k * (ledge_h + top_rc);
edge_yf = -q / (1 - k * tt) * cos(tilt_deg) + (top_rc - q / (1 - k * tt) * tt) * sin(tilt_deg);
edge_yb = q / (1 + k * tt) * cos(tilt_deg) + (top_rc + q / (1 + k * tt) * tt) * sin(tilt_deg);
edge_y = (edge_yf + edge_yb) / 2;
edge_r = (edge_yb - edge_yf) / 2;

// Tray. z = 0 at its bottom; the stand rests on the post shoulder.
post_h = post_height_mm > 0 ? post_height_mm : 65 * grow;
rim_h = min(rim_height_mm > 0 ? rim_height_mm : 40 * grow, post_h);
spigot_r = socket_r - socket_clearance_mm;
post_in = spigot_r - 5;
post_out = post_in + post_wall_mm;
rim_out = foot_r - 0.5;
rim_in = rim_out - rim_width_mm;
moat_round = max(0, min(tray_round_mm, rim_in - post_out - 1, rim_h - base_floor_mm - 1));
bottom_round = min(tray_round_mm, rim_h - 1, rim_out - post_out);
// Single parts sit on the plate; the assembly puts the stand on the post.
stand_z = show_base && layout == "Assembled" && export_part == "All" ? post_h : 0;

// Name layout along the wall (u = arc length, 0 = front centre).
name_size = name_size_mm > 0 ? name_size_mm : 0.3 * bowl_d / 2;
chars = [for (c = name_text) c];
n = len(chars);
function tm(s) = textmetrics(s, size = name_size, font = font_name);
function cumulative(values, index = 0, total = 0) =
    index >= len(values) ? [] : concat([total], cumulative(values, index + 1, total + values[index]));
advances = [for (c = chars) tm(c).advance.x + letter_spacing_mm];
letter_u = cumulative(advances);
name_w = n > 0 ? letter_u[n - 1] + advances[n - 1] - letter_spacing_mm : 0;
cap = tm("H").size.y;

// A chosen image always wins over the built-in icon; "Custom image" without a file shows nothing.
left_kind = left_icon == "None" ? "None" : icon_left_file != "" ? "Custom image" : left_icon;
right_kind = right_icon == "None" ? "None" : icon_right_file != "" ? "Custom image" : right_icon;
has_left = left_kind != "None" && (left_kind != "Custom image" || icon_left_file != "");
has_right = right_kind != "None" && (right_kind != "Custom image" || icon_right_file != "");
left_s = cap * left_icon_size_percent / 100;
right_s = cap * right_icon_size_percent / 100;
left_u = -(n > 0 ? name_w / 2 + icon_gap_mm : (has_right ? icon_gap_mm / 2 : -left_s / 2)) - left_s / 2;
right_u = (n > 0 ? name_w / 2 + icon_gap_mm : (has_left ? icon_gap_mm / 2 : -right_s / 2)) + right_s / 2;
has_decor = len([for (c = chars) if (c != " ") c]) > 0 || has_left || has_right;

// Part selection never leaves the model empty: without a separate decoration
// part (Engraved, or no name and icons) Decoration shows the stand instead,
// and Base tray is drawn even when the tray is hidden from the assembly.
decor_part_exists = has_decor && decor_style != "Engraved";
want_stand = export_part == "All" || export_part == "Stand" || (export_part == "Decoration" && !decor_part_exists);
want_decor = (export_part == "All" || export_part == "Decoration") && decor_part_exists;
want_base = (export_part == "All" && show_base) || export_part == "Base tray";

name_z = foot_round + (front_top - 3 - foot_round) * name_height_percent / 100;
cut_depth = min(decor_depth_mm, 3);
// Flat decoration is extruded through the curved wall, then clipped to it.
PRISM = decor_depth_mm + 4;

// ------------------------------------------------------------ 2D helpers ---

function arc(c, r, a0, a1, steps = 32) =
    [for (i = [0 : steps]) let(a = a0 + (a1 - a0) * i / steps) [c[0] + r * cos(a), c[1] + r * sin(a)]];

module round_convex(r) { if (r > 0) offset(r = r) offset(delta = -r) children(); else children(); }

// Built-in pet icons, drawn about 100 units wide so curves keep enough segments.
module pet_icon(name) {
    scale([100, 100])
        if (name == "Paw") union() {
            translate([0, -0.2]) scale([1, 0.82]) circle(d = 0.56, $fn = 72);
            for (p = [[-0.36, 0.1, 25], [-0.13, 0.32, 8], [0.13, 0.32, -8], [0.36, 0.1, -25]])
                translate([p[0], p[1]]) rotate(p[2]) scale([0.8, 1]) circle(d = 0.26, $fn = 48);
        }
        else if (name == "Bone") rotate(35) union() {
            square([0.7, 0.16], center = true);
            for (x = [-0.38, 0.38], y = [-0.09, 0.09]) translate([x, y]) circle(d = 0.22, $fn = 48);
        }
        else if (name == "Fish") difference() {
            union() {
                translate([-0.08, 0]) scale([1, 0.6]) circle(d = 0.72, $fn = 72);
                translate([0.2, 0]) polygon([[0, 0], [0.3, 0.24], [0.3, -0.24]]);
            }
            translate([-0.27, 0.06]) circle(d = 0.08, $fn = 24);
        }
        else if (name == "Heart")
            scale(0.58) translate([0, -0.78]) rotate(45) union() {
                square(1);
                translate([0.5, 1]) circle(d = 1, $fn = 96);
                translate([1, 0.5]) circle(d = 1, $fn = 96);
            }
        else if (name == "Crown") union() {
            polygon([[-0.48, -0.32], [-0.42, 0.24], [-0.17, 0.02], [0, 0.36], [0.17, 0.02], [0.42, 0.24], [0.48, -0.32]]);
            for (p = [[-0.42, 0.27], [0, 0.4], [0.42, 0.27]]) translate(p) circle(d = 0.12, $fn = 32);
        }
        else if (name == "Star")
            polygon([for (i = [0 : 9]) let(a = 90 + i * 36, r = (i % 2 == 0) ? 0.5 : 0.23) [r * cos(a), r * sin(a)]]);
        else if (name == "Dog") difference() {
            union() {
                circle(d = 0.7, $fn = 72);
                for (m = [0, 1]) mirror([m, 0]) translate([0.34, 0.04]) rotate(18) scale([0.55, 1]) circle(d = 0.5, $fn = 48);
            }
            for (m = [0, 1]) mirror([m, 0]) translate([0.13, 0.08]) circle(d = 0.1, $fn = 24);
            translate([0, -0.12]) scale([1.3, 1]) circle(d = 0.11, $fn = 24);
        }
        else if (name == "Cat") difference() {
            union() {
                translate([0, -0.05]) scale([1, 0.85]) circle(d = 0.8, $fn = 72);
                for (m = [0, 1]) mirror([m, 0]) polygon([[0.1, 0.24], [0.38, 0.45], [0.37, 0.04]]);
            }
            for (m = [0, 1]) mirror([m, 0]) translate([0.15, -0.02]) scale([0.7, 1]) circle(d = 0.12, $fn = 24);
            polygon([[-0.05, -0.14], [0.05, -0.14], [0, -0.2]]);
        }
}

// Longest side of centred artwork = size: resized together with a far-away
// copy turned 90 degrees, which is then cut away (resize() scales about the origin).
module fit_longest(size) {
    intersection() {
        square(2 * size, center = true);
        resize([0, size], auto = true) {
            children();
            translate([PHANTOM, 0]) rotate(90) children();
        }
    }
}

module icon_2d(kind, file, size) {
    if (kind == "Custom image") { if (file != "") fit_longest(size) import(file = file, center = true); }
    else if (kind != "None") scale(size / 100) pet_icon(kind);
}

module bold_if() { if (decor_bold_mm != 0) offset(r = decor_bold_mm) children(); else children(); }

// ------------------------------------------------------------------ stand ---

// Section of the stand before the tilted top cut: thick conical wall, foot
// with a socket for the tray's spigot, rounded inner corner (mirrored about
// the axis so only the intended corners get rounded).
module stand_profile() {
    top = ledge_h + 2 * top_outer_r * tan(tilt_deg) + 20;
    intersection() {
        square([BIG, BIG]);
        difference() {
            round_convex(foot_round)
                polygon([[-foot_r, 0], [foot_r, 0], [outer_r(top), top], [-outer_r(top), top]]);
            round_convex(inner_round_mm)
                polygon([[-inner_r(socket_h), socket_h], [inner_r(socket_h), socket_h],
                         [inner_r(top + 50), top + 50], [-inner_r(top + 50), top + 50]]);
            translate([-socket_r, -1]) square([2 * socket_r, socket_h + 1.01]);
        }
    }
}

// Frame of the tilted ledge plane (origin on the axis, z up from the ledge).
module ledge_frame() { translate([0, 0, ledge_h]) rotate([tilt_deg, 0, 0]) children(); }

// Ring that rounds the top outer edge: the corner wedge outside a fillet of
// radius rr between the top face and the wall (wall lean taken as the taper).
module top_edge_cutter() {
    rr = top_edge_round_mm;
    th = taper_deg;
    c = [edge_r - rr * (1 - sin(th)) / cos(th), flange_recess_mm - rr];
    translate([0, edge_y, 0]) scale([q / edge_r, 1, 1]) rotate_extrude(convexity = 4)
        polygon(concat([[edge_r + 1, flange_recess_mm + 1]], arc(c, rr, 90, th, 16)));
}

module stand_body() {
    difference() {
        rotate_extrude(convexity = 6) stand_profile();
        ledge_frame() {
            translate([-BIG / 2, -BIG / 2, flange_recess_mm]) cube(BIG);
            translate([0, edge_y, 0]) cylinder(r = recess_r, h = BIG);
            if (top_edge_round_mm > 0) top_edge_cutter();
        }
        if (hand_slot)
            translate([0, 0, slot_z]) rotate([-90, 0, 0]) linear_extrude(BIG)
                hull() for (x = [-1, 1]) translate([x * (hand_slot_width_mm - hand_slot_height_mm) / 2, 0])
                    circle(d = hand_slot_height_mm);
    }
}

// Solid cone matching the outer wall, pushed out by g (perpendicular) and
// extended past both ends; same $fa as the stand, so facets line up.
module wall_cone(g) {
    h = g / cos(taper_deg);
    rotate_extrude(convexity = 4)
        polygon([[0, -5], [outer_r(-5) + h, -5], [outer_r(front_top + 5) + h, front_top + 5], [0, front_top + 5]]);
}

module wall_shell(inner, outer) { difference() { wall_cone(outer); wall_cone(inner); } }

// Stands flat 2D artwork on the wall at arc position u and height z.
module on_wall(u, z) {
    r = outer_r(z);
    a = u / r * 180 / PI + decor_turn_deg;
    translate([r * sin(a), -r * cos(a), z]) rotate([0, 0, a]) rotate([-taper_deg, 0, 0]) rotate([90, 0, 0])
        translate([0, 0, -PRISM]) linear_extrude(2 * PRISM, convexity = 8) bold_if() children();
}

module decor_prisms() {
    for (i = [0 : max(0, n - 1)]) if (n > 0 && chars[i] != " ") {
        adv = tm(chars[i]).advance.x;
        on_wall(-name_w / 2 + letter_u[i] + adv / 2, name_z)
            translate([-adv / 2, -cap / 2]) text(chars[i], size = name_size, font = font_name);
    }
    if (has_left) on_wall(left_u, name_z + left_icon_raise_mm) icon_2d(left_kind, icon_left_file, left_s);
    if (has_right) on_wall(right_u, name_z + right_icon_raise_mm) icon_2d(right_kind, icon_right_file, right_s);
}

module stand() {
    color(stand_color) difference() {
        stand_body();
        if (has_decor && decor_style != "Raised")
            intersection() { decor_prisms(); wall_shell(-cut_depth, 1); }
    }
}

module decoration() {
    if (has_decor && decor_style == "Raised")
        color(decor_color) intersection() { decor_prisms(); wall_shell(0, decor_depth_mm); }
    else if (has_decor && decor_style == "Flush inlay")
        color(decor_color) intersection() { decor_prisms(); wall_shell(-cut_depth, 0); }
}

// Stand-in for the steel bowl, flange resting on the ledge.
module steel_bowl() {
    rt = bowl_d / 2;
    rb = rt * 0.62;
    fr = recess_r - 0.5;
    t = 0.8;
    color("Silver") ledge_frame() translate([0, edge_y, 1]) rotate_extrude(convexity = 4)
        polygon([[0, -bowl_depth], [rb, -bowl_depth], [rt, -1], [fr, -1], [fr, 0],
                 [rt - t, 0], [rb - t, -bowl_depth + t], [0, -bowl_depth + t]]);
}

// ------------------------------------------------------------------- tray ---

// Floor, outer rim, rounded moat, hollow post with shoulder and spigot.
module tray_profile() {
    top = post_h + spigot_height_mm;
    polygon(concat(
        [[0, 0]],
        bottom_round > 0 ? arc([rim_out - bottom_round, bottom_round], bottom_round, -90, 0) : [[rim_out, 0]],
        [[rim_out, rim_h], [rim_in, rim_h]],
        moat_round > 0
            ? arc([rim_in - moat_round, base_floor_mm + moat_round], moat_round, 0, -90)
            : [[rim_in, base_floor_mm]],
        [[post_out, base_floor_mm], [post_out, post_h], [spigot_r, post_h], [spigot_r, top],
         [post_in, top], [post_in, base_floor_mm], [0, base_floor_mm]]
    ));
}

module base_tray() {
    color(base_color) difference() {
        rotate_extrude(convexity = 6) tray_profile();
        // Arched opening on the right side, from the floor up.
        if (drain_window)
            translate([post_in - 2, 0, base_floor_mm]) rotate([90, 0, 90]) linear_extrude(post_wall_mm + 4)
                union() {
                    translate([-15.8, -1]) square([31.6, 26]);
                    translate([0, 25]) circle(r = 15.8);
                }
    }
}

// ----------------------------------------------------------------- model ---

module place_stand() {
    if (layout == "Assembled") translate([0, 0, stand_z]) children();
    else translate([-(foot_r + 5), 0, 0]) children();
}

module place_base() {
    if (layout == "Assembled") children();
    else translate([rim_out + 5, 0, 0]) children();
}

// One top-level iteration per color part: with the 3MF objects marker above,
// FormForge exports each part as its own object (STL still gets one mesh).
for (part = [0 : 3])
    if (part == 0 && want_stand) place_stand() stand();
    else if (part == 1 && want_decor) place_stand() decoration();
    else if (part == 2 && want_base) place_base() base_tray();
    else if (part == 3 && show_steel_bowl && layout == "Assembled" && export_part == "All") place_stand() steel_bowl();
