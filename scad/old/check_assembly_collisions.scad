// =========================================================================
// Automated Assembly Collision & Interference Verification Suite
// Use in OpenSCAD GUI (press F5/F6) or run via Command-Line:
//   openscad -o collision.stl check_assembly_collisions.scad
// If there are NO collisions, OpenSCAD outputs an empty geometry warning.
// =========================================================================

include <7segment_pogo.scad>
include <colon_pogo.scad>
use <assembly_inspector.scad>

// Suppress default renders from included files
show_frontplate_black = false;
show_frontplate_white = false;
show_backplate        = false;
show_pogo_hardware    = false;
render_mode           = "custom";

/* [Collision Check Target] */
check_target = "all"; // ["all", "digit_front_vs_back", "digit_front_vs_diffuser", "colon_front_vs_back", "colon_front_vs_diffuser", "coupon_tower_vs_notch"]

// 1. 7-Segment Digit: Black Housing vs Backplate
module check_digit_front_vs_back() {
    show_collision() {
        frontplate_black(panel_id = 1);
        backplate(panel_id = 1);
    }
}

// 2. 7-Segment Digit: Black Housing vs White Diffuser
module check_digit_front_vs_diffuser() {
    show_collision() {
        frontplate_black(panel_id = 1);
        frontplate_white();
    }
}

// 3. Colon Module: Black Housing vs Backplate
module check_colon_front_vs_back() {
    show_collision() {
        colon_frontplate_black();
        colon_backplate();
    }
}

// 4. Colon Module: Black Housing vs White Diffuser/Lightguides
module check_colon_front_vs_diffuser() {
    show_collision() {
        colon_frontplate_black();
        colon_frontplate_white();
    }
}

// 5. Quick Coupon: Backplate Tower vs Frontplate U-Notch
module check_coupon_tower_vs_notch() {
    wall_x = digit_width / 2;
    
    show_collision() {
        // Child 0: Backplate Tower
        intersection() {
            backplate(panel_id = 1);
            translate([wall_x - 10.0, 0, (pogo_tower_h - backplate_thick) / 2])
                cube([24.0, 42.0, pogo_tower_h + backplate_thick + 2.0], center = true);
        }
        
        // Child 1: Frontplate Notch
        intersection() {
            frontplate_black(panel_id = 1);
            translate([wall_x - 6.0, 0, (total_depth - backplate_thick) / 2])
                cube([16.0, 42.0, total_depth + backplate_thick + 2.0], center = true);
        }
    }
}

// --- Execution ---
if (check_target == "all") {
    // Offset each test along X for easy visual inspection of all pairs at once
    translate([-160, 0, 0]) check_digit_front_vs_back();
    translate([-80, 0, 0])  check_digit_front_vs_diffuser();
    translate([0, 0, 0])    check_colon_front_vs_back();
    translate([80, 0, 0])   check_colon_front_vs_diffuser();
    translate([160, 0, 0])  check_coupon_tower_vs_notch();
} else if (check_target == "digit_front_vs_back") {
    check_digit_front_vs_back();
} else if (check_target == "digit_front_vs_diffuser") {
    check_digit_front_vs_diffuser();
} else if (check_target == "colon_front_vs_back") {
    check_colon_front_vs_back();
} else if (check_target == "colon_front_vs_diffuser") {
    check_colon_front_vs_diffuser();
} else if (check_target == "coupon_tower_vs_notch") {
    check_coupon_tower_vs_notch();
}
