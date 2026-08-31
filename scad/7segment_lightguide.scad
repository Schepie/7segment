// Modular 7-Segment Lightguide / Diffuser (Parametric)
// Solid continuous reflector walls (No wire/connector cutouts)
// Optimized for maximum brightness: 0.6mm and 0.8mm top diffuser layer variants

// --- Configuration Parameter ---
diffuser_thick = 0.6; // [0.6: High Brightness (0.6mm), 0.8: Balanced (0.8mm), 1.0: Standard (1.0mm)]

total_depth = 13.0;   // Matches frontplate housing depth (13.0 mm)
tunnel_depth = total_depth - diffuser_thick; // Inner cavity depth (12.4mm for 0.6, 12.2mm for 0.8)

// --- Dimensions (matching 7segment_pogo / 7segment_v1) ---
pitch_x = 92;
pitch_y_top = 92;
pitch_y_bot = 92;
strip_width = 12;
white_wall = 1.2;
front_wall = 2.0;

diffuser_w = strip_width + 2;               // 14 mm
total_seg_w = diffuser_w + white_wall * 2;  // 16.4 mm

total_seg_l_x = pitch_x - front_wall * 1.4142;
total_seg_l_y_top = pitch_y_top - front_wall * 1.4142;
total_seg_l_y_bot = pitch_y_bot - front_wall * 1.4142;
diffuser_l_x = total_seg_l_x - white_wall * 2;
diffuser_l_y_top = total_seg_l_y_top - white_wall * 2;
diffuser_l_y_bot = total_seg_l_y_bot - white_wall * 2;

// --- Shapes & Helpers ---
module segment_shape(l, w, h) {
    translate([0, 0, -0.1])
    linear_extrude(height = h + 0.2)
    polygon([
        [-l/2 + w/2, -w/2],
        [l/2 - w/2, -w/2],
        [l/2, 0],
        [l/2 - w/2, w/2],
        [-l/2 + w/2, w/2],
        [-l/2, 0]
    ]);
}

module layout_horiz(is_top=false, is_bot=false) {
    if (is_top) {
        translate([0, pitch_y_top, 0]) children();
    } else if (is_bot) {
        translate([0, -pitch_y_bot, 0]) children();
    } else {
        translate([0, 0, 0]) children();
    }
}

module layout_vert(is_top=false) {
    if (is_top) {
        translate([-pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) children();
        translate([pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) children();
    } else {
        translate([-pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) children();
        translate([pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) children();
    }
}

module frontplate_white(d_thick = diffuser_thick) {
    t_depth = total_depth - d_thick;
    difference() {
        // Outer white reflector walls + top diffuser (Total depth = 13.0 mm)
        union() {
            layout_horiz(false, false) segment_shape(total_seg_l_x, total_seg_w, total_depth);
            layout_horiz(true, false) segment_shape(total_seg_l_x, total_seg_w, total_depth);
            layout_horiz(false, true) segment_shape(total_seg_l_x, total_seg_w, total_depth);
            layout_vert(true) segment_shape(total_seg_l_y_top, total_seg_w, total_depth);
            layout_vert(false) segment_shape(total_seg_l_y_bot, total_seg_w, total_depth);
        }
            
        // Hollow light tunnel cavity, leaving d_thick solid diffuser face on top
        layout_horiz(false, false) segment_shape(diffuser_l_x, diffuser_w, t_depth);
        layout_horiz(true, false) segment_shape(diffuser_l_x, diffuser_w, t_depth);
        layout_horiz(false, true) segment_shape(diffuser_l_x, diffuser_w, t_depth);
        layout_vert(true) segment_shape(diffuser_l_y_top, diffuser_w, t_depth);
        layout_vert(false) segment_shape(diffuser_l_y_bot, diffuser_w, t_depth);
    }
}

// Default render
color("White") frontplate_white(diffuser_thick);
