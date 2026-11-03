// Flat lithophane: a photo pressed into a thin plate. Thick spots block light and look dark,
// thin spots let light through, so the picture appears when the plate is held against a lamp.
// All dimensions are in millimetres.
//
// Print tips: white PLA, 100 % infill, stand the plate upright on its bottom edge, 0.1–0.12 mm
// layers. The picture reads correctly from the textured side.

/* [Image] */
// Choose image: dark areas become thick, light areas thin (keep Invert off in the next step)
relief_image_file = "";
// Positive = normal photo when lit; Negative = inverted picture
image_mode = "Positive"; // ["Positive","Negative"]

/* [Size] */
// Size of the picture along the side chosen below (the other side follows the image)
size_mm = 100; // [30:1:250]
// Which side of the image gets the size above
fit_side = "Width"; // ["Width","Height"]
// Thickness at the darkest spots
max_thickness_mm = 3; // [1.2:0.1:6]
// Thickness at the lightest spots (one or two perimeters' worth keeps the plate strong)
min_thickness_mm = 0.8; // [0.3:0.1:2]

/* [Shape] */
// Outline of the lithophane; Circle and Heart are centred on the picture
shape = "Rectangle"; // ["Rectangle","Rounded","Circle","Heart"]
// Corner radius for Rounded
corner_radius_mm = 6; // [1:0.5:40]
// Circle/Heart: width in percent of the size above (set Fit side to the image's shorter side)
shape_size_percent = 100; // [40:1:100]

/* [Frame] */
// Solid border around the picture (0 = none)
frame_mm = 4; // [0:0.5:15]
// Border thickness; at least the maximum thickness
frame_thickness_mm = 4; // [1.2:0.1:10]

/* [Hanger] */
// Ring at the top centre for a string or hook
hanger = true;
// Outer diameter of the ring
hanger_diameter_mm = 10; // [6:0.5:20]
// Hole diameter
hanger_hole_mm = 4; // [2:0.5:12]

/* [Colour] */
plate_color = "White"; // ["White","Ivory","Beige","LightGray","LightSkyBlue","Pink"]

// Preview resolution only; FormForge exports at maximum resolution.
$fa = 6;
$fs = 0.5;

// ---------------------------------------------------------------- derived ---

BIG = 2 * 1000;
EPS = 1 / 100;
t_max = max(max_thickness_mm, min_thickness_mm + 0.2);
t_min = min_thickness_mm;
relief = t_max - t_min;
frame_t = max(frame_thickness_mm, t_max);
hang_r = hanger_diameter_mm / 2;
hole_r = min(hanger_hole_mm, hanger_diameter_mm - 2) / 2;
has_image = relief_image_file != "";

// --------------------------------------------------------------- picture ---

// surface(): one point per pixel, height = brightness 0..100, base 1 unit under the darkest
// pixel. FormForge height maps have a 1 px black border, so the darkest level is always 0.
module scaled_surface() {
    resize(fit_side == "Width" ? [size_mm, 0, 0] : [0, size_mm, 0], auto = [true, true, false])
        surface(file = relief_image_file, center = true);
}

// Height field with brightness 0..1 mapped to 0..relief (solid from just below 0 up to it).
module brightness_field() {
    scale([1, 1, relief / 100]) scaled_surface();
}

// The picture's outline (cut inside the base, just under the darkest level).
module picture_footprint() {
    projection(cut = true) translate([0, 0, relief / 200]) brightness_field();
}

// Demo before an image is chosen: concentric rings and a soft gradient.
demo_w = fit_side == "Width" ? size_mm : size_mm * 4 / 3;
demo_h = fit_side == "Width" ? size_mm * 3 / 4 : size_mm;
module demo_footprint() { square([demo_w, demo_h], center = true); }
module demo_dark_field() {      // solid from z = 0 up to darkness * relief
    r = min(demo_w, demo_h) * 0.45;
    intersection() {
        rotate_extrude($fn = 96)
            polygon(concat([[0, 0]], [for (i = [0 : 48]) let(t = i / 48) [r * t, relief * (0.5 + 0.5 * cos(t * 1080)) * (1 - 0.6 * t)]], [[r, 0]]));
        linear_extrude(relief + 1) demo_footprint();
    }
}

module footprint() { if (has_image) picture_footprint(); else demo_footprint(); }

// OpenSCAD has no bounding-box function, so Circle and Heart are sized from size_mm (the
// fitted side) and clipped by the picture's footprint.
module heart(d) {
    // A square turned 45 degrees with two half circles; d = overall width, centred vertically.
    s = d / (1 + sqrt(2) / 2);
    translate([0, s * (sqrt(2) / 8 - 0.25)]) rotate(45) union() {
        square(s, center = true);
        translate([0, s / 2]) circle(d = s);
        translate([s / 2, 0]) circle(d = s);
    }
}

// Lithophane outline (picture area only, without the frame).
module outline() {
    k = shape_size_percent / 100;
    if (shape == "Rectangle") footprint();
    else if (shape == "Rounded") offset(r = corner_radius_mm) offset(delta = -corner_radius_mm) footprint();
    else intersection() {
        footprint();
        if (shape == "Circle") circle(d = k * size_mm);
        else heart(k * size_mm);
    }
}

// Light-blocking plate: thickness = t_min + relief * darkness.
module picture_plate() {
    intersection() {
        linear_extrude(height = t_max) offset(delta = -EPS) outline();
        if (!has_image) {
            union() { cube([BIG, BIG, 2 * t_min], center = true); translate([0, 0, t_min - EPS]) demo_dark_field(); }
        } else if (image_mode == "Positive") {
            // Mirror the brightness field down from the top: the space under it is
            // t_max - brightness * relief thick, i.e. dark = thick.
            difference() {
                translate([-BIG / 2, -BIG / 2, -1]) cube([BIG, BIG, t_max + 1]);
                translate([0, 0, t_max]) mirror([0, 0, 1]) brightness_field();
            }
        } else {
            union() {
                translate([-BIG / 2, -BIG / 2, -1]) cube([BIG, BIG, t_min + 1]);
                translate([0, 0, t_min]) brightness_field();
            }
        }
    }
}

// ----------------------------------------------------------- frame/hanger ---

module frame_2d() {
    if (frame_mm > 0) difference() { offset(delta = frame_mm) outline(); outline(); }
}

// Space just above the top edge: a strip at x = 0 of the outer outline (picture + frame,
// convex hull so the heart's dip is bridged), lifted by the ring diameter, minus itself.
module outer_hull() { hull() offset(delta = frame_mm) outline(); }

module hanger_cell() {
    difference() {
        translate([0, hanger_diameter_mm]) intersection() {
            outer_hull();
            square([hanger_diameter_mm, BIG], center = true);
        }
        outer_hull();
    }
}

// Ring centre found by shrinking the cell to a point, then growing it back to a circle.
module hanger_disc(r) { offset(r = r) offset(delta = -(hang_r - EPS)) hanger_cell(); }

module hanger_2d() {
    difference() {
        hull() { hanger_disc(hang_r); translate([0, -2 * hanger_diameter_mm]) hanger_disc(hang_r); }
        hanger_disc(hole_r);
    }
}

// ----------------------------------------------------------------- model ---

color(plate_color) union() {
    picture_plate();
    if (frame_mm > 0) linear_extrude(height = frame_t) frame_2d();
    if (hanger) linear_extrude(height = frame_t) difference() { hanger_2d(); offset(delta = -EPS) outline(); }
}

if (!has_image) echo("Choose an image to make your lithophane; the rings are a demo.");
echo(str("Lithophane thickness: ", t_min, " mm (light) to ", t_max, " mm (dark)"));
