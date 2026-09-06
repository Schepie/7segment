// =========================================================================
// Modular 7-Segment Lightguide / Diffuser with Snaps (Dual Material)
// PRINT ORIENTATION: Flat front diffuser face on the print bed (Z = 0)
// - Layer 1 (White):        Z = 0.0 to 0.4 mm (2 solid layers of White @ 0.20mm)
// - Body (Transparent):     Z = 0.4 to 13.0 mm (0.4mm transparent core + 12.2mm hollow walls + snaps)
// ZERO OVERLAP: Layer 1 is strictly [0.0, 0.4], Layer 2 is strictly [0.4, 13.0]
// =========================================================================

/* [Parameters] */
diffuser_thick = 0.8;          // 0.8mm total diffuser face
layer1_white_thick = 0.4;      // 0.4mm white front layer (2 layers @ 0.20mm)
enable_segment_snaps = true;   // Snap teeth enabled
segment_clearance = 0.15;      // 0.15mm perimeter clearance

total_depth = 13.0;            // Total housing depth (13.0 mm)
tunnel_depth = total_depth - diffuser_thick; // Inner cavity depth (12.2 mm)

pitch_x = 92.0;
pitch_y_top = 92.0;
pitch_y_bot = 92.0;
strip_width = 12.0;
white_wall = 1.2;
front_wall = 2.0;

diffuser_w = strip_width + 2;               // 14.0 mm
total_seg_w = diffuser_w + white_wall * 2;  // 16.4 mm

total_seg_l_x = pitch_x - front_wall * 1.4142;      // 89.17 mm
total_seg_l_y_top = pitch_y_top - front_wall * 1.4142;
total_seg_l_y_bot = pitch_y_bot - front_wall * 1.4142;
diffuser_l_x = total_seg_l_x - white_wall * 2;      // 86.77 mm
diffuser_l_y_top = total_seg_l_y_top - white_wall * 2;
diffuser_l_y_bot = total_seg_l_y_bot - white_wall * 2;

// --- Shapes & Helpers ---
module segment_shape_2d(l, w) {
    polygon([
        [-l/2 + w/2, -w/2],
        [l/2 - w/2, -w/2],
        [l/2, 0],
        [l/2 - w/2, w/2],
        [-l/2 + w/2, w/2],
        [-l/2, 0]
    ]);
}

module segment_shape(l, w, h) {
    linear_extrude(height = h)
        segment_shape_2d(l, w);
}

// Snap teeth: positioned near the open top (at Z = total_depth - 3.0 = 10.0mm from bed)
module single_segment_snap_teeth_print_orient(l = total_seg_l_x, w = total_seg_w) {
    if (enable_segment_snaps) {
        tooth_w = 3.5;
        tooth_h = 2.2;
        tooth_reach = 0.45;
        z_pos = total_depth - 3.0; // 10.0mm above print bed
        
        for (side = [-1, 1]) {
            for (x_pos = [-22.0, 22.0]) {
                translate([x_pos, side * (w/2 - segment_clearance), z_pos]) {
                    rotate([side > 0 ? 0 : 180, 0, 0])
                        rotate([0, 90, 0])
                            linear_extrude(tooth_w, center=true)
                                polygon([
                                    [-tooth_h/2, -0.4],
                                    [-tooth_h/4, tooth_reach],
                                    [tooth_h/4, tooth_reach],
                                    [tooth_h/2, -0.4]
                                ]);
                }
            }
        }
    }
}

// Flex relief slits flanking snap teeth (cutting from top down)
module single_segment_flex_slits_print_orient(w = total_seg_w) {
    if (enable_segment_snaps) {
        slit_w = 0.8;
        slit_l = 3.5;
        slit_h = 5.5;
        z_center = total_depth - slit_h/2;
        
        for (side = [-1, 1]) {
            for (x_center = [-22.0, 22.0]) {
                for (dx = [-2.5, 2.5]) {
                    translate([x_center + dx, side * (w/2 - segment_clearance), z_center + 0.1])
                        cube([slit_w, slit_l, slit_h + 0.2], center=true);
                }
            }
        }
    }
}

// --- 1. Layer 1 (White Filament): Strictly Z = 0.0 to 0.40 mm ---
module single_segment_WHITE_layer1(l = total_seg_l_x, w = total_seg_w) {
    eff_w = w - segment_clearance * 2;
    eff_l = l - segment_clearance * 2;
    segment_shape(eff_l, eff_w, layer1_white_thick);
}

// --- 2. Body (Transparent Filament): Strictly Z = 0.40 to 13.00 mm ---
module single_segment_TRANSPARENT_body(l = total_seg_l_x, w = total_seg_w) {
    eff_w = w - segment_clearance * 2;
    eff_l = l - segment_clearance * 2;
    inner_w = diffuser_w;
    inner_l = l - white_wall * 2;
    
    // Starts strictly at Z = 0.40mm
    translate([0, 0, layer1_white_thick]) {
        difference() {
            union() {
                // Outer shell from Z = 0.4 to 13.0 (height = 12.6mm)
                segment_shape(eff_l, eff_w, total_depth - layer1_white_thick);
                
                // Snap teeth (shifted relative to Z=0.4)
                translate([0, 0, -layer1_white_thick])
                    single_segment_snap_teeth_print_orient(l, w);
            }
            
            // Hollow inner cavity: starts at Z = (diffuser_thick - layer1_white_thick = 0.4mm) above the transparent floor
            // Cuts all the way open through the top at Z = 13.0mm
            translate([0, 0, diffuser_thick - layer1_white_thick])
                segment_shape(inner_l, inner_w, total_depth - diffuser_thick + 1.0);
                
            // Flex slits
            translate([0, 0, -layer1_white_thick])
                single_segment_flex_slits_print_orient(w);
        }
    }
}

// --- 3. Full Solid Single Piece (Z = 0.0 to 13.0 mm) ---
module single_segment_SOLID(l = total_seg_l_x, w = total_seg_w) {
    eff_w = w - segment_clearance * 2;
    eff_l = l - segment_clearance * 2;
    inner_w = diffuser_w;
    inner_l = l - white_wall * 2;
    
    difference() {
        union() {
            segment_shape(eff_l, eff_w, total_depth);
            single_segment_snap_teeth_print_orient(l, w);
        }
        translate([0, 0, diffuser_thick])
            segment_shape(inner_l, inner_w, total_depth - diffuser_thick + 1.0);
        single_segment_flex_slits_print_orient(w);
    }
}

// --- 7-Segment Assembly Layouts ---
module layout_7segments_white() {
    translate([0, pitch_y_top, 0]) single_segment_WHITE_layer1(total_seg_l_x, total_seg_w);
    translate([pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) single_segment_WHITE_layer1(total_seg_l_y_top, total_seg_w);
    translate([pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) single_segment_WHITE_layer1(total_seg_l_y_bot, total_seg_w);
    translate([0, -pitch_y_bot, 0]) single_segment_WHITE_layer1(total_seg_l_x, total_seg_w);
    translate([-pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) single_segment_WHITE_layer1(total_seg_l_y_bot, total_seg_w);
    translate([-pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) single_segment_WHITE_layer1(total_seg_l_y_top, total_seg_w);
    translate([0, 0, 0]) single_segment_WHITE_layer1(total_seg_l_x, total_seg_w);
}

module layout_7segments_transp() {
    translate([0, pitch_y_top, 0]) single_segment_TRANSPARENT_body(total_seg_l_x, total_seg_w);
    translate([pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) single_segment_TRANSPARENT_body(total_seg_l_y_top, total_seg_w);
    translate([pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) single_segment_TRANSPARENT_body(total_seg_l_y_bot, total_seg_w);
    translate([0, -pitch_y_bot, 0]) single_segment_TRANSPARENT_body(total_seg_l_x, total_seg_w);
    translate([-pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) single_segment_TRANSPARENT_body(total_seg_l_y_bot, total_seg_w);
    translate([-pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) single_segment_TRANSPARENT_body(total_seg_l_y_top, total_seg_w);
    translate([0, 0, 0]) single_segment_TRANSPARENT_body(total_seg_l_x, total_seg_w);
}

module layout_7segments_solid() {
    translate([0, pitch_y_top, 0]) single_segment_SOLID(total_seg_l_x, total_seg_w);
    translate([pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) single_segment_SOLID(total_seg_l_y_top, total_seg_w);
    translate([pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) single_segment_SOLID(total_seg_l_y_bot, total_seg_w);
    translate([0, -pitch_y_bot, 0]) single_segment_SOLID(total_seg_l_x, total_seg_w);
    translate([-pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) single_segment_SOLID(total_seg_l_y_bot, total_seg_w);
    translate([-pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) single_segment_SOLID(total_seg_l_y_top, total_seg_w);
    translate([0, 0, 0]) single_segment_SOLID(total_seg_l_x, total_seg_w);
}

// --- Render Selection ---
render_target = "preview"; // ["preview", "single_white", "single_transp", "single_solid", "all_white", "all_transp", "all_solid"]

if (render_target == "preview") {
    color("White") single_segment_WHITE_layer1();
    color("Cyan", 0.6) single_segment_TRANSPARENT_body();
} else if (render_target == "single_white") {
    single_segment_WHITE_layer1();
} else if (render_target == "single_transp") {
    single_segment_TRANSPARENT_body();
} else if (render_target == "single_solid") {
    single_segment_SOLID();
} else if (render_target == "all_white") {
    layout_7segments_white();
} else if (render_target == "all_transp") {
    layout_7segments_transp();
} else if (render_target == "all_solid") {
    layout_7segments_solid();
}
