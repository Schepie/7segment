// =========================================================================
// Quick Test-Fit Coupons: USB-C Port & Magnetic Pogo Pin Connector
// Isolated cutouts from the 7-segment housing for rapid test printing.
// =========================================================================

include <./7segment_pogo.scad>

// Ensure full display elements are hidden
show_frontplate_black = false;
show_frontplate_white = false;
show_backplate = false;
show_pogo_hardware = false;

/* [Coupon Selection] */
coupon_type = "pogo"; // ["usb", "pogo", "both", "backplate_tower", "frontplate_notch"]

// Coupon 1: Flat Rectangular 40 x 20 mm Plate (2.0mm thick) with 14.1 x 7.2 mm USB Cutout
module coupon_usb_c() {
    plate_w = 40.0;      // Exact 40.0mm width
    plate_h = 20.0;      // Exact 20.0mm height
    plate_t = 2.0;       // 2.0mm housing wall thickness
    usb_w = 14.1;        // 14.1mm USB-C width
    usb_h = 7.2;         // 7.2mm USB-C height
    
    difference() {
        // Flat rectangular plate 40 x 20 x 2 mm
        cube([plate_w, plate_h, plate_t], center = true);
                
        // Centered USB-C through-hole cutout 14.1 x 7.2 mm
        cube([usb_w, usb_h, plate_t + 1.0], center = true);
    }
}

// Coupon 2: Backplate Pogo Pin Connector Tower (with M2 screw bosses)
module coupon_pogo_pin() {
    wall_x = digit_width / 2; // Right outer wall face
    
    intersection() {
        backplate(panel_id = 1);
        
        translate([wall_x - 10.0, 0, (pogo_tower_h - backplate_thick) / 2])
            cube([24.0, 42.0, pogo_tower_h + backplate_thick + 2.0], center = true);
    }
}

// Coupon 3: Frontplate Mating Stepped Notch
module coupon_frontplate_notch() {
    wall_x = digit_width / 2;
    
    intersection() {
        frontplate_black(panel_id = 1);
        
        translate([wall_x - 6.0, 0, (total_depth - backplate_thick) / 2])
            cube([16.0, 42.0, total_depth + backplate_thick + 2.0], center = true);
    }
}

// Render Logic
if (coupon_type == "usb") {
    coupon_usb_c();
} else if (coupon_type == "pogo" || coupon_type == "backplate_tower") {
    coupon_pogo_pin();
} else if (coupon_type == "frontplate_notch") {
    coupon_frontplate_notch();
} else if (coupon_type == "both") {
    translate([-15, 0, 0]) coupon_pogo_pin();
    translate([15, 0, 0]) coupon_frontplate_notch();
}
