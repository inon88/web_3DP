// ZigZag name keychains — many names at once.
// Same keychain as Name_zigzag.scad, but "names" takes several names separated by commas
// ("Ana, Budi, Citra"). Every name becomes its own keychain, laid out in a grid with a gap between
// them so the whole batch prints in one go. All dimensions are in millimetres.

/* [Text] */
// Names separated by commas; spaces around each name are ignored and empty entries are skipped
names = "Ana, Budi, Citra, Jijil";
font_name = "Arial:style=Bold";
// Rounds and thickens every letter so neighbours merge into one piece
text_bold_mm = 0.6; // [0:0.1:3]

/* [Layout] */
// Number of keychains side by side; the rest continue on the next rows
columns = 1; // [1:1:6]
// Clear space between neighbouring keychains
keychain_gap_mm = 5; // [1:0.5:30]

/* [Dimensions] */
font_size_mm = 22; // [8:1:60]
// Added to each letter's natural advance; negative values make letters overlap
letter_spacing_mm = -2.5; // [-8:0.5:8]
// Height of the shared base every letter starts from
base_thickness_mm = 2.5; // [1:0.1:6]
// The base bridges gaps between letters up to twice this distance, so each name prints as one piece
base_gap_fill_mm = 2.5; // [0:0.5:6]
// Width of the bar that joins the dot of "i" and "j" to the stem
dot_bridge_width_mm = 1.6; // [0.4:0.1:5]

/* [Alternating Z extrusion] */
// Extra height above the base for the 1st, 3rd, 5th… letter
high_extrusion_mm = 4; // [0:0.1:15]
// Extra height above the base for the 2nd, 4th, 6th… letter
low_extrusion_mm = 2; // [0:0.1:15]

/* [Keyring hook] */
show_keyring_hook = true;
hook_outer_diameter_mm = 10; // [4:0.5:30]
hook_inner_diameter_mm = 5; // [1:0.5:25]
hook_height_mm = 4.5; // [1:0.1:15]
// Moves the hook left (−) or right (+) from its automatic spot in front of the first letter
hook_x_mm = 0; // [-20:0.5:20]
// Moves the hook down (−) or up (+) from the middle of the capital letter height
hook_y_mm = 0; // [-30:0.5:30]

/* [Color] */
// Hex code or OpenSCAD color name; kept in 3MF export
model_color = "#F85DE9";

// Preview resolution only — FormForge exports at maximum resolution regardless.
$fn = 32;

// ---------- Name list ----------
function substring(string, start, end) =
    start >= end ? "" : chr([for (index = [start : end - 1]) ord(string[index])]);

function split(string, separator = ",", index = 0, start = 0) =
    index >= len(string) ? [substring(string, start, len(string))]
    : string[index] == separator
        ? concat([substring(string, start, index)], split(string, separator, index + 1, index + 1))
        : split(string, separator, index + 1, start);

function trim(string) =
    let(kept = [for (index = [0 : max(0, len(string) - 1)]) if (len(string) > 0 && string[index] != " ") index])
    len(kept) == 0 ? "" : substring(string, kept[0], kept[len(kept) - 1] + 1);

labels = [for (entry = split(names)) let(label = trim(entry)) if (label != "") label];
label_count = len(labels);

// ---------- Text metrics ----------
function metrics(string) = textmetrics(string, size = font_size_mm, font = font_name);

function cumulative(values, index = 0, total = 0) =
    index >= len(values) ? [] : concat([total], cumulative(values, index + 1, total + values[index]));

// Shared by every name: they only depend on the font and size.
dotless_width = metrics("ı").size.x;
stem_width = dotless_width > 0 ? dotless_width : metrics("l").size.x;
x_height = metrics("x").size.y;
cap_height = metrics("H").size.y;
hole_diameter = min(hook_inner_diameter_mm, hook_outer_diameter_mm - 1);

function characters_of(label) = [for (character = label) character];
function letter_x_of(characters) =
    cumulative([for (character = characters) metrics(character).advance.x + letter_spacing_mm]);
function visible_of(characters) = [for (index = [0 : len(characters) - 1]) if (characters[index] != " ") index];

// The hook sits in front of the first letter: its hole stays 1 mm clear of the letter,
// so the ring wall overlaps the letter and every keychain prints as one piece.
function hook_centre_of(characters) =
    let(
        letter_x = letter_x_of(characters),
        first = visible_of(characters)[0],
        first_metrics = metrics(characters[first])
    )
    [
        letter_x[first] + first_metrics.position.x - text_bold_mm - hole_diameter / 2 - 1 + hook_x_mm,
        cap_height / 2 + hook_y_mm
    ];

// [left, right, bottom, top] of one keychain, used to lay the batch out without overlaps.
function bounds_of(label) =
    let(
        characters = characters_of(label),
        letter_x = letter_x_of(characters),
        visible = visible_of(characters),
        first = visible[0],
        last = visible[len(visible) - 1],
        first_metrics = metrics(characters[first]),
        last_metrics = metrics(characters[last]),
        whole = metrics(label),
        hook = hook_centre_of(characters),
        ring = hook_outer_diameter_mm / 2,
        left = letter_x[first] + first_metrics.position.x - text_bold_mm,
        right = letter_x[last] + last_metrics.position.x + last_metrics.size.x + text_bold_mm,
        bottom = whole.position.y - text_bold_mm,
        top = whole.position.y + whole.size.y + text_bold_mm
    )
    show_keyring_hook
        ? [min(left, hook.x - ring), max(right, hook.x + ring), min(bottom, hook.y - ring), max(top, hook.y + ring)]
        : [left, right, bottom, top];

all_bounds = [for (label = labels) bounds_of(label)];
cell_width = label_count == 0 ? 0 : max([for (b = all_bounds) b[1] - b[0]]) + keychain_gap_mm;
cell_height = label_count == 0 ? 0 : max([for (b = all_bounds) b[3] - b[2]]) + keychain_gap_mm;

// ---------- One keychain ----------
module keychain(label) {
    characters = characters_of(label);
    character_count = len(characters);
    letter_x = letter_x_of(characters);
    // Spaces keep their width but do not take part in the high/low alternation.
    letter_rank = cumulative([for (character = characters) character == " " ? 0 : 1]);
    visible = visible_of(characters);
    first_index = visible[0];
    first_right_x = letter_x[first_index] + metrics(characters[first_index]).position.x
        + metrics(characters[first_index]).size.x + text_bold_mm;
    hook_centre = hook_centre_of(characters);

    module dot_bridge(character) {
        m = metrics(character);
        // "i" has its dot centred over the stem; the dot of "j" sits over the stem at the right of its box.
        centre_x = character == "i"
            ? m.position.x + m.size.x / 2
            : m.position.x + m.size.x - stem_width / 2;
        top_y = m.position.y + m.size.y - stem_width / 2;
        bottom_y = x_height * 0.5;
        if (top_y > bottom_y)
            translate([centre_x - dot_bridge_width_mm / 2, bottom_y])
                square([dot_bridge_width_mm, top_y - bottom_y]);
    }

    module letter_2d(character) {
        offset(r = text_bold_mm)
            union() {
                text(character, size = font_size_mm, font = font_name);
                if (character == "i" || character == "j") dot_bridge(character);
            }
    }

    // Fills the gap between the hook and the first letter, row by row, up to the letter's nearest edge.
    // This keeps the hook attached even when the first letter is open on the left at hook height (e.g. "J").
    module hook_neck_2d() {
        neck_height = hook_outer_diameter_mm * 0.5;
        module band() {
            translate([hook_centre.x, hook_centre.y - neck_height / 2])
                square([max(0.01, first_right_x - hook_centre.x), neck_height]);
        }
        offset(delta = 0.3)
            difference() {
                band();
                // Everything at or to the right of the letter's material in each row.
                minkowski() {
                    intersection() {
                        band();
                        translate([letter_x[first_index], 0]) letter_2d(characters[first_index]);
                    }
                    translate([0, -0.005]) square([1000, 0.01]);
                }
            }
    }

    module placed_letters_2d() {
        for (index = visible)
            translate([letter_x[index], 0]) letter_2d(characters[index]);
    }

    // A space is wider than the gap fill, so each run of spaces gets a bar at base height that links the
    // last ink of the word before it to the first ink of the word after it.
    module space_bridges_2d() {
        bar_height = max(1.5, x_height * 0.35);
        for (index = [1 : max(1, character_count - 1)])
            if (index < character_count && characters[index] == " " && characters[index - 1] != " ") {
                before = [for (candidate = visible) if (candidate < index) candidate];
                after = [for (candidate = visible) if (candidate > index) candidate];
                if (len(before) > 0 && len(after) > 0) {
                    previous = before[len(before) - 1];
                    next = after[0];
                    previous_metrics = metrics(characters[previous]);
                    start_x = letter_x[previous] + previous_metrics.position.x + previous_metrics.size.x - 1;
                    end_x = letter_x[next] + metrics(characters[next]).position.x + 1;
                    translate([start_x, x_height * 0.5 - bar_height / 2])
                        square([max(0.01, end_x - start_x), bar_height]);
                }
            }
    }

    // Morphological closing: grows the letters, merges them, then shrinks back. Narrow letters such as
    // "i", "j", and "l" whose side bearings leave a gap are joined by a web at base height only.
    module base_2d() {
        offset(r = -base_gap_fill_mm)
            offset(r = base_gap_fill_mm)
                union() {
                    placed_letters_2d();
                    space_bridges_2d();
                }
    }

    difference() {
        union() {
            linear_extrude(height = base_thickness_mm) base_2d();
            for (index = visible) {
                extra = letter_rank[index] % 2 == 0 ? high_extrusion_mm : low_extrusion_mm;
                translate([letter_x[index], 0, 0])
                    linear_extrude(height = base_thickness_mm + extra)
                        letter_2d(characters[index]);
            }
            if (show_keyring_hook) {
                translate([hook_centre.x, hook_centre.y, 0])
                    cylinder(d = hook_outer_diameter_mm, h = hook_height_mm);
                linear_extrude(height = hook_height_mm) hook_neck_2d();
            }
        }
        if (show_keyring_hook)
            translate([hook_centre.x, hook_centre.y, -1])
                cylinder(d = hole_diameter, h = 100);
    }
}

// ---------- Batch layout ----------
// Keychains fill each row left to right, then continue on the next row below.
color(model_color)
    for (index = [0 : max(0, label_count - 1)])
        if (label_count > 0) {
            b = all_bounds[index];
            column = index % columns;
            row = floor(index / columns);
            translate([column * cell_width - b[0], -row * cell_height - b[2], 0])
                keychain(labels[index]);
        }
