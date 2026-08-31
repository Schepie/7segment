// 7-Segment Display Digit Housing (Monolithic Design)
// Configured for 93 mm parallel strip pitch, 105 mm total segment length with connector,
// 68 mm LED strip length, and 4.5 mm thick 90° corner connectors.

pitch = 93;
seg_length = 105;
strip_length = 68;
strip_width = 11;
strip_depth = 6;
wall = 2;
base_thickness = 2;

// Calculated dimensions
diffuser_w = strip_width + 2;
digit_width = pitch + diffuser_w + wall * 4;
digit_height = pitch * 2 + diffuser_w + wall * 4;
depth = strip_depth + base_thickness;

module segment() {
    translate([-seg_length/2, -diffuser_w/2, -0.1])
    cube([seg_length, diffuser_w, strip_depth + 0.2]);
}

module digit_body() {
    difference() {
        // Main block
        translate([-digit_width/2, -digit_height/2, 0])
            cube([digit_width, digit_height, depth]);
        
        // Segments cutout
        // G - Middle
        translate([0, 0, base_thickness])
            segment();
            
        // A - Top
        translate([0, pitch, base_thickness])
            segment();
            
        // D - Bottom
        translate([0, -pitch, base_thickness])
            segment();
            
        // F - Top Left
        translate([-pitch/2, pitch/2, base_thickness])
            rotate([0, 0, 90]) segment();
            
        // E - Bottom Left
        translate([-pitch/2, -pitch/2, base_thickness])
            rotate([0, 0, 90]) segment();
            
        // B - Top Right
        translate([pitch/2, pitch/2, base_thickness])
            rotate([0, 0, 90]) segment();
            
        // C - Bottom Right
        translate([pitch/2, -pitch/2, base_thickness])
            rotate([0, 0, 90]) segment();
            
        // Corner and T-junction connector pockets (4.5mm deep)
        translate([0, 0, base_thickness]) {
            // Middle left & right
            translate([-pitch/2, 0, 0]) translate([-15, -18, 0]) cube([30, 36, strip_depth + 0.1]);
            translate([pitch/2, 0, 0]) translate([-15, -18, 0]) cube([30, 36, strip_depth + 0.1]);
            
            // Top left & right
            translate([-pitch/2, pitch, 0]) translate([-15, -15, 0]) cube([30, 30, strip_depth + 0.1]);
            translate([pitch/2, pitch, 0]) translate([-15, -15, 0]) cube([30, 30, strip_depth + 0.1]);
            
            // Bottom left & right
            translate([-pitch/2, -pitch, 0]) translate([-15, -15, 0]) cube([30, 30, strip_depth + 0.1]);
            translate([pitch/2, -pitch, 0]) translate([-15, -15, 0]) cube([30, 30, strip_depth + 0.1]);
        }
        
        // Wire pass-through to next digit
        translate([digit_width/2, 0, base_thickness + strip_depth/2]) cube([10, 15, strip_depth + 1], center=true);
        translate([-digit_width/2, 0, base_thickness + strip_depth/2]) cube([10, 15, strip_depth + 1], center=true);
        
        // Screw holes for joining (M3 clearance holes = 3.2mm diameter)
        translate([digit_width/2, digit_height/3, depth/2]) rotate([0, 90, 0]) cylinder(h=10, r=1.6, center=true, $fn=20);
        translate([digit_width/2, -digit_height/3, depth/2]) rotate([0, 90, 0]) cylinder(h=10, r=1.6, center=true, $fn=20);
        translate([-digit_width/2, digit_height/3, depth/2]) rotate([0, 90, 0]) cylinder(h=10, r=1.6, center=true, $fn=20);
        translate([-digit_width/2, -digit_height/3, depth/2]) rotate([0, 90, 0]) cylinder(h=10, r=1.6, center=true, $fn=20);
    }
}

// Render the body
digit_body();
