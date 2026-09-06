// ==============================================================================
// Single White Lightguide / Diffuser Segment (Frontplate White)
// For Modular 7-Segment Clock / Scoreboard Display
// ==============================================================================
//
// Features:
// - Standalone 1-color white segment designed for rapid test-printing or replacement.
// - Print Orientation: Flat front diffuser face rests directly on the build plate (Z = 0)
//   for a flawless textured/smooth finish and ZERO supports required!
// - Hollow internal cavity channels and reflects LED light directly forward.
// - Snap-fit retention tabs with compliance flex slits lock securely into the
//   frontplate housing channels.
// - Compatible with all 7 segment positions (A, B, C, D, E, F, G) on the digit
//   (pitch_x = pitch_y_top = pitch_y_bot = 92.0 mm).
// ==============================================================================

/* [Configuration] */
part = 1; // [1:"single - 1 Segment (with snap tabs, print orientation)", 2:"single_nosnaps - 1 Segment (smooth friction fit, no snaps)", 3:"digit_set - Full set of 7 segments laid out flat on bed", 4:"cutaway - Cross-section preview"]

// Front diffuser face thickness (mm)
diffuser_thick = 0.6; // [0.4:0.1:1.2] (0.6mm = high brightness, 0.8mm = balanced diffusion)

// Snap-fit retention teeth
enable_snaps = true;

// Clearance gap around perimeter for slide-in fit (mm)
segment_clearance = 0.15; // [0.05:0.05:0.30]

/* [Segment Dimensions (matching 7segment_pogo.scad)] */
pitch_x       = 92.0;  // 92mm pitch
pitch_y_top   = 92.0;
pitch_y_bot   = 92.0;
strip_width   = 12.0;  // WS2812 LED strip width (12 mm)
white_wall    = 1.2;   // Reflector wall thickness (1.2 mm)
front_wall    = 2.0;   // Black divider wall between segments (2.0 mm)
total_depth   = 13.0;  // Total frontplate housing depth (13.0 mm)

/* [Derived Calculations] */
diffuser_w    = strip_width + 2;                   // 14.0 mm inner channel
total_seg_w   = diffuser_w + white_wall * 2;      // 16.4 mm outer width
total_seg_l   = pitch_x - front_wall * 1.4142;    // 89.17 mm outer length
diffuser_l    = total_seg_l - white_wall * 2;     // 86.77 mm inner length

eff_w         = total_seg_w - segment_clearance * 2; // 16.10 mm
eff_l         = total_seg_l - segment_clearance * 2; // 88.87 mm

$fn = 40;

// ==============================================================================
// 2D & 3D GEOMETRY MODULES
// ==============================================================================

// Classic mitered 45-degree pointy 7-segment polygon
module segment_polygon_2d(l, w) {
    polygon([
        [-l/2 + w/2, -w/2],
        [ l/2 - w/2, -w/2],
        [ l/2,        0   ],
        [ l/2 - w/2,  w/2],
        [-l/2 + w/2,  w/2],
        [-l/2,        0   ]
    ]);
}

module segment_prism(l, w, h) {
    linear_extrude(height = h)
        segment_polygon_2d(l, w);
}

// Snap teeth positioned in print orientation (Z = 0 is front face on bed)
module snap_teeth_print_orient(l = total_seg_l, w = total_seg_w) {
    tooth_w     = 3.5;
    tooth_h     = 2.2;
    tooth_reach = 0.45;
    // Positioned 3.0mm from the open rear rim (10.0mm above the bed)
    z_pos       = total_depth - 3.0;
    
    for (side = [-1, 1]) {
        for (x_pos = [-22.0, 22.0]) {
            translate([x_pos, side * (w/2 - segment_clearance), z_pos]) {
                rotate([side > 0 ? 0 : 180, 0, 0])
                    rotate([0, 90, 0])
                        linear_extrude(tooth_w, center=true)
                            polygon([
                                [-tooth_h/2, -0.4],
                                [-tooth_h/4, tooth_reach],
                                [ tooth_h/4, tooth_reach],
                                [ tooth_h/2, -0.4]
                            ]);
            }
        }
    }
}

// Flex compliance slits flanking each snap tooth
module flex_slits_print_orient(w = total_seg_w) {
    slit_w   = 0.8;
    slit_l   = 3.5;
    slit_h   = 5.5;
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

// Single Segment Model (Print Orientation: Front face at Z = 0)
module single_segment_white(d_thick = diffuser_thick, snaps = enable_snaps) {
    difference() {
        union() {
            // Solid outer prism (Z = 0 to 13.0 mm)
            segment_prism(eff_l, eff_w, total_depth);
            
            // Outward snap-fit latch teeth
            if (snaps) {
                snap_teeth_print_orient(total_seg_l, total_seg_w);
            }
        }
        
        // Hollow light tunnel: leaves solid d_thick front face at Z = [0, d_thick]
        // Hollow cavity extends from Z = d_thick to the open rear at Z = 13.0+ mm
        translate([0, 0, d_thick])
            segment_prism(diffuser_l, diffuser_w, total_depth - d_thick + 1.0);
            
        // Compliance flex slits for snap teeth
        if (snaps) {
            flex_slits_print_orient(total_seg_w);
        }
    }
}

// 7 Segments Laid Out Flat on Build Plate
module digit_set_segments_print_orient(spacing_y = 20.0) {
    for (i = [0:6]) {
        translate([0, (i - 3) * spacing_y, 0])
            single_segment_white(diffuser_thick, enable_snaps);
    }
}

// Cutaway preview (cross-section along length to verify diffuser thickness)
module single_segment_cutaway() {
    difference() {
        single_segment_white(diffuser_thick, enable_snaps);
        translate([0, 15, -1])
            cube([eff_l + 10, 30, total_depth + 2], center = true);
    }
}

// ==============================================================================
// TOP-LEVEL RENDER SELECTION
// ==============================================================================
if (part == 1 || part == "single") {
    // 1 Segment with snap tabs (print-ready)
    color("White")
        single_segment_white(diffuser_thick, snaps = true);
} else if (part == 2 || part == "single_nosnaps") {
    // 1 Segment without snap tabs (friction fit)
    color("White")
        single_segment_white(diffuser_thick, snaps = false);
} else if (part == 3 || part == "digit_set") {
    // Full digit set of 7 segments flat on bed
    color("White")
        digit_set_segments_print_orient(spacing_y = 22.0);
} else if (part == 4 || part == "cutaway") {
    // Longitudinal cross-section view
    color("White")
        single_segment_cutaway();
}
