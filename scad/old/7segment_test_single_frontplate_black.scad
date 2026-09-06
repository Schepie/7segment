// Single Segment Test Housing & Segment Selector
// Quick-print test coupon (~15 minutes) to test and verify snap-fit retention,
// tolerances, and surface flushness of the modular white lightguide segments.

include <7segment_modular_segment.scad>

/* [Test Coupon Visibility Controls] */
show_black_housing  = true;   // Show the black test frontplate housing
show_white_segment  = true;   // Show the white lightguide segment(s)
segment_count       = 1;      // [0:None, 1:1 Segment (In Housing), 2:2 Segments, 3:3 Segments, 4:4 Segments, 5:5 Segments, 6:6 Segments, 7:7 Segments]

/* [Preview & Alignment Settings] */
preview_mode   = "assembled"; // ["assembled": Seated flush inside housing (Z=0), "exploded": Hovering above (+20mm Z), "side_by_side": Placed beside housing flat on bed]
diffuser_thick = 0.6;         // [0.6: High Brightness (0.6mm), 0.8: Balanced (0.8mm), 1.0: Standard (1.0mm)]

module rounded_rect_plate(l, w, h, r = 3.0) {
    linear_extrude(h) {
        hull() {
            translate([-l/2 + r, -w/2 + r]) circle(r=r, $fn=24);
            translate([l/2 - r, -w/2 + r]) circle(r=r, $fn=24);
            translate([l/2 - r, w/2 - r]) circle(r=r, $fn=24);
            translate([-l/2 + r, w/2 - r]) circle(r=r, $fn=24);
        }
    }
}

module single_segment_test_housing() {
    difference() {
        // Outer housing structure (exact 2mm wall thickness matching full frontplate)
        union() {
            // Contoured segment shell (13mm height)
            segment_shape(total_seg_l_x + 4.0, total_seg_w + 4.0, total_depth);
            
            // Compact base rim (2mm high) for stability and easy grip during testing
            translate([0, 0, -0.1])
                rounded_rect_plate(total_seg_l_x + 8.0, total_seg_w + 8.0, 2.1, r=3.0);
        }
        
        // Channel cutout for the white segment insert (Z = -1 to 14 mm)
        translate([0, 0, -1])
            segment_shape(total_seg_l_x, total_seg_w, total_depth + 2);
            
        // Snap-lock detent pockets in the channel side walls
        single_segment_snap_teeth(total_seg_l_x, total_seg_w, is_subtraction = true);
    }
}

// --- Render Logic ---

// 1. Black Test Housing
if (show_black_housing) {
    color("DimGray") single_segment_test_housing();
}

// 2. White Segment(s) - Only renders the exact number selected by segment_count
if (show_white_segment && segment_count > 0) {
    if (preview_mode == "assembled") {
        // Segment 1 seated directly inside the test housing
        color("White") single_segment_lightguide(diffuser_thick);
        
        // Any additional segments (2, 3, etc.) placed beside the housing
        if (segment_count > 1) {
            for (i = [1 : segment_count - 1]) {
                translate([0, i * (total_seg_w + 8.0), 0])
                    color("White") single_segment_lightguide(diffuser_thick);
            }
        }
    } else if (preview_mode == "exploded") {
        // Segment 1 hovering 20mm above the housing channel
        translate([0, 0, 20])
            color("White") single_segment_lightguide(diffuser_thick);
            
        if (segment_count > 1) {
            for (i = [1 : segment_count - 1]) {
                translate([0, i * (total_seg_w + 8.0), 0])
                    color("White") single_segment_lightguide(diffuser_thick);
            }
        }
    } else if (preview_mode == "side_by_side") {
        // All segments placed flat on the bed alongside the housing
        for (i = [0 : segment_count - 1]) {
            translate([0, (i + 1) * (total_seg_w + 8.0), 0])
                color("White") single_segment_lightguide(diffuser_thick);
        }
    }
}
