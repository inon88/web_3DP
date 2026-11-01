// SVG / image / icon to 3D: turns a built-in icon, an SVG, or a PNG/JPG/WebP
// (traced into color layers or a silhouette by FormForge) into a printable
// product (flat icon, badge, keychain, fridge magnet, wall sign, stencil,
// stamp, or cookie cutter).
// All dimensions are in millimetres. Each colored part is a separate solid so
// it can be assigned its own filament in a multi-material slicer (3MF).
// OpenSCAD has no bounding-box function, so plate shapes and hole positions
// are built geometrically from the artwork (bands, hulls and minkowski).
// 3MF export: every color part (plate, each artwork color, detail) is its own
// object, so a multi-material slicer can give each part its own filament.
// @formforge-3mf-objects

/* [Source image] */
// Icon: built-in shape. SVG: one shape from the file. Image: traced color layers (or a silhouette).
source_type = "Image"; // ["Icon","SVG","Image"]
// Choose image: SVG is used as-is; PNG/JPG/WebP open a dialog to trace color layers or make a silhouette. Empty uses the built-in icon.
icon_left_file = "";
// Filled automatically when an image is traced into color layers
icon_left_colors = "";
// Used for Icon, and when no file is chosen
fallback_icon = "Heart"; // ["Heart","Star","Flower","Diamond","Lightning","Crown","Balloon","Plus"]
// Use the background instead of the shape (not available with color layers)
invert_image = false;
invert_frame_mm = 3; // [0.5:0.5:20]
// Fill every hole inside the shape
fill_holes = false;
// Rounds corners and removes pixel steps (PNG/JPG: about 0.3-0.8)
smoothing_mm = 0.3; // [0:0.05:3]
// Removes details thinner than this (match your nozzle, e.g. 0.4)
min_feature_mm = 0; // [0:0.05:2]
// Positive thickens, negative thins the artwork
bold_mm = 0; // [-1.5:0.05:3]

/* [Size & orientation] */
size_mode = "Longest side"; // ["Longest side","Width","Height"]
// Artwork size before rotation, without the plate margin
target_size_mm = 50; // [10:1:250]
// Turns the artwork inside the product (the ring and plate follow); rotate the whole object in the viewport
artwork_rotation_deg = 0; // [-180:1:180]
mirror_image = false;

/* [Product] */
product_mode = "Badge"; // ["Flat icon","Badge","Keychain","Fridge magnet","Wall sign","Stencil","Stamp","Cookie cutter"]
// How the artwork sits on the plate (Badge, Keychain, Fridge magnet, Wall sign)
icon_style = "Raised"; // ["Raised","Engraved","Flush inlay","Cut-through"]
// Raised height; total height in Flat icon mode; relief height in Stamp mode
icon_height_mm = 1.6; // [0.4:0.2:20]
// Pocket depth for Engraved and Flush inlay
engrave_depth_mm = 1; // [0.2:0.2:10]

/* [Base plate] */
// Plate shape for every mode except Flat icon and Cookie cutter
base_shape = "Outline"; // ["Outline","Rounded rectangle","Circle","Hexagon"]
// Distance from the artwork to the plate edge
base_margin_mm = 3; // [0:0.5:30]
// Outline only: bridges gaps between separate parts of the artwork
outline_closing_mm = 2; // [0:0.5:15]
base_thickness_mm = 3; // [0.8:0.2:20]
// Rounded rectangle and Hexagon only
corner_radius_mm = 4; // [0:0.5:30]
// Top edge of the plate (of the icon in Flat icon mode)
edge_style = "Chamfer"; // ["None","Chamfer","Round"]
edge_size_mm = 0.6; // [0.2:0.1:3]

/* [Detail layer (second color)] */
// Optional second image printed on top in its own color
icon_right_file = "";
detail_size_mm = 20; // [2:1:250]
detail_offset_x_mm = 0; // [-125:0.5:125]
detail_offset_y_mm = 0; // [-125:0.5:125]
detail_rotation_deg = 0; // [-180:1:180]
detail_height_mm = 0.6; // [0.2:0.2:5]
// Trim the detail so it never overhangs the surface below
clip_detail = true;

/* [Keychain] */
ring_position = "Top"; // ["Top","Left","Right"]
ring_hole_mm = 4.5; // [2:0.1:10]
ring_wall_mm = 2.5; // [1.2:0.1:6]

/* [Fridge magnet] */
magnet_diameter_mm = 10; // [3:0.5:30]
magnet_thickness_mm = 2; // [0.5:0.1:10]
magnet_count = 1; // [1:1:2]
// Centre distance when using two magnets
magnet_spacing_mm = 20; // [5:1:150]
// Extra room around the magnet for a press fit
magnet_clearance_mm = 0.2; // [0:0.05:1]

/* [Wall sign] */
// Keyhole is cut into the back and needs a plate of at least 4 mm
mount_style = "Two screw holes"; // ["Two screw holes","Keyhole","None"]
screw_diameter_mm = 4; // [2:0.5:8]
screw_head_mm = 8; // [4:0.5:16]
// Distance from the plate edge to the screw
mount_inset_mm = 7; // [3:0.5:40]

/* [Stencil] */
stencil_thickness_mm = 1.2; // [0.4:0.1:5]
// Bars that hold islands (like the centre of an O) in place
stencil_bridges = "Vertical"; // ["None","Vertical","Horizontal","Grid"]
bridge_width_mm = 1.2; // [0.4:0.1:5]
bridge_spacing_mm = 12; // [3:0.5:60]

/* [Stamp] */
// The artwork is mirrored automatically so the print reads correctly
stamp_handle = "Peg hole and knob"; // ["None","Peg hole","Peg hole and knob"]
peg_diameter_mm = 10; // [4:0.5:30]
peg_depth_mm = 6; // [2:0.5:20]
knob_diameter_mm = 25; // [12:1:60]
knob_height_mm = 25; // [10:1:80]

/* [Cookie cutter] */
cutter_height_mm = 14; // [6:0.5:40]
blade_thickness_mm = 1.2; // [0.6:0.1:3]
// Thickness at the cutting edge
blade_tip_mm = 0.6; // [0.4:0.1:2]
flange_width_mm = 4; // [0:0.5:15]
flange_height_mm = 1.6; // [0.6:0.2:5]
// Adds imprint walls along the holes inside the artwork, held by bars
cutter_inner_details = false;
inner_detail_height_mm = 8; // [2:0.5:30]
inner_wall_mm = 1; // [0.6:0.1:3]

/* [Color layers] */
// Traced images only. Flush: all colors at one height (multi-material). Stacked: each color a step higher. Single color: use Icon color.
color_layer_style = "Flush"; // ["Flush","Stacked","Single color"]
// Extra height per color in Stacked style
layer_step_mm = 0.4; // [0.2:0.2:3]
// Color areas narrower than this join the main color (tiny color islands print poorly and waste purge)
min_color_feature_mm = 0.6; // [0:0.05:3]

/* [Colors] */
base_color = "White"; // ["White","Black","Gray","Silver","Red","Orange","Gold","Yellow","LimeGreen","Green","DodgerBlue","Navy","MediumPurple","HotPink","SaddleBrown"]
icon_color = "DodgerBlue"; // ["White","Black","Gray","Silver","Red","Orange","Gold","Yellow","LimeGreen","Green","DodgerBlue","Navy","MediumPurple","HotPink","SaddleBrown"]
detail_color = "Gold"; // ["White","Black","Gray","Silver","Red","Orange","Gold","Yellow","LimeGreen","Green","DodgerBlue","Navy","MediumPurple","HotPink","SaddleBrown"]

// Preview resolution (export always overrides it). $fa/$fs instead of $fn: a
// global $fn also splits every SVG curve into $fn pieces, which makes traced
// images (hundreds of curves) and the offsets applied to them very slow.
$fa = 6;
$fs = 0.4;

// ---------------------------------------------------------------- derived ---

// Written as expressions so they stay out of the parameter form.
BIG = 5 * 1000;        // band length, far beyond any printable model
EPS = 1 / 100;         // anchor size
PHANTOM = 100 * 1000;  // offset of the helper copy used by "Longest side"

is_plate_mode = product_mode == "Badge" || product_mode == "Keychain"
    || product_mode == "Fridge magnet" || product_mode == "Wall sign";
final_mirror = mirror_image != (product_mode == "Stamp");
edge_mm = edge_style == "None" ? 0 : edge_size_mm;
engrave_mm = min(engrave_depth_mm, base_thickness_mm - 0.4);
has_peg = product_mode == "Stamp" && stamp_handle != "None";
plate_mm = product_mode == "Stencil" ? stencil_thickness_mm
    : has_peg ? max(base_thickness_mm, peg_depth_mm + 1.6)
    : base_thickness_mm;
ring_od = ring_hole_mm + 2 * ring_wall_mm;
ring_dir = ring_position == "Left" ? [-1, 0] : ring_position == "Right" ? [1, 0] : [0, 1];
ring_center = ring_hole_mm / 2 + 0.8;   // keeps the hole clear of the plate edge
use_file = source_type != "Icon" && icon_left_file != "";
// Traced colors arrive as "#RRGGBB,#RRGGBB,..." (7 characters each, comma separated),
// in the same order as the layers c0, c1, ... in the file.
layer_count = source_type == "Image" && use_file && len(icon_left_colors) >= 7
    ? floor((len(icon_left_colors) + 1) / 8) : 0;
layer_colors = [for (k = [0 : max(0, layer_count - 1)]) let(o = k * 8)
    str(icon_left_colors[o], icon_left_colors[o + 1], icon_left_colors[o + 2], icon_left_colors[o + 3],
        icon_left_colors[o + 4], icon_left_colors[o + 5], icon_left_colors[o + 6])];
layered = layer_count > 0 && color_layer_style != "Single color"
    && (product_mode == "Flat icon" || (is_plate_mode && (icon_style == "Raised" || icon_style == "Flush inlay")));
stack_mm = layered && color_layer_style == "Stacked" && icon_style != "Flush inlay" ? (layer_count - 1) * layer_step_mm : 0;
icon_top_mm = (product_mode == "Flat icon") ? icon_height_mm + stack_mm
    : (product_mode == "Stamp") ? plate_mm + icon_height_mm
    : icon_style == "Raised" ? plate_mm + icon_height_mm + stack_mm
    : plate_mm;

// ------------------------------------------------------------ 2D helpers ---

module builtin_icon(name) {
    // Drawn at 100 mm so curved parts keep enough segments after resizing.
    scale([100, 100])
        if (name == "Star")
            polygon(points = [for (i = [0 : 9])
                let(a = 90 + i * 36, r = (i % 2 == 0) ? 0.5 : 0.23) [r * cos(a), r * sin(a)]]);
        else if (name == "Heart")
            // Square turned 45 degrees with two half-circle lobes.
            scale(0.58) translate([0, -0.78]) rotate(45) union() {
                square(1);
                translate([0.5, 1]) circle(d = 1, $fn = 96);
                translate([1, 0.5]) circle(d = 1, $fn = 96);
            }
        else if (name == "Flower")
            union() { for (a = [0 : 60 : 300]) rotate(a) translate([0, 0.25]) circle(d = 0.48, $fn = 64); circle(d = 0.3, $fn = 48); }
        else if (name == "Diamond")
            polygon(points = [[0,0.5],[0.42,0],[0,-0.5],[-0.42,0]]);
        else if (name == "Plus")
            union() { square([0.28, 1], center = true); square([1, 0.28], center = true); }
        else if (name == "Lightning")
            polygon(points = [[0.12,0.5],[-0.34,-0.03],[-0.04,-0.03],[-0.16,-0.5],[0.34,0.08],[0.05,0.08]]);
        else if (name == "Balloon")
            union() { translate([0, 0.12]) circle(d = 0.82, $fn = 96); polygon(points = [[-0.12,-0.24],[0.12,-0.24],[0,-0.42]]); hull() { translate([0,-0.39]) circle(d = 0.035, $fn = 12); translate([0.08,-0.5]) circle(d = 0.035, $fn = 12); } }
        else if (name == "Crown")
            polygon(points = [[-0.48,-0.38],[-0.38,0.3],[-0.12,0.02],[0,0.48],[0.14,0.02],[0.4,0.3],[0.48,-0.38]]);
}

module source_art(file, fallback) {
    if (file != "") import(file = file, center = true);
    else builtin_icon(fallback);
}

// Uniformly scales centred artwork. "Longest side" resizes the artwork together
// with a far-away copy rotated 90 degrees, so the shared height equals the
// longest side; resize() scales about the origin, so the copy is then cut away.
module fit_2d(mode, size) {
    if (mode == "Width") resize([size, 0], auto = true) children();
    else if (mode == "Height") resize([0, size], auto = true) children();
    else intersection() {
        square(2 * size, center = true);
        resize([0, size], auto = true) {
            children();
            translate([PHANTOM, 0]) rotate(90) children();
        }
    }
}

module mirror_if(enabled) { if (enabled) mirror([1, 0]) children(); else children(); }
module offset_if(r) { if (r != 0) offset(r = r) children(); else children(); }
module closing(r) { if (r > 0) offset(r = -r) offset(r = r) children(); else children(); }
module opening(r) { if (r > 0) offset(r = r) offset(r = -r) children(); else children(); }
module fill_if(enabled) { if (enabled) fill() children(); else children(); }

// Band spanning the children's x-range (full height) or y-range (full width).
module x_band() { hull() for (y = [-BIG, BIG]) translate([0, y]) scale([1, 1e-3]) hull() children(); }
module y_band() { hull() for (x = [-BIG, BIG]) translate([x, 0]) scale([1e-3, 1]) hull() children(); }
module bbox_2d() { intersection() { x_band() children(); y_band() children(); } }

// Thin strip along one bounding-box side of the children.
module edge_strip(side) {
    if (side == "Top" || side == "Bottom")
        difference() { y_band() children(); translate([0, side == "Top" ? -EPS : EPS]) y_band() children(); }
    else
        difference() { x_band() children(); translate([side == "Left" ? EPS : -EPS, 0]) x_band() children(); }
}

// Tiny square at the middle of one bounding-box side of the children.
module edge_anchor(side) {
    intersection() {
        edge_strip(side) children();
        if (side == "Top" || side == "Bottom") square([EPS, 2 * BIG], center = true);
        else square([2 * BIG, EPS], center = true);
    }
}

// Bounding box of the children with rounded corners: a hull of corner circles
// clipped to the box, so a radius larger than the box still leaves a plate
// instead of disappearing (as offset(-r) would).
module rounded_bbox(r) {
    if (r <= 0) bbox_2d() children();
    else intersection() {
        bbox_2d() children();
        hull() for (v = ["Top", "Bottom"], h = ["Left", "Right"])
            minkowski() {
                intersection() { edge_strip(v) children(); edge_strip(h) children(); }
                translate([h == "Left" ? r : -r, v == "Bottom" ? r : -r]) circle(r = r);
            }
    }
}

// children(0): reference shape; children(1): convex 2D shape placed relative
// to the anchor on that side. (3D minkowski with the thin anchor trips CGAL,
// so 3D parts are extruded or hulled from these 2D placements instead.)
module at_edge_2d(side) { minkowski() { edge_anchor(side) children(0); children(1); } }

// Cone (d1 at z, d2 at z + h) at a position relative to an edge anchor.
module cone_at_edge(side, pos, d1, d2, z, h) {
    hull() {
        translate([0, 0, z]) linear_extrude(EPS) at_edge_2d(side) { base_2d(); translate(pos) circle(d = d1); }
        translate([0, 0, z + h - EPS]) linear_extrude(EPS) at_edge_2d(side) { base_2d(); translate(pos) circle(d = d2); }
    }
}

module smoothed(r) { opening(r) closing(r) children(); }

// ------------------------------------------------------------- artwork ---

module oriented_art() {
    rotate(artwork_rotation_deg) mirror_if(final_mirror)
        fit_2d(size_mode, target_size_mm) source_art(use_file ? icon_left_file : "", fallback_icon);
}

module inverted_if() {
    if (invert_image && layer_count == 0)
        difference() { offset(delta = invert_frame_mm) bbox_2d() children(); children(); }
    else children();
}

module icon_2d() {
    offset_if(bold_mm) opening(min_feature_mm / 2) smoothed(smoothing_mm)
        fill_if(fill_holes) inverted_if() oriented_art();
}

// --------------------------------------------------------- color layers ---

// Every traced layer must get exactly the transform of the full artwork, but
// import(..., center = true) would centre each layer on its own. Layers are
// therefore imported uncentred and shifted by the artwork's bounding-box centre
// (half the minkowski sum of two opposite corner points), then resized together
// with a thin frame on that bounding box, which is cut away again.
module full_art() { import(file = icon_left_file); }
module corner_point(v, h) { intersection() { edge_strip(v) children(); edge_strip(h) children(); } }
module minus_center() { scale([-0.5, -0.5]) minkowski() { corner_point("Bottom", "Left") children(); corner_point("Top", "Right") children(); } }

// Layer i shifted to the artwork centre; i < 0 gives the bounding-box frame.
module centered_layer(i) {
    minkowski() {
        if (i < 0) difference() { bbox_2d() full_art(); offset(delta = -EPS) bbox_2d() full_art(); }
        else import(file = icon_left_file, id = str("c", i));
        minus_center() full_art();
    }
}

module layer_art(i) {
    rotate(artwork_rotation_deg) mirror_if(final_mirror) difference() {
        fit_2d(size_mode, target_size_mm) { centered_layer(i); centered_layer(-1); }
        fit_2d(size_mode, target_size_mm) centered_layer(-1);
    }
}

module layer_raw(i) { intersection() { icon_2d(); smoothed(smoothing_mm) layer_art(i); } }

// Removes specks and slivers of this color narrower than min_color_feature_mm
// (layer 0 takes them over, see layer_region). Opening alone would also round
// every corner and leave hairline slivers along the color borders, so the opened
// shape is grown back and intersected with the original ("opening by
// reconstruction"): corners and straight borders stay exactly where they were.
module layer_shape(i) {
    w = min_color_feature_mm;
    if (w > 0) intersection() { layer_raw(i); offset(r = w) opening(w / 2) layer_raw(i); }
    else layer_raw(i);
}

// Non-overlapping regions without gaps: layer 0 (the largest color) fills
// whatever the other layers leave of the processed silhouette.
module layer_region(i) {
    if (i == 0) difference() {
        icon_2d();
        if (layer_count > 1) for (j = [1 : layer_count - 1]) layer_shape(j);
    }
    else difference() {
        layer_shape(i);
        for (j = [0 : i - 1]) if (j > 0) layer_shape(j);
    }
}

module clip_to_plate(enabled) { if (enabled) intersection() { children(); plate_top_2d(); } else children(); }

// Artwork color i from z to z + h: traced color i (Stacked adds a step per
// color), or the whole artwork in Icon color when there are no color layers.
module icon_layer_solid(i, z, h, clip) {
    if (layered)
        color(layer_colors[i]) difference() {
            translate([0, 0, z]) linear_extrude(height = h + (stack_mm > 0 ? i * layer_step_mm : 0))
                clip_to_plate(clip) layer_region(i);
            mode_cutouts_3d();
        }
    else if (i == 0)
        color(icon_color) difference() {
            translate([0, 0, z]) linear_extrude(height = h) clip_to_plate(clip) icon_2d();
            mode_cutouts_3d();
        }
}

module detail_2d() {
    translate([detail_offset_x_mm, detail_offset_y_mm]) rotate(detail_rotation_deg)
        mirror_if(final_mirror) smoothed(smoothing_mm)
            fit_2d("Longest side", detail_size_mm) source_art(icon_right_file, "");
}

// --------------------------------------------------------------- plates ---

module circle_hull() { hull() for (a = [0 : 3 : 357]) rotate(a) hull() icon_2d(); }

// Smallest regular hexagon (pointy top) around the artwork: the hull of six
// 60-degree copies has equal width in the three band directions.
module hexagon_hull() {
    intersection_for (a = [0, 60, 120]) rotate(a) x_band() rotate(-a)
        hull() for (b = [0 : 60 : 300]) rotate(b) hull() icon_2d();
}

module base_2d() {
    if (base_shape == "Rounded rectangle")
        rounded_bbox(corner_radius_mm) offset(delta = base_margin_mm) bbox_2d() icon_2d();
    else if (base_shape == "Hexagon") {
        // The hexagon's inradius is at least cos(30)/2 of the fitted artwork
        // size, so this limit keeps the inner offset from vanishing.
        r = min(corner_radius_mm, base_margin_mm + target_size_mm * 0.43 - 1);
        offset(r = r) offset(delta = base_margin_mm - r) hexagon_hull();
    }
    else if (base_shape == "Circle") offset(r = base_margin_mm) circle_hull();
    else outline_plate();
}

// The plate outline only needs coarse arcs (at most ~0.04 mm off for a 3 mm
// margin). Full export resolution would put an arc on each of the thousands of
// tiny corners of traced artwork and make every later 3D union very slow.
module outline_plate($fa = 12, $fs = 1) {
    fill() closing(outline_closing_mm) offset(r = base_margin_mm) icon_2d();
}

module keychain_tab_2d() {
    side = ring_position;
    at_edge_2d(side) {
        base_2d();
        hull() { translate(ring_center * ring_dir) circle(d = ring_od); translate(-ring_od / 2 * ring_dir) circle(d = ring_od); }
    }
}

module body_2d() {
    if (product_mode == "Keychain") union() { base_2d(); keychain_tab_2d(); }
    else base_2d();
}

// Plate top surface that is not part of the edge treatment.
module plate_top_2d() { offset(delta = -edge_mm) body_2d(); }

// Extrusion with a stepped chamfer or rounded top edge (steps of about 0.2 mm,
// matching common layer heights).
module edged_extrude(h) {
    e = min(edge_mm, h / 2);
    steps = e > 0 ? min(10, max(2, ceil(e / 0.2))) : 0;
    linear_extrude(height = h - e) children();
    if (steps > 0) for (i = [1 : steps]) {
        t = (i - 0.5) / steps;
        inset = edge_style == "Round" ? e - sqrt(e * e - pow(e * t, 2)) : e * t;
        translate([0, 0, h - e + e * (i - 1) / steps])
            linear_extrude(height = e / steps) offset(delta = -inset) children();
    }
}

// ------------------------------------------------------------- cutouts ---

module keychain_hole_3d() {
    translate([0, 0, -1]) linear_extrude(height = icon_top_mm + detail_height_mm + 2)
        at_edge_2d(ring_position) { base_2d(); translate(ring_center * ring_dir) circle(d = ring_hole_mm); }
}

module magnet_pockets_3d() {
    depth = min(magnet_thickness_mm + magnet_clearance_mm, plate_mm - 0.6);
    for (x = magnet_count == 2 ? [-magnet_spacing_mm / 2, magnet_spacing_mm / 2] : [0])
        translate([x, 0, -1]) cylinder(d = magnet_diameter_mm + 2 * magnet_clearance_mm, h = depth + 1);
}

module screw_holes_3d() {
    sink = (screw_head_mm - screw_diameter_mm) / 2;
    for (side = ["Left", "Right"]) {
        inward = side == "Left" ? mount_inset_mm : -mount_inset_mm;
        translate([0, 0, -1]) linear_extrude(height = plate_mm + 2)
            at_edge_2d(side) { base_2d(); translate([inward, 0]) circle(d = screw_diameter_mm + 0.3); }
        // Countersink, plus clearance through any raised artwork above it.
        cone_at_edge(side, [inward, 0], screw_diameter_mm + 0.3, screw_head_mm + 0.3, plate_mm - sink, sink + 0.01);
        translate([0, 0, plate_mm]) linear_extrude(height = icon_height_mm + stack_mm + detail_height_mm + 1)
            at_edge_2d(side) { base_2d(); translate([inward, 0]) circle(d = screw_head_mm + 0.3); }
    }
}

module keyhole_3d() {
    lip = 1.6;
    cavity = max(0, min(2.5, plate_mm - lip - 1));
    head = screw_head_mm + 0.5;
    shaft = screw_diameter_mm + 0.3;
    top = -mount_inset_mm;              // slot end where the screw rests
    entry = top - screw_head_mm;        // large hole the head goes through
    translate([0, 0, -1]) linear_extrude(height = lip + 1)
        at_edge_2d("Top") {
            base_2d();
            union() { translate([0, entry]) circle(d = head); hull() { translate([0, entry]) circle(d = shaft); translate([0, top]) circle(d = shaft); } }
        }
    if (cavity > 0)
        translate([0, 0, lip - 0.01]) linear_extrude(height = cavity + 0.01)
            at_edge_2d("Top") { base_2d(); hull() { translate([0, entry]) circle(d = head); translate([0, top]) circle(d = head); } }
}

module mode_cutouts_3d() {
    if (product_mode == "Keychain") keychain_hole_3d();
    else if (product_mode == "Fridge magnet") magnet_pockets_3d();
    else if (product_mode == "Wall sign" && mount_style == "Two screw holes") screw_holes_3d();
    else if (product_mode == "Wall sign" && mount_style == "Keyhole") keyhole_3d();
    else if (has_peg) translate([0, 0, -1]) cylinder(d = peg_diameter_mm + 0.3, h = peg_depth_mm + 1);
}

// --------------------------------------------------------------- parts ---

module detail_part(z, surface_is_icon) {
    if (icon_right_file != "")
        color(detail_color) difference() {
            translate([0, 0, z]) linear_extrude(height = detail_height_mm)
                if (!clip_detail) detail_2d();
                else intersection() {
                    detail_2d();
                    if (surface_is_icon) icon_2d();
                    else if (icon_style == "Engraved" || icon_style == "Cut-through")
                        difference() { plate_top_2d(); icon_2d(); }
                    else plate_top_2d();
                }
            mode_cutouts_3d();
        }
}

module plate_body() {
    color(base_color) difference() {
        edged_extrude(plate_mm) body_2d();
        if (icon_style == "Engraved" || icon_style == "Flush inlay")
            translate([0, 0, plate_mm - engrave_mm]) linear_extrude(height = engrave_mm + 1) icon_2d();
        if (icon_style == "Cut-through")
            translate([0, 0, -1]) linear_extrude(height = plate_mm + 2) icon_2d();
        mode_cutouts_3d();
    }
}

module bridges_2d() {
    n = ceil(150 / bridge_spacing_mm);
    union() {
        if (stencil_bridges == "Vertical" || stencil_bridges == "Grid")
            for (i = [-n : n]) translate([i * bridge_spacing_mm, 0]) square([bridge_width_mm, 300], center = true);
        if (stencil_bridges == "Horizontal" || stencil_bridges == "Grid")
            for (i = [-n : n]) translate([0, i * bridge_spacing_mm]) square([300, bridge_width_mm], center = true);
    }
}

module stencil() {
    color(base_color) difference() {
        linear_extrude(height = plate_mm) base_2d();
        translate([0, 0, -1]) linear_extrude(height = plate_mm + 2)
            if (stencil_bridges == "None") icon_2d();
            else difference() { icon_2d(); bridges_2d(); }
    }
}

module stamp_relief() {
    color(icon_color) translate([0, 0, plate_mm]) linear_extrude(height = icon_height_mm)
        intersection() { icon_2d(); plate_top_2d(); }
}

module stamp_body() {
    color(base_color) difference() {
        edged_extrude(plate_mm) base_2d();
        mode_cutouts_3d();
    }
    if (stamp_handle == "Peg hole and knob") {
        // Separate knob printed beside the stamp; its peg fits the peg hole.
        gap = 5 + knob_diameter_mm / 2;
        color(base_color) union() {
            linear_extrude(height = knob_height_mm)
                at_edge_2d("Right") { base_2d(); translate([gap, 0]) circle(d = knob_diameter_mm); }
            translate([0, 0, knob_height_mm]) linear_extrude(height = peg_depth_mm - 0.5)
                at_edge_2d("Right") { base_2d(); translate([gap, 0]) circle(d = peg_diameter_mm - 0.2); }
        }
    }
}

module cutter_outline_2d() { fill() icon_2d(); }

module cutter_ring(t) { difference() { offset(r = t) cutter_outline_2d(); cutter_outline_2d(); } }

module cookie_cutter() {
    tip = min(blade_tip_mm, blade_thickness_mm);
    taper = min(4, cutter_height_mm - flange_height_mm);
    steps = 4;
    color(base_color) union() {
        if (flange_width_mm > 0) linear_extrude(height = flange_height_mm) cutter_ring(blade_thickness_mm + flange_width_mm);
        linear_extrude(height = cutter_height_mm - taper) cutter_ring(blade_thickness_mm);
        for (i = [1 : steps])
            translate([0, 0, cutter_height_mm - taper + taper * (i - 1) / steps])
                linear_extrude(height = taper / steps)
                    cutter_ring(blade_thickness_mm - (blade_thickness_mm - tip) * i / steps);
        if (cutter_inner_details) {
            linear_extrude(height = inner_detail_height_mm) intersection() {
                cutter_outline_2d();
                difference() {
                    offset(delta = inner_wall_mm / 2) difference() { cutter_outline_2d(); icon_2d(); }
                    offset(delta = -inner_wall_mm / 2) difference() { cutter_outline_2d(); icon_2d(); }
                }
            }
            // Bars on the pressing side hold the imprint walls in place.
            linear_extrude(height = flange_height_mm) intersection() {
                cutter_outline_2d();
                for (i = [-ceil(150 / bridge_spacing_mm) : ceil(150 / bridge_spacing_mm)])
                    translate([i * bridge_spacing_mm, 0]) square([bridge_width_mm, 300], center = true);
            }
        }
    }
}

// ----------------------------------------------------------------- model ---

// Part 0: plate or body in Base color (none for Flat icon).
module body_part() {
    if (is_plate_mode) plate_body();
    else if (product_mode == "Stencil") stencil();
    else if (product_mode == "Stamp") stamp_body();
    else if (product_mode == "Cookie cutter") cookie_cutter();
}

// Parts 1..n: one per artwork color (one part in Icon color without color layers).
module icon_part(i) {
    if (product_mode == "Flat icon") {
        if (layered) icon_layer_solid(i, 0, icon_height_mm, false);
        else if (i == 0) color(icon_color) edged_extrude(icon_height_mm) icon_2d();
    }
    else if (is_plate_mode && icon_style == "Raised") icon_layer_solid(i, plate_mm, icon_height_mm, true);
    else if (is_plate_mode && icon_style == "Flush inlay") icon_layer_solid(i, plate_mm - engrave_mm, engrave_mm, false);
    else if (product_mode == "Stamp" && i == 0) stamp_relief();
}

// Last part: the optional second image in Detail color.
module detail_top_part() {
    if (product_mode == "Flat icon") detail_part(icon_top_mm, true);
    else if (is_plate_mode) detail_part(icon_top_mm, icon_style == "Raised");
}

icon_parts = layered ? layer_count : 1;

// One top-level iteration per color part: with the 3MF objects marker above,
// FormForge exports each part as its own object (STL still gets one mesh).
for (k = [0 : icon_parts + 1])
    if (k == 0) body_part();
    else if (k <= icon_parts) icon_part(k - 1);
    else detail_top_part();
