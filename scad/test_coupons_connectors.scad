// =========================================================================
// Quick Test-Fit Coupons: USB-C Port & Magnetic Pogo Pin Connector
// Isolated cutouts from the 7-segment housing for rapid test printing.
// =========================================================================

include <7segment_pogo.scad>

// Ensure full display elements are hidden
show_frontplate_black = false;
show_frontplate_white = false;
show_backplate = false;
show_pogo_hardware = false;

/* [Coupon Selection] */
coupon_type = "both"; // ["usb", "pogo", "both"]

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

// Coupon 2: 4-Pin Magnetic Pogo Pin Connector Wall Cutout (with M2 screw bosses)
module coupon_pogo_pin() {
    wall_x = digit_width / 2; // +69.2 mm (Right wall with pogo transmitter mount)
    
    translate([-wall_x + 4.0, 0, 0]) {
        intersection() {
            // Full Panel 1 housing with pogo mounting features
            frontplate_black(panel_id = 1);
            
            // Tight bounding box around the Pogo pocket & bosses (40mm long x 16mm deep x 13mm high)
            translate([wall_x - 6.0, 0, total_depth / 2])
                cube([16.0, 40.0, total_depth + 1.0], center=true);
        }
    }
}

// Render Logic
if (coupon_type == "usb") {
    coupon_usb_c();
} else if (coupon_type == "pogo") {
    coupon_pogo_pin();
} else if (coupon_type == "both") {
    translate([-14, 0, 0]) coupon_usb_c();
    translate([14, 0, 0]) coupon_pogo_pin();
}
