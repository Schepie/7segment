// Spacer for Modular 7-Segment Display (v2 Design)
// Fits between digits to add configurable horizontal spacing.

// --- Key Parameters ---
spacer_width = 30;      // Width of the spacer in mm
panel_id = 2;           // Treated as a middle panel to have both left and right connectors

pitch = 83;             // Center-to-center distance between parallel LED strips (83 mm)
strip_width = 12;       // Width of LED strip (12 mm)
white_wall = 1.2;       // Thickness of the white inner reflector walls
margin_x = 15;          // Extra bezel space on left and right sides
margin_y = 15;          // Extra bezel space on top and bottom sides

tunnel_depth = 12;      // Depth of the light tunnel
diffuser_thick = 1.0;   // Thickness of the white top diffuser layer
backplate_floor = 1.5;  // Solid base floor under connector pockets
connector_thick = 4.0;  
backplate_thick = connector_thick + backplate_floor; // 6.0 mm total backplate thickness

// --- Calculated Dimensions ---
diffuser_w = strip_width + 2;      // inner diffuser width
total_seg_w = diffuser_w + white_wall * 2; // outer white cup width

// Height matches the standard digit panel height exactly
digit_height = pitch * 2 + total_seg_w + margin_y * 2; // 231.4 mm
total_depth = tunnel_depth + diffuser_thick;           // 13 mm

// --- Components ---

module spacer_frontplate() {
    difference() {
        union() {
            // 1. Main frame (hollowed out from the back, leaving 2mm walls and 2mm front face)
            difference() {
                translate([-spacer_width/2, -digit_height/2, 0]) cube([spacer_width, digit_height, total_depth]);
                translate([-spacer_width/2 + 2, -digit_height/2 + 2, -1]) cube([spacer_width - 4, digit_height - 4, total_depth - 1]);
            }
            
            // 2. Screw posts for backplate
            translate([spacer_width/2 - 6, digit_height/2 - 6, 0]) cylinder(h=total_depth, r=4, $fn=20);
            translate([-spacer_width/2 + 6, digit_height/2 - 6, 0]) cylinder(h=total_depth, r=4, $fn=20);
            translate([spacer_width/2 - 6, -digit_height/2 + 6, 0]) cylinder(h=total_depth, r=4, $fn=20);
            translate([-spacer_width/2 + 6, -digit_height/2 + 6, 0]) cylinder(h=total_depth, r=4, $fn=20);
            
            // 3. Mounting bosses for side screws
            for (y = [digit_height/3, -digit_height/3]) {
                // Right side gets mounting bosses
                translate([spacer_width/2 - 2, y, tunnel_depth/2 + 0.5]) cube([4, 15, tunnel_depth + 1], center=true);
                // Left side gets mounting bosses
                translate([-spacer_width/2 + 2, y, tunnel_depth/2 + 0.5]) cube([4, 15, tunnel_depth + 1], center=true);
            }
            
            // Inter-panel alignment protrusion (Right side, robust 12x12 male flange sticking out 2mm)
            translate([spacer_width/2, 0, tunnel_depth/2]) 
                cube([4, 12.0, 12.0], center=true);
        }
        
        // Screw holes for backplate to mount (sized for standard M3 heat-set inserts, 4.2mm diameter)
        translate([spacer_width/2 - 6, digit_height/2 - 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([-spacer_width/2 + 6, digit_height/2 - 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([spacer_width/2 - 6, -digit_height/2 + 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([-spacer_width/2 + 6, -digit_height/2 + 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        
        // Side mounting holes
        for (y = [digit_height/3, -digit_height/3]) {
            // Right side gets clearance holes for the screws (3.2mm)
            translate([spacer_width/2, y, tunnel_depth/2]) rotate([0, 90, 0]) cylinder(h=20, r=1.6, center=true, $fn=20);
            // Left side gets holes for heat-set inserts (4.2mm) to receive the screws from the previous panel
            translate([-spacer_width/2, y, tunnel_depth/2]) rotate([0, 90, 0]) cylinder(h=20, r=2.1, center=true, $fn=20);
        }
        
        // Inter-panel wire pass-through hole (Right side, outgoing wires to next digit)
        translate([spacer_width/2, 0, tunnel_depth/2]) 
            cube([10, 6.0, 6.0], center=true);
        
        // Inter-panel wire pass-through & alignment receiver (Left side, incoming wires)
        translate([-spacer_width/2, 0, tunnel_depth/2]) 
            cube([10, 12.5, 12.5], center=true);
    }
}

module spacer_backplate() {
    difference() {
        // Main flat plate
        translate([-spacer_width/2, -digit_height/2, -backplate_thick])
            cube([spacer_width, digit_height, backplate_thick]);
            
        // Mounting screw holes (M3 clearance, 3.2mm) with countersink for flush heads
        for (x = [spacer_width/2 - 6, -spacer_width/2 + 6]) {
            for (y = [digit_height/2 - 6, -digit_height/2 + 6]) {
                translate([x, y, -backplate_thick - 0.1]) {
                    cylinder(h=backplate_thick + 0.2, r=1.6, $fn=20);       // Main shaft
                    cylinder(h=1.6, r1=3.2, r2=1.6, $fn=20);                // 90-degree countersink cone
                }
            }
        }
    }
}

// --- Render Assembly ---
color("DimGray") spacer_frontplate();
// Translated backwards by 20mm for preview
translate([0, 0, -20]) color("SlateGray") spacer_backplate();
