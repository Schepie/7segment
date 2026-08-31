// =========================================================================
// 7-Segment Dual-Material Diffuser (0.8 mm Total Thickness)
// Layer 1 (0.0 to 0.2 mm) = White Filament (100% surface diffusion)
// Layer 2 (0.2 to 0.8 mm) = Transparent / Clear Filament (Structural core)
// =========================================================================

// --- Configuration Parameters ---
pitch_x         = 92.0;   // Horizontal pitch between vertical columns
pitch_y_top     = 92.0;   // Pitch between middle & top horizontal segments
pitch_y_bot     = 92.0;   // Pitch between middle & bottom horizontal segments

total_seg_w     = 18.0;   // Segment width (18mm)
total_seg_l_x   = 104.0;  // Horizontal segment length (A, D, G)
total_seg_l_y_top = 104.0;// Top vertical segment length (B, F)
total_seg_l_y_bot = 117.0;// Bottom vertical segment length (C, E)

layer1_thick    = 0.2;    // First layer: 0.20 mm White
total_thick     = 0.8;    // Total thickness: 0.80 mm (0.6mm Transparent backing)

// --- Render Selection ---
render_part = 0; // 0: Dual-color assembly preview
                 // 1: White layer only (export STL)
                 // 2: Transparent layer only (export STL)
                 // 3: Single solid 0.8mm piece (export STL for slicer layer-pause)

// --- Segment Polygon Generator ---
module segment_shape(l, w, h) {
    linear_extrude(height = h)
    polygon([
        [-l/2, 0],
        [-l/2 + w/2, -w/2],
        [l/2 - w/2, -w/2],
        [l/2, 0],
        [l/2 - w/2, w/2],
        [-l/2 + w/2, w/2]
    ]);
}

// --- 7-Segment Layout Helpers ---
module layout_7segments(h) {
    // 1. Segment A (Top)
    translate([0, pitch_y_top, 0]) 
        segment_shape(total_seg_l_x, total_seg_w, h);

    // 2. Segment B (Top-Right)
    translate([pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) 
        segment_shape(total_seg_l_y_top, total_seg_w, h);

    // 3. Segment C (Bottom-Right)
    translate([pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) 
        segment_shape(total_seg_l_y_bot, total_seg_w, h);

    // 4. Segment D (Bottom)
    translate([0, -pitch_y_bot, 0]) 
        segment_shape(total_seg_l_x, total_seg_w, h);

    // 5. Segment E (Bottom-Left)
    translate([-pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) 
        segment_shape(total_seg_l_y_bot, total_seg_w, h);

    // 6. Segment F (Top-Left)
    translate([-pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) 
        segment_shape(total_seg_l_y_top, total_seg_w, h);

    // 7. Segment G (Middle)
    translate([0, 0, 0]) 
        segment_shape(total_seg_l_x, total_seg_w, h);
}

// --- White Layer (0.0 to 0.2 mm) ---
module diffuser_white() {
    color("White")
        layout_7segments(layer1_thick);
}

// --- Transparent Layer (0.2 to 0.8 mm) ---
module diffuser_transparent() {
    color("Cyan", 0.5) // Transparent cyan preview
        translate([0, 0, layer1_thick])
            layout_7segments(total_thick - layer1_thick);
}

// --- Assembly Rendering ---
if (render_part == 0) {
    diffuser_white();
    diffuser_transparent();
} else if (render_part == 1) {
    diffuser_white();
} else if (render_part == 2) {
    diffuser_transparent();
} else if (render_part == 3) {
    color("GhostWhite")
        layout_7segments(total_thick);
}
