// Filament painting (HueForge-style relief): the picture's brightness becomes height, and the
// relief is printed with dark filaments at the bottom and lighter filaments on top, so thin
// layers blend into shades. All dimensions are in millimetres.
//
// Multi-material printers: export 3MF. Every filament band is its own object, so the slicer
// loads them as parts of one model and the printer swaps filament by itself.
// Single nozzle without a filament changer: export STL and add the filament changes listed in
// the OpenSCAD console ("Swap to … at … mm") in the slicer.
// @formforge-3mf-objects

/* [Image] */
// Choose image: brightness becomes height; levels and contrast are set in the next step
relief_image_file = "";

/* [Size] */
// Width of the picture (the height follows the image)
width_mm = 100; // [30:1:250]
// Print layer height; filament changes are placed on whole layers
layer_height_mm = 0.08; // [0.04:0.01:0.2]
// Solid base under the picture, printed in filament 1
base_mm = 0.6; // [0.24:0.04:3]
// Height of the relief above the base
relief_mm = 1.6; // [0.4:0.04:6]
// Raised border around the picture (0 = none)
frame_mm = 0; // [0:0.5:10]

/* [Filaments] */
// Bottom to top: start dark and end light for the usual result
filament_count = 4; // [2:1:6]
filament_1 = "Black"; // ["Black","DimGray","Gray","Silver","White","Navy","DarkRed","DarkGreen","SaddleBrown","Red","Orange","Gold","Yellow","LimeGreen","Green","Cyan","DodgerBlue","MediumPurple","Magenta","HotPink","Pink","Tan","Beige"]
filament_2 = "Gray"; // ["Black","DimGray","Gray","Silver","White","Navy","DarkRed","DarkGreen","SaddleBrown","Red","Orange","Gold","Yellow","LimeGreen","Green","Cyan","DodgerBlue","MediumPurple","Magenta","HotPink","Pink","Tan","Beige"]
filament_3 = "Silver"; // ["Black","DimGray","Gray","Silver","White","Navy","DarkRed","DarkGreen","SaddleBrown","Red","Orange","Gold","Yellow","LimeGreen","Green","Cyan","DodgerBlue","MediumPurple","Magenta","HotPink","Pink","Tan","Beige"]
filament_4 = "White"; // ["Black","DimGray","Gray","Silver","White","Navy","DarkRed","DarkGreen","SaddleBrown","Red","Orange","Gold","Yellow","LimeGreen","Green","Cyan","DodgerBlue","MediumPurple","Magenta","HotPink","Pink","Tan","Beige"]
filament_5 = "Gold"; // ["Black","DimGray","Gray","Silver","White","Navy","DarkRed","DarkGreen","SaddleBrown","Red","Orange","Gold","Yellow","LimeGreen","Green","Cyan","DodgerBlue","MediumPurple","Magenta","HotPink","Pink","Tan","Beige"]
filament_6 = "Beige"; // ["Black","DimGray","Gray","Silver","White","Navy","DarkRed","DarkGreen","SaddleBrown","Red","Orange","Gold","Yellow","LimeGreen","Green","Cyan","DodgerBlue","MediumPurple","Magenta","HotPink","Pink","Tan","Beige"]
// Equal spreads the filaments evenly over the relief height
band_mode = "Equal"; // ["Equal","Custom"]
// Custom: where filament 1 ends, in percent of the relief height
band_1_top_percent = 20; // [0:1:100]
// Custom: where filament 2 ends
band_2_top_percent = 45; // [0:1:100]
// Custom: where filament 3 ends
band_3_top_percent = 70; // [0:1:100]
// Custom: where filament 4 ends
band_4_top_percent = 85; // [0:1:100]
// Custom: where filament 5 ends
band_5_top_percent = 95; // [0:1:100]

// Preview resolution only; FormForge exports at maximum resolution.
$fa = 6;
$fs = 0.5;

// ---------------------------------------------------------------- derived ---

colors = [filament_1, filament_2, filament_3, filament_4, filament_5, filament_6];
count = filament_count;
top_z = base_mm + relief_mm;
function snap(z) = max(layer_height_mm, round(z / layer_height_mm) * layer_height_mm);

// Fraction of the relief height where each filament ends (the last one runs to the top).
custom_tops = [band_1_top_percent, band_2_top_percent, band_3_top_percent, band_4_top_percent, band_5_top_percent];
custom = [for (k = [0 : count - 2]) custom_tops[k] / 100];
fractions = band_mode == "Custom" ? custom : [for (k = [0 : count - 2]) (k + 1) / count];
// Band tops, snapped to whole layers, never below the base or the previous band.
function tops(k = 0, previous = 0) = k > count - 2 ? []
    : let(z = max(previous + layer_height_mm, snap(base_mm + relief_mm * fractions[k]))) concat([z], tops(k + 1, z));
band_top = concat(tops(), [top_z + 1]);
band_bottom = concat([-1], [for (k = [0 : count - 2]) band_top[k]]);

echo(str("Filament 1 (", colors[0], "): from the first layer to ", band_top[0], " mm"));
for (k = [1 : count - 1])
    echo(str("Swap to filament ", k + 1, " (", colors[k], ") at ", band_bottom[k], " mm = start of layer ",
        round(band_bottom[k] / layer_height_mm) + 1, " (with a first layer of ", layer_height_mm, " mm)"));
if (band_top[count - 2] >= top_z)
    echo("Some filaments start above the top of the relief and will not show; lower the Custom band tops.");

// ------------------------------------------------------------------ relief ---

// surface() gives one point per pixel with height = brightness 0..100 and its base 1 unit
// below the darkest pixel. FormForge height maps always have a 1 px black border, so the
// darkest level is 0 and the base sits just under base_mm everywhere.
module picture() {
    translate([0, 0, base_mm]) scale([1, 1, relief_mm / 100])
        resize([width_mm, 0, 0], auto = [true, true, false]) surface(file = relief_image_file, center = true);
}

// The picture's outline: a cut just under the lowest brightness level, inside the base.
module footprint() {
    projection(cut = true) translate([0, 0, -(base_mm - relief_mm / 200)]) picture();
}

// Demo before an image is chosen: a soft dome with rings, so the bands are visible.
module demo_relief() {
    r = width_mm * 0.36;
    linear_extrude(height = base_mm) square([width_mm, width_mm * 0.75], center = true);
    intersection() {
        translate([0, 0, base_mm - 0.01]) rotate_extrude($fn = 96)
            polygon(concat([[0, 0]], [for (i = [0 : 24]) let(t = i / 24) [r * t, relief_mm * (1 - t * t) * (0.75 + 0.25 * cos(t * 1440))]], [[r, 0]]));
        cube([width_mm, width_mm * 0.75, 2 * top_z + 2], center = true);
    }
}

module relief() {
    if (relief_image_file != "") {
        picture();
        linear_extrude(height = base_mm) footprint();
        if (frame_mm > 0)
            linear_extrude(height = top_z) difference() { offset(delta = frame_mm) footprint(); footprint(); }
    } else demo_relief();
}

module band(k) {
    intersection() {
        relief();
        translate([-1000, -1000, band_bottom[k]]) cube([2000, 2000, band_top[k] - band_bottom[k]]);
    }
}

// ----------------------------------------------------------------- model ---

// One top-level iteration per filament: each band is its own 3MF object.
for (k = [0 : count - 1]) color(colors[k]) band(k);
