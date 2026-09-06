// Standalone USB-C Test Coupon
// Horizontal orientation: 14.1mm horizontal width along wall, 6.0mm vertical height, 2.0mm flat vertical ends

$fn = 32;

// USB-C parameters:
// - Width (horizontal along wall): 14.1 mm
// - Height (vertical): 6.0 mm
// - Flat vertical section at left/right ends: 2.0 mm (33.3% of 6.0mm)
// - Top & bottom corner fillets: 2.0 mm radius
usb_w = 14.1;
usb_h = 6.0;
flat_h = 2.0; // 2.0 mm flat vertical height in middle of left and right ends
corner_r = (usb_h - flat_h) / 2; // 2.0 mm radius

plate_w = 40.0;
plate_h = 20.0;
plate_t = 2.0;

module usb_c_profile_2d() {
    dy = usb_w / 2 - corner_r; // 5.05 mm along Y (horizontal)
    dz = flat_h / 2;           // 1.0 mm along X (vertical in 3D)
    
    // When rotated around Y with rotate([0, 90, 0]):
    // 2D Y maps to 3D Y (horizontal along plate width)
    // 2D X maps to 3D Z (vertical along plate height)
    hull() {
        translate([-dz, -dy]) circle(r = corner_r, $fn = 24);
        translate([ dz, -dy]) circle(r = corner_r, $fn = 24);
        translate([-dz,  dy]) circle(r = corner_r, $fn = 24);
        translate([ dz,  dy]) circle(r = corner_r, $fn = 24);
    }
}

module coupon_usb_c() {
    difference() {
        // Flat rectangular plate 40 x 20 x 2 mm
        translate([0, 0, plate_h / 2])
            cube([plate_t, plate_w, plate_h], center = true);
                
        // Centered horizontal USB-C through-hole cutout (14.1mm horizontal x 6.0mm vertical)
        translate([0, 0, plate_h / 2])
            rotate([0, 90, 0])
                linear_extrude(height = plate_t + 4.0, center = true)
                    usb_c_profile_2d();
    }
}

coupon_usb_c();
