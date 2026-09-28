// Parameters (in mm)
base_size   = 50;   // Outer width/height
base_thick  = 2.0;  // Base plate thickness
code_size   = 42;   // QR code width/height
code_height = 0.8;  // Raised pattern height

module base_plate() {
    color("White")
    linear_extrude(height = base_thick)
        square([base_size, base_size], center = true);
}

module qr_pattern() {
    color("Black")
    translate([0, 0, base_thick])
        linear_extrude(height = code_height)
            resize([code_size, code_size, 0])
                import("qr.svg", center = true);
}

// Assemble
base_plate();
qr_pattern();