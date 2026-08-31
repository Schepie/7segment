// Modular Replaceable 7-Segment Lightguide / Diffuser System
// Each segment is an independent, replaceable part with snap-fit retention tabs.
// Fits seamlessly into the frontplate housing just like the modular colon lightguides.

/* [Diffuser & Geometry Parameters] */
diffuser_thick = 0.6;          // [0.6: High Brightness (0.6mm), 0.8: Balanced (0.8mm), 1.0: Standard (1.0mm)]
enable_segment_snaps = true;   // Set to true for snap-lock retention tabs
segment_clearance = 0.15;      // 0.15mm perimeter clearance for smooth slide-in fit without binding

total_depth = 13.0;            // Matches frontplate housing depth (13.0 mm)
tunnel_depth = total_depth - diffuser_thick; // Inner cavity depth (12.4mm for 0.6, 12.2mm for 0.8)

/* [Segment Visibility & Selection] */
// Select how many or which white segments to display
segment_display_mode = "all";  // ["all": Show All 7 Segments, "count": Show by Count (1 to 7), "custom": Custom Checkbox Selection, "none": Hide All]
visible_segment_count = 1;     // [1:7] Number of segments to show when mode is "count" (1=Top A, 2=A+B, 3=A+B+C, etc.)

/* [Custom Segment Toggles (Active when mode is "custom")] */
show_seg_a = true; // Segment A (Top Horizontal)
show_seg_b = true; // Segment B (Top-Right Vertical)
show_seg_c = true; // Segment C (Bottom-Right Vertical)
show_seg_d = true; // Segment D (Bottom Horizontal)
show_seg_e = true; // Segment E (Bottom-Left Vertical)
show_seg_f = true; // Segment F (Top-Left Vertical)
show_seg_g = true; // Segment G (Middle Horizontal)

// --- Segment Dimensions (matching 7segment_pogo / 7segment_v1) ---
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

// Visibility evaluation function
function is_seg_active(idx, custom_val) =
    (segment_display_mode == "all") ? true :
    (segment_display_mode == "none") ? false :
    (segment_display_mode == "count") ? (idx <= visible_segment_count) :
    custom_val;

// --- Shapes & Geometry Helpers ---
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
    translate([0, 0, -0.1])
    linear_extrude(height = h + 0.2)
    segment_shape_2d(l, w);
}

// Layout helper for 7-segment digit positions
module layout_horiz(is_top=false, is_bot=false) {
    if (is_top) {
        translate([0, pitch_y_top, 0]) children();
    } else if (is_bot) {
        translate([0, -pitch_y_bot, 0]) children();
    } else {
        translate([0, 0, 0]) children();
    }
}

// --- Snap-Lock Teeth & Compliance Flex Geometry ---
// Symmetrical snap tabs along the upper and lower straight walls of the segment
module single_segment_snap_teeth(l = total_seg_l_x, w = total_seg_w, is_subtraction = false) {
    if (enable_segment_snaps) {
        tooth_w = 3.5;         // Width along segment length
        tooth_h = 2.2;         // Height along Z
        tooth_reach = is_subtraction ? 0.65 : 0.45; // Outward latching reach
        z_pos = 3.0;           // Positioned in lower third above LED plane
        
        // 2 snap teeth along upper wall (+Y) and 2 along lower wall (-Y)
        for (side = [-1, 1]) {
            for (x_pos = [-22.0, 22.0]) {
                translate([x_pos, side * (w/2 - (is_subtraction ? 0 : segment_clearance)), z_pos]) {
                    if (is_subtraction) {
                        // Pocket detent cutout extending cleanly into the channel void
                        translate([0, side * (tooth_reach - 0.5), 0])
                            cube([tooth_w + 0.5, 1.0 + tooth_reach * 2, tooth_h + 0.4], center=true);
                    } else {
                        // Outward latching tooth with 45° lead-in chamfers for push-in assembly
                        rotate([side > 0 ? 0 : 180, 0, 0])
                            translate([0, 0, 0])
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
}

// Vertical flex relief slits flanking each snap tooth to allow elastic deflection upon insertion
module single_segment_flex_slits(w = total_seg_w) {
    if (enable_segment_snaps) {
        slit_w = 0.8;
        slit_l = 3.5;
        slit_h = 5.5;
        
        for (side = [-1, 1]) {
            for (x_center = [-22.0, 22.0]) {
                for (dx = [-2.5, 2.5]) {
                    translate([x_center + dx, side * (w/2 - segment_clearance), slit_h/2 - 0.1])
                        cube([slit_w, slit_l, slit_h + 0.2], center=true);
                }
            }
        }
    }
}

// --- Single Standalone Replaceable Segment Module ---
module single_segment_lightguide(d_thick = diffuser_thick, l = total_seg_l_x, w = total_seg_w) {
    t_depth = total_depth - d_thick;
    eff_w = w - segment_clearance * 2;
    eff_l = l - segment_clearance * 2;
    inner_w = diffuser_w;
    inner_l = l - white_wall * 2;
    
    difference() {
        union() {
            // Outer white reflector walls + top solid diffuser face
            segment_shape(eff_l, eff_w, total_depth);
            
            // Outward snap-lock teeth on long sides
            single_segment_snap_teeth(l, w, is_subtraction = false);
        }
        
        // Hollow light tunnel cavity from bottom up to (total_depth - d_thick)
        translate([0, 0, -0.1])
            segment_shape(inner_l, inner_w, t_depth + 0.1);
            
        // Compliance flex slits allowing snap tabs to deflect during insertion
        single_segment_flex_slits(w);
    }
}

// --- Multi-Segment Layouts ---

// 1. Modular 7-Segment Assembly (Positioned in standard 7-segment digit arrangement with visibility controls)
module modular_7segment_assembled(d_thick = diffuser_thick) {
    // Seg A: Top Horizontal (Index 1)
    if (is_seg_active(1, show_seg_a)) {
        layout_horiz(true, false) single_segment_lightguide(d_thick, total_seg_l_x, total_seg_w);
    }
    
    // Seg B: Top-Right Vertical (Index 2)
    if (is_seg_active(2, show_seg_b)) {
        translate([pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) single_segment_lightguide(d_thick, total_seg_l_y_top, total_seg_w);
    }
    
    // Seg C: Bottom-Right Vertical (Index 3)
    if (is_seg_active(3, show_seg_c)) {
        translate([pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) single_segment_lightguide(d_thick, total_seg_l_y_bot, total_seg_w);
    }
    
    // Seg D: Bottom Horizontal (Index 4)
    if (is_seg_active(4, show_seg_d)) {
        layout_horiz(false, true) single_segment_lightguide(d_thick, total_seg_l_x, total_seg_w);
    }
    
    // Seg E: Bottom-Left Vertical (Index 5)
    if (is_seg_active(5, show_seg_e)) {
        translate([-pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) single_segment_lightguide(d_thick, total_seg_l_y_bot, total_seg_w);
    }
    
    // Seg F: Top-Left Vertical (Index 6)
    if (is_seg_active(6, show_seg_f)) {
        translate([-pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) single_segment_lightguide(d_thick, total_seg_l_y_top, total_seg_w);
    }
    
    // Seg G: Middle Horizontal (Index 7)
    if (is_seg_active(7, show_seg_g)) {
        layout_horiz(false, false) single_segment_lightguide(d_thick, total_seg_l_x, total_seg_w);
    }
}

// 2. Selectable count batch print plate laid flat on print bed
module modular_7segment_print_plate(d_thick = diffuser_thick) {
    actual_count = (segment_display_mode == "count") ? visible_segment_count : 7;
    spacing_y = total_seg_w + 5.0; // 21.4mm spacing between segments
    for (i = [0 : actual_count - 1]) {
        translate([0, (i - (actual_count - 1) / 2) * spacing_y, 0])
            single_segment_lightguide(d_thick, total_seg_l_x, total_seg_w);
    }
}

// Helper to subtract snap-lock detent pockets from black housing
module all_segments_snap_subtractions() {
    layout_horiz(true, false) single_segment_snap_teeth(total_seg_l_x, total_seg_w, is_subtraction = true);
    translate([pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) single_segment_snap_teeth(total_seg_l_y_top, total_seg_w, is_subtraction = true);
    translate([pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) single_segment_snap_teeth(total_seg_l_y_bot, total_seg_w, is_subtraction = true);
    layout_horiz(false, true) single_segment_snap_teeth(total_seg_l_x, total_seg_w, is_subtraction = true);
    translate([-pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) single_segment_snap_teeth(total_seg_l_y_bot, total_seg_w, is_subtraction = true);
    translate([-pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) single_segment_snap_teeth(total_seg_l_y_top, total_seg_w, is_subtraction = true);
    layout_horiz(false, false) single_segment_snap_teeth(total_seg_l_x, total_seg_w, is_subtraction = true);
}

// --- Default Render Selection ---
/* [Standalone Preview Mode] */
enable_standalone_preview = false; // Set to true when opening this file directly to preview
render_mode = "plate"; // ["assembled": In 7-Segment Digit Layout, "plate": Flat on Print Bed Batch, "single": 1 Single Segment]

if (enable_standalone_preview) {
    if (render_mode == "plate") {
        color("White") modular_7segment_print_plate(diffuser_thick);
    } else if (render_mode == "single") {
        color("White") single_segment_lightguide(diffuser_thick);
    } else if (render_mode == "assembled") {
        color("White") modular_7segment_assembled(diffuser_thick);
    }
}
