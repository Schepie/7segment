// =========================================================================
// Quick Test-Fit Coupons: Backplate Connector Towers & Frontplate U-Shape Notches
// Allows rapid test printing and validation of the backplate-mounted connector
// tower and the frontplate U-shaped retention collar / stepped lap-joint interface.
// =========================================================================

include <./7segment_pogo.scad>

// Ensure full display elements are hidden
show_frontplate_black = true;
show_frontplate_white = true;
show_backplate        = true;
show_pogo_hardware    = true;

/* [Coupon Selection] */
coupon_type = "both_side_by_side"; // ["backplate_pogo_tower", "frontplate_u_shape_notch", "backplate_usb_tower", "assembled_mating_test", "exploded_mating_view", "both_side_by_side", "collision_check", "clearance_check", "cutaway_view"]

use <assembly_inspector.scad>

// Coupon 1: Isolated Backplate Pogo Connector Tower (with section of base plate)
module coupon_backplate_pogo_tower() {
    wall_x = digit_width / 2; // Right outer wall
    
    intersection() {
        backplate(panel_id = 1);
        
        translate([wall_x - 10.0, 0, (pogo_tower_h - backplate_thick) / 2])
            cube([24.0, 42.0, pogo_tower_h + backplate_thick + 2.0], center = true);
    }
}

// Coupon 2: Isolated Frontplate U-Shape Stepped Retention Notch & Collar (mating cap)
module coupon_frontplate_stepped_notch() {
    wall_x = digit_width / 2;
    
    intersection() {
        frontplate_black(panel_id = 1);
        
        translate([wall_x - 6.0, 0, (total_depth - backplate_thick) / 2])
            cube([16.0, 42.0, total_depth + backplate_thick + 2.0], center = true);
    }
}

// Coupon 3: Isolated Backplate USB-C Connector Tower
module coupon_backplate_usb_tower() {
    wall_x = -digit_width / 2; // Left outer wall (Panel 1)
    
    intersection() {
        backplate(panel_id = 1);
        
        translate([wall_x + 10.0, 0, (pogo_tower_h - backplate_thick) / 2])
            cube([24.0, 42.0, pogo_tower_h + backplate_thick + 2.0], center = true);
    }
}

// 3D Pogo Connector Hardware (Right wall position)
module coupon_pogo_hardware() {
    translate([digit_width / 2 - 2.0, 0, pogo_z])
        pogo_connector_model(is_male = true, alpha = 1.0);
}

// --- Render Selection ---
if (coupon_type == "backplate_pogo_tower") {
    coupon_backplate_pogo_tower();
} else if (coupon_type == "frontplate_u_shape_notch" || coupon_type == "frontplate_stepped_notch") {
    coupon_frontplate_stepped_notch();
} else if (coupon_type == "backplate_usb_tower") {
    coupon_backplate_usb_tower();
} else if (coupon_type == "assembled_mating_test") {
    // Shows the backplate tower captured inside the frontplate U-shaped retention collar
    color("SlateGray") coupon_backplate_pogo_tower();
    color("DimGray", 0.75) coupon_frontplate_stepped_notch();
    coupon_pogo_hardware();
} else if (coupon_type == "exploded_mating_view") {
    // Exploded view along Z showing how the U-notch slides down over the tower
    color("SlateGray") coupon_backplate_pogo_tower();
    translate([0, 0, 18]) color("DimGray") coupon_frontplate_stepped_notch();
    coupon_pogo_hardware();
} else if (coupon_type == "both_side_by_side") {
    // Oriented side-by-side for quick ~15-minute 3D test print
    translate([-15, 0, 0]) color("SlateGray") coupon_backplate_pogo_tower();
    translate([15, 0, 0]) color("DimGray") coupon_frontplate_stepped_notch();
} else if (coupon_type == "collision_check") {
    // Computes boolean intersection of both parts (empty = 100% collision-free)
    show_collision() {
        coupon_backplate_pogo_tower();
        coupon_frontplate_stepped_notch();
    }
} else if (coupon_type == "clearance_check") {
    // Highlights any areas where clearance is less than 0.2mm
    check_clearance(gap = 0.2) {
        coupon_backplate_pogo_tower();
        coupon_frontplate_stepped_notch();
    }
} else if (coupon_type == "cutaway_view") {
    // Cross-section cut along Y-axis to inspect internal stepped joint interface
    cutaway(axis = "y", cut_depth = 0) {
        color("SlateGray") coupon_backplate_pogo_tower();
        color("DimGray", 0.75) coupon_frontplate_stepped_notch();
        coupon_pogo_hardware();
    }
}
