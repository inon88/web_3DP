// Nested decorative lettering. Each element uses this OpenSCAD vector layout:
// [type, text, font, icon, svgPath, x, y, size, thickness, bold, placement, inset, children, color]
// @formforge-nested-tree max-depth=4
decorative_layers = [];

/* [Main Letter] */
main_text = "P";
font_name = "Liberation Sans:style=Bold";
main_size_mm = 180; // [20:1:210]
main_thickness_mm = 6; // [1:0.2:20]
main_bold_mm = 0.6; // [0:0.1:4]

$fn = 48;

module decorative_icon(icon_name, size_mm) {
    scale([size_mm, size_mm])
        if (icon_name == "Star")
            polygon(points = [for (i = [0 : 9])
                let(a = 90 + i * 36, r = (i % 2 == 0) ? 0.5 : 0.23)
                    [r * cos(a), r * sin(a)]]);
        else if (icon_name == "Heart")
            polygon(points = [[0,-0.5],[-0.46,-0.05],[-0.5,0.14],[-0.46,0.33],[-0.34,0.47],[-0.17,0.5],[0,0.35],[0.17,0.5],[0.34,0.47],[0.46,0.33],[0.5,0.14],[0.46,-0.05]]);
        else if (icon_name == "Flower")
            union() { for (a = [0 : 60 : 300]) rotate(a) translate([0,0.25]) circle(d=0.48); circle(d=0.3); }
        else if (icon_name == "Diamond")
            polygon(points = [[0,0.5],[0.42,0],[0,-0.5],[-0.42,0]]);
        else if (icon_name == "Plus")
            union() { square([0.28,1], center=true); square([1,0.28], center=true); }
        else if (icon_name == "Lightning")
            polygon(points = [[0.12,0.5],[-0.34,-0.03],[-0.04,-0.03],[-0.16,-0.5],[0.34,0.08],[0.05,0.08]]);
        else if (icon_name == "Balloon")
            union() { translate([0,0.12]) circle(d=0.82); polygon(points=[[-0.12,-0.24],[0.12,-0.24],[0,-0.42]]); hull() { translate([0,-0.39]) circle(d=0.035); translate([0.08,-0.5]) circle(d=0.035); } }
        else if (icon_name == "Crown")
            polygon(points = [[-0.48,-0.38],[-0.38,0.3],[-0.12,0.02],[0,0.48],[0.14,0.02],[0.4,0.3],[0.48,-0.38]]);
        else circle(d=0.8);
}

module main_letter() {
    color("White")
        linear_extrude(height=main_thickness_mm)
            offset(r=main_bold_mm)
                text(main_text, size=main_size_mm, font=font_name,
                    halign="center", valign="center", spacing=0.95);
}

module element_shape(element) {
    if (element[0] == "Text")
        text(element[1], size=element[7], font=element[2], halign="center", valign="center");
    else if (element[0] == "Icon")
        decorative_icon(element[3], element[7]);
    else if (element[0] == "SVG" && element[4] != "")
        resize([element[7], element[7], 0], auto=true) import(file=element[4], center=true);
}

module render_element(element, parent_x, parent_y, parent_z, parent_thickness) {
    x = parent_x + element[5];
    y = parent_y + element[6];
    z = parent_z + parent_thickness
        - (element[10] == "Inset" ? min(element[11], parent_thickness) : 0);
    color(element[13])
        translate([x,y,z])
            linear_extrude(height=element[8])
                offset(r=element[9]) element_shape(element);
    for (child = element[12])
        render_element(child, x, y, z, element[8]);
}

union() {
    main_letter();
    for (element = decorative_layers)
        render_element(element, 0, 0, 0, main_thickness_mm);
}
