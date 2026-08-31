// Endplate for Modular 7-Segment Display (v2 Design)
// Caps off the right side of a panel when you want to end the chain early.

// --- Key Parameters ---
endplate_thick = 4.0;   // Thickness of the endplate

pitch = 83;             // Center-to-center distance between parallel LED strips (83 mm)
strip_width = 12;       // Width of LED strip (12 mm)
white_wall = 1.2;       // Thickness of the white inner reflector walls
margin_y = 15;          // Extra bezel space on top and bottom sides

tunnel_depth = 12;      // Depth of the light tunnel
diffuser_thick = 1.0;   // Thickness of the white top diffuser layer
connector_thick = 4.0;  
backplate_floor = 1.5;  
backplate_thick = connector_thick + backplate_floor; // 6.0 mm total backplate thickness

// --- Calculated Dimensions ---
diffuser_w = strip_width + 2;      
total_seg_w = diffuser_w + white_wall * 2; 

digit_height = pitch * 2 + total_seg_w + margin_y * 2; // 231.4 mm
total_depth = tunnel_depth + diffuser_thick;           // 13 mm

// --- Endplate Component ---
module endplate() {
    difference() {
        // Main block (covers both frontplate and backplate side profile)
        // We orient it so the mating face is at X=0, and it extends to X = endplate_thick
        translate([endplate_thick/2, 0, (total_depth - backplate_thick)/2])
            cube([endplate_thick, digit_height, total_depth + backplate_thick], center=true);
            
        // Female receiver pocket for the 12x12 alignment protrusion
        // The protrusion sticks out 2mm, so we cut 2.5mm deep
        translate([2.5/2, 0, tunnel_depth/2]) 
            cube([2.51, 12.5, 12.5], center=true);
            
        // Holes for heat-set inserts (4.2mm diameter) to receive screws from the panel
        for (y = [digit_height/3, -digit_height/3]) {
            translate([0, y, tunnel_depth/2]) 
                rotate([0, 90, 0]) 
                cylinder(h=20, r=2.1, center=true, $fn=20);
        }
    }
}

// --- Render ---
color("DimGray") endplate();
