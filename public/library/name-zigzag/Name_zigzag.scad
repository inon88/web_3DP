// ZigZag name keychain.
// Every letter is placed individually from the font's own metrics, alternate letters are raised to
// two different heights for a zigzag profile, the dots of "i" and "j" are bridged to their stems,
// and a keyring loop is attached in front of the first letter. All dimensions are in millimetres.

/* [Text] */
// Name on the keychain
name = "Name";
font_name = "Arial:style=Bold";
// Rounds and thickens every letter so neighbours merge into one piece
text_bold_mm = 0.6; // [0:0.1:3]

/* [Dimensions] */
font_size_mm = 22; // [8:1:60]
// Added to each letter's natural advance; negative values make letters overlap
letter_spacing_mm = -2.5; // [-8:0.5:8]
// Height of the shared base every letter starts from
base_thickness_mm = 2.5; // [1:0.1:6]
// The base bridges gaps between letters up to twice this distance, so the name prints as one piece
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

// ---------- Text metrics ----------
characters = [for (character = name) character];
character_count = len(characters);

function metrics(string) = textmetrics(string, size = font_size_mm, font = font_name);

function cumulative(values, index = 0, total = 0) =
    index >= len(values) ? [] : concat([total], cumulative(values, index + 1, total + values[index]));

letter_x = cumulative([for (character = characters) metrics(character).advance.x + letter_spacing_mm]);
// Spaces keep their width but do not take part in the high/low alternation.
letter_rank = cumulative([for (character = characters) character == " " ? 0 : 1]);

// Stem width of a plain vertical stroke, used to find the dot of "j".
dotless_width = metrics("ı").size.x;
stem_width = dotless_width > 0 ? dotless_width : metrics("l").size.x;
x_height = metrics("x").size.y;
cap_height = metrics("H").size.y;

// The hook sits in front of the first visible letter: its hole stays 1 mm clear of the letter,
// so the ring wall overlaps the letter and the keychain prints as one piece for any font or size.
first_index = [for (index = [0 : max(0, character_count - 1)]) if (character_count > 0 && characters[index] != " ") index][0];
first_metrics = first_index == undef ? undef : metrics(characters[first_index]);
first_left_x = first_index == undef ? 0
    : letter_x[first_index] + first_metrics.position.x - text_bold_mm;
first_right_x = first_index == undef ? 0
    : letter_x[first_index] + first_metrics.position.x + first_metrics.size.x + text_bold_mm;
hole_diameter = min(hook_inner_diameter_mm, hook_outer_diameter_mm - 1);
hook_centre = [
    first_left_x - hole_diameter / 2 - 1 + hook_x_mm,
    cap_height / 2 + hook_y_mm
];

// ---------- Geometry ----------
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
    for (index = [0 : max(0, character_count - 1)])
        if (character_count > 0 && characters[index] != " ")
            translate([letter_x[index], 0]) letter_2d(characters[index]);
}

// Morphological closing: grows the letters, merges them, then shrinks back. Narrow letters such as
// "i", "j", and "l" whose side bearings leave a gap are joined by a web at base height only.
// A space is wider than the gap fill, so each run of spaces gets a bar at base height that links the
// last ink of the word before it to the first ink of the word after it.
module space_bridges_2d() {
    visible = [for (index = [0 : max(0, character_count - 1)]) if (character_count > 0 && characters[index] != " ") index];
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

module base_2d() {
    offset(r = -base_gap_fill_mm)
        offset(r = base_gap_fill_mm)
            union() {
                placed_letters_2d();
                space_bridges_2d();
            }
}

module letters() {
    linear_extrude(height = base_thickness_mm) base_2d();
    for (index = [0 : max(0, character_count - 1)])
        if (character_count > 0 && characters[index] != " ") {
            extra = letter_rank[index] % 2 == 0 ? high_extrusion_mm : low_extrusion_mm;
            translate([letter_x[index], 0, 0])
                linear_extrude(height = base_thickness_mm + extra)
                    letter_2d(characters[index]);
        }
}

color(model_color)
    difference() {
        union() {
            letters();
            if (show_keyring_hook) {
                translate([hook_centre.x, hook_centre.y, 0])
                    cylinder(d = hook_outer_diameter_mm, h = hook_height_mm);
                if (first_index != undef)
                    linear_extrude(height = hook_height_mm) hook_neck_2d();
            }
        }
        if (show_keyring_hook)
            translate([hook_centre.x, hook_centre.y, -1])
                cylinder(d = hole_diameter, h = 100);
    }
