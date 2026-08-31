// Modular 7-Segment Display (Backplate & Frontplate Design for AMS)
// Configured for 93 mm parallel strip pitch, 105 mm total segment length with connector,
// 68 mm LED strip length, and 4.5 mm thick 90° corner connectors.

// --- Key Parameters ---
pitch = 83;             // Center-to-center distance between parallel LED strips (83 mm)
seg_length = 110;       // Total segment length including connectors on backplate (110 mm)
strip_length = 56;      // Active LED strip length (56 mm)
strip_width = 12;       // Width of LED strip (12 mm)
connector_thick = 4.0;  // Thickness / depth of the 90° corner connector (4.0 mm, 2mm below strip recess)
connector_len = (seg_length - strip_length) / 2; // 27 mm connector allowance per end
connector_width = 27;   // Width allowance for 90° solderless clip connector

tunnel_depth = 12;      // Depth of the light tunnel
diffuser_thick = 1.0;   // Thickness of the white top diffuser layer
white_wall = 1.2;       // Thickness of the white inner reflector walls
front_wall = 2.0;       // Black divider wall thickness between segment diffusers

backplate_floor = 1.5;  // Solid base floor under connector pockets
backplate_thick = connector_thick + backplate_floor; // 6.0 mm total backplate thickness
strip_recess_depth = 2.0; // Depth of LED strip recess

margin_x = 15;          // Extra bezel space on left and right sides
margin_y = 15;          // Extra bezel space on top and bottom sides

// --- Calculated Dimensions ---
diffuser_w = strip_width + 2;      // inner diffuser width
total_seg_w = diffuser_w + white_wall * 2; // outer white cup width

// Ensure a solid black wall of thickness 'front_wall' between the mitered segments
total_seg_l = pitch - front_wall * 1.4142; 
diffuser_l = total_seg_l - white_wall * 2;

digit_width = pitch + total_seg_w + margin_x * 2;      // 138.4 mm
digit_height = pitch * 2 + total_seg_w + margin_y * 2; // 231.4 mm
total_depth = tunnel_depth + diffuser_thick;           // 13 mm

// --- Shapes ---

// Pointy-end polygon for classic 7-segment display aesthetic (centered at origin)
module segment_shape(l, w, h) {
    translate([0, 0, -0.1])
    linear_extrude(height = h + 0.2)
    polygon([
        [-l/2 + w/2, -w/2],
        [l/2 - w/2, -w/2],
        [l/2, 0],
        [l/2 - w/2, w/2],
        [-l/2 + w/2, w/2],
        [-l/2, 0]
    ]);
}

// Layout helper for placing all 7 segments (A, B, C, D, E, F, G) on 93 mm pitch
module layout_7_segments() {
    // G - Middle (horizontal at y = 0)
    translate([0, 0, 0])
        children();
        
    // A - Top (horizontal at y = +pitch)
    translate([0, pitch, 0])
        children();
        
    // D - Bottom (horizontal at y = -pitch)
    translate([0, -pitch, 0])
        children();
        
    // F - Top Left (vertical at x = -pitch/2, y = +pitch/2)
    translate([-pitch/2, pitch/2, 0])
        rotate([0, 0, 90])
        children();
        
    // E - Bottom Left (vertical at x = -pitch/2, y = -pitch/2)
    translate([-pitch/2, -pitch/2, 0])
        rotate([0, 0, 90])
        children();
        
    // B - Top Right (vertical at x = +pitch/2, y = +pitch/2)
    translate([pitch/2, pitch/2, 0])
        rotate([0, 0, 90])
        children();
        
    // C - Bottom Right (vertical at x = +pitch/2, y = -pitch/2)
    translate([pitch/2, -pitch/2, 0])
        rotate([0, 0, 90])
        children();
}

// LED strip & connector channels on backplate
module led_strip_channel() {
    // Centered 68mm LED strip channel (depth = 2.0 mm)
    translate([-strip_length/2, -strip_width/2, -strip_recess_depth])
        cube([strip_length, strip_width, strip_recess_depth + 0.1]);
        
    // 18.5mm end connector channels (depth = 4.5 mm)
    translate([-seg_length/2 - 0.1, -connector_width/2, -connector_thick])
        cube([connector_len + 0.2, connector_width, connector_thick + 0.1]);
        
    translate([seg_length/2 - connector_len - 0.1, -connector_width/2, -connector_thick])
        cube([connector_len + 0.2, connector_width, connector_thick + 0.1]);
}

// --- Components ---

module frontplate_black() {
    difference() {
        union() {
            // 1. Main frame (hollowed out from the back, leaving 2mm walls and 2mm front face)
            difference() {
                translate([-digit_width/2, -digit_height/2, 0]) cube([digit_width, digit_height, total_depth]);
                translate([-digit_width/2 + 2, -digit_height/2 + 2, -1]) cube([digit_width - 4, digit_height - 4, total_depth - 1]);
            }
            
            // 2. Black walls around the segments (to prevent light bleed)
            layout_7_segments()
                segment_shape(total_seg_l + 4, total_seg_w + 4, total_depth);
                
            // 3. Screw posts for backplate
            translate([digit_width/2 - 6, digit_height/2 - 6, 0]) cylinder(h=total_depth, r=4, $fn=20);
            translate([-digit_width/2 + 6, digit_height/2 - 6, 0]) cylinder(h=total_depth, r=4, $fn=20);
            translate([digit_width/2 - 6, -digit_height/2 + 6, 0]) cylinder(h=total_depth, r=4, $fn=20);
            translate([-digit_width/2 + 6, -digit_height/2 + 6, 0]) cylinder(h=total_depth, r=4, $fn=20);
            
            // 4. Mounting bosses for side screws (right side only, as left is the first panel)
            for (y = [digit_height/3, -digit_height/3]) {
                translate([digit_width/2 - 2, y, tunnel_depth/2 + 0.5]) cube([4, 15, tunnel_depth + 1], center=true);
            }
        }
        
        // NOW cut out the actual white segment spaces
        layout_7_segments()
            translate([0, 0, -1]) // Ensure clean cut through the front face
            segment_shape(total_seg_l, total_seg_w, total_depth + 2);
            
        // Screw holes for backplate to mount (sized for standard M3 heat-set inserts, 4.2mm diameter)
        // Penetrates slightly into the 2mm front roof (Z=total_depth - 1.5) to avoid exact flush non-manifold faces
        translate([digit_width/2 - 6, digit_height/2 - 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([-digit_width/2 + 6, digit_height/2 - 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([digit_width/2 - 6, -digit_height/2 + 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([-digit_width/2 + 6, -digit_height/2 + 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        
        // Side mounting holes
        // Right side only (clearance holes for the screws, 3.2mm)
        for (y = [digit_height/3, -digit_height/3]) {
            translate([digit_width/2, y, tunnel_depth/2]) rotate([0, 90, 0]) cylinder(h=20, r=1.6, center=true, $fn=20);
        }
        
        // USB-C Power Connector Cutout (Left side, centered)
        // Designed for the snap-in panel mount Type-C connector (approx 9.5mm x 5.0mm hole)
        translate([-digit_width/2, 0, tunnel_depth/2]) 
            cube([10, 9.5, 5.0], center=true);
            

        // Connector clearance and wire routing notches (all 6 junctions)
        // Removes the bottom 3mm of plastic in a 27x27mm area to clear the L-shape connectors
        for (y = [pitch, 0, -pitch]) {
            for (x = [-pitch/2, pitch/2]) {
                translate([x, y, 0]) cube([27, 27, 6.2], center=true); // cuts from Z=0 to Z=3.1
            }
        }
        
        // Cable pass-through cutout in the middle segment
        // Allows cables from the ESP32 to cross directly into the top cavity
        translate([0, 0, 0]) cube([15, 30, 6.2], center=true);
    }
}

module frontplate_white() {
    // White diffuser cup: solid outer wall, hollow light tunnel inside with 1mm diffuser top
    difference() {
        // Outer white reflector walls + top diffuser
        layout_7_segments()
            segment_shape(total_seg_l, total_seg_w, total_depth);
            
        // Hollow light tunnel cavity, leaving 1.0mm solid diffuser face on top
        layout_7_segments()
            segment_shape(diffuser_l, diffuser_w, tunnel_depth);
            
        // Connector clearance pockets at all 6 corners (matches black frontplate)
        for (y = [pitch, 0, -pitch]) {
            for (x = [-pitch/2, pitch/2]) {
                translate([x, y, 0]) cube([27, 27, 6.2], center=true);
            }
        }
        
        // Cable pass-through cutout in the middle segment
        translate([0, 0, 0]) cube([15, 30, 6.2], center=true);
    }
}

module backplate() {
    difference() {
        union() {
            // Main flat plate
            translate([-digit_width/2, -digit_height/2, -backplate_thick])
                cube([digit_width, digit_height, backplate_thick]);
                
            // Reinforcing bosses for VESA mount inserts (sunk 1mm to avoid non-manifold Z-fighting)
            for (x = [-25, 25]) {
                for (y = [-25, 25]) {
                    translate([x, y, -1]) cylinder(h=5, r=5, $fn=30);
                }
            }
            
            // ESP32 Mini hot-glue cradle (sized for 25x20mm board)
            translate([0, -50, 0]) {
                difference() {
                    // Outer ridge (sunk 1mm into plate for perfect manifold union)
                    translate([0, 0, 0.5]) cube([29, 24, 3], center=true);
                    // Inner cavity (cuts from Z=0 upwards so it doesn't dig into the floor)
                    translate([0, 0, 2]) cube([26, 21, 4], center=true);
                }
            }
        }
            
        // Recesses for LED strips and connector channels
        layout_7_segments()
            led_strip_channel();
            
        // Deep pockets at the 6 junction corners for 90-degree connectors & solder joints (27x27)
        translate([0, 0, -connector_thick]) {
            // Middle left & right (T-junctions G/E/F and G/C/B)
            translate([-pitch/2, 0, 0]) translate([-13.5, -13.5, 0]) cube([27, 27, connector_thick + 0.1]);
            translate([pitch/2, 0, 0]) translate([-13.5, -13.5, 0]) cube([27, 27, connector_thick + 0.1]);
            
            // Top left & right (90° corners A/F and A/B)
            translate([-pitch/2, pitch, 0]) translate([-13.5, -13.5, 0]) cube([27, 27, connector_thick + 0.1]);
            translate([pitch/2, pitch, 0]) translate([-13.5, -13.5, 0]) cube([27, 27, connector_thick + 0.1]);
            
            // Bottom left & right (90° corners D/E and D/C)
            translate([-pitch/2, -pitch, 0]) translate([-13.5, -13.5, 0]) cube([27, 27, connector_thick + 0.1]);
            translate([pitch/2, -pitch, 0]) translate([-13.5, -13.5, 0]) cube([27, 27, connector_thick + 0.1]);
        }
            
        // Mounting screw holes (M3 clearance, 3.2mm) with countersink for flush heads
        for (x = [digit_width/2 - 6, -digit_width/2 + 6]) {
            for (y = [digit_height/2 - 6, -digit_height/2 + 6]) {
                translate([x, y, -backplate_thick - 0.1]) {
                    cylinder(h=backplate_thick + 0.2, r=1.6, $fn=20);       // Main shaft
                    cylinder(h=1.6, r1=3.2, r2=1.6, $fn=20);                // 90-degree countersink cone
                }
            }
        }
        
        // VESA-like mounting pattern (50x50 mm) in the center of the backplate
        // Sized for standard M3 heat-set inserts (4.2mm diameter / r=2.1)
        for (x = [-25, 25]) {
            for (y = [-25, 25]) {
                translate([x, y, -backplate_thick - 1]) cylinder(h=backplate_thick + 6, r=2.1, $fn=20);
            }
        }
        // Orientation indicator debossed into the top of the backplate
        // Mirrored along X so it reads correctly when looking at the physical back
        translate([0, 95, -backplate_thick - 0.1])
            linear_extrude(1.0)
                mirror([1, 0, 0])
                    text("↑ TOP", size=6, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    
        // Panel ID debossed into the center of the VESA mount
        // Mirrored along X so it reads correctly when looking at the physical back
        translate([0, 0, -backplate_thick - 0.1])
            linear_extrude(1.0)
                mirror([1, 0, 0])
                    text("1", size=15, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    
        // Copyright text debossed into the outside face of the backplate (Z = -backplate_thick)
        // Mirrored along X so it reads correctly when looking at the physical back of the device
        translate([0, -100, -backplate_thick - 0.1])
            linear_extrude(1.0)
                mirror([1, 0, 0])
                    text("© Designed by Geert Schepers", size=4.2, font="Liberation Sans:style=Bold", halign="center", valign="center");
    }
}

// --- Render Assembly ---
// When loaded in Bambu Studio / OrcaSlicer, these components align automatically.

color("DimGray") frontplate_black();
// Translated forward by 20mm to explode the view for preview
translate([0, 0, 20]) color("White") frontplate_white();
// Translated backwards by 20mm for preview so OpenSCAD doesn't complain about bodies perfectly touching at Z=0
translate([0, 0, -20]) color("SlateGray") backplate();
