// Padel Court Mesh Clamp for 7-Segment Display
// Designed specifically for standard 50x50mm electro-welded wire mesh
// Interfaces with the 50x50 VESA pattern on the display backplate

/*
ASSEMBLY INSTRUCTIONS:
1. Insert two M5 hex nuts into the hex traps on the back of the 'front_bracket'.
2. Screw the 'front_bracket' to the display's VESA holes using four M3x10mm screws.
   (The display will trap the M5 nuts so they can never fall out).
3. Place the display against the padel court mesh so the wire sits in the cross grooves.
4. From behind the mesh, place the 'back_plate' and secure it into the trapped M5 nuts 
   using two M5x20mm bolts. 
*/

// --- Parameters ---
mesh_wire_diameter = 5.0; // Wire thickness of the padel mesh (typically 4mm to 5mm)
vesa_spacing = 50.0;

bracket_size = 65.0;
bracket_thick = 8.0;

backplate_width = 20.0;
backplate_length = 60.0;
backplate_thick = 8.0;

clamp_bolt_spacing = 30.0; // Distance between the two M5 clamping bolts (15mm from center)

$fn = 40;

module front_bracket() {
    difference() {
        // Main block
        translate([0, 0, bracket_thick/2]) 
            cube([bracket_size, bracket_size, bracket_thick], center=true);
            
        // 1. VESA mounting holes (M3)
        // Countersunk/counterbored so the M3 screw heads sit below the mesh surface
        for(x = [-vesa_spacing/2, vesa_spacing/2]) {
            for(y = [-vesa_spacing/2, vesa_spacing/2]) {
                translate([x, y, -1]) {
                    // M3 clearance shaft
                    cylinder(h=bracket_thick + 2, r=1.7);
                    // Counterbore for M3 socket head (head dia 5.5mm -> r=3.0)
                    translate([0, 0, bracket_thick - 3.5 + 1]) 
                        cylinder(h=4.0, r=3.0);
                }
            }
        }
        
        // 2. Alignment grooves for the padel mesh wires (Cross shape)
        // Helps the clamp bite onto the mesh intersection perfectly
        translate([0, 0, bracket_thick]) 
            rotate([0, 90, 0]) 
                cylinder(h=bracket_size + 2, r=mesh_wire_diameter/2 + 0.5, center=true);
                
        translate([0, 0, bracket_thick]) 
            rotate([-90, 0, 0]) 
                cylinder(h=bracket_size + 2, r=mesh_wire_diameter/2 + 0.5, center=true);
                
        // 3. Clamping holes and M5 Nut traps
        // Nuts are inserted from the display side (Z=0) and trapped when mounted
        for(y = [-clamp_bolt_spacing/2, clamp_bolt_spacing/2]) {
            translate([0, y, -1]) {
                // M5 clearance shaft
                cylinder(h=bracket_thick + 2, r=2.7);
                // M5 hex nut trap (width across flats ~8.1mm -> outer radius = 8.2 / sqrt(3) ≈ 4.8)
                cylinder(h=4.5 + 1, r=4.8, $fn=6);
            }
        }
    }
}

module back_plate() {
    difference() {
        // Main clamp bar
        translate([0, 0, backplate_thick/2]) 
            cube([backplate_width, backplate_length, backplate_thick], center=true);
            
        // 1. Clamping holes for M5 bolts
        for(y = [-clamp_bolt_spacing/2, clamp_bolt_spacing/2]) {
            translate([0, y, -1]) {
                // M5 clearance shaft
                cylinder(h=backplate_thick + 2, r=2.7);
                // Counterbore for M5 socket head (head dia 8.5mm -> r=4.5)
                translate([0, 0, backplate_thick - 3.5 + 1]) 
                    cylinder(h=4.0, r=4.5);
            }
        }
        
        // 2. Groove to grip the horizontal mesh wire
        translate([0, 0, 0]) 
            rotate([0, 90, 0]) 
                cylinder(h=backplate_width + 2, r=mesh_wire_diameter/2 + 0.5, center=true);
    }
}

// --- Render Layout ---
// Arranged for easy 3D printing (both parts lay flat on the bed)

translate([-35, 0, 0]) {
    color("DimGray") front_bracket();
    translate([0, -45, 0]) 
        text("Front Bracket", size=4, halign="center");
}

translate([30, 0, 0]) {
    color("SlateGray") back_plate();
    translate([0, -45, 0]) 
        text("Back Plate", size=4, halign="center");
}
