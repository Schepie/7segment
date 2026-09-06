// Padel Court Mesh Hook for 7-Segment Display
// Designed to hang perfectly on standard 50x50mm electro-welded wire mesh
// Interfaces securely with the 50x50 VESA pattern on the display backplate

/*
ASSEMBLY INSTRUCTIONS:
1. Screw this hook bracket to the display's VESA holes using four M3x10mm screws.
   (The screw heads will sink into the counterbores so they don't scratch the mesh).
2. Simply push the display onto a horizontal wire of the padel court mesh!
   The hook has an angled entry guide and is designed to snap firmly over a 5mm wire.
*/

$fn = 40;

module hook_profile_2d() {
    difference() {
        // Hook outer block with angled entry chamfer
        polygon([
            [0, 5],
            [15, 5],      // Extends upwards for strength
            [15, 15],     // Top thickness
            [-7, 15],     // Hook lip extends forwards over the wire
            [-7, 12.2],   // Outer corner of the lip
            [-5, 10.2],   // Angled chamfer guiding the wire into the slot
            [0, 10.2]     // Inside edge of the lip
        ]);
        
        // Subtract a perfectly round pocket for the 5mm wire (r=2.6mm for a nice snug fit)
        // This is perfectly centered so the display hangs straight down.
        translate([0, 7.6]) circle(r=2.6);
        
        // Subtract the straight entry slot so the wire can slide into the pocket
        translate([-7.1, 5]) square([7.1, 5.2]);
    }
}

module padel_hook() {
    difference() {
        union() {
            // Main base plate (65x65mm wide to accommodate the 50x50 VESA pattern)
            translate([0, 0, 2.5]) cube([65, 65, 5], center=true);
            
            // Extrude the 2D hook profile to be exactly 40mm wide
            // This guarantees it fits comfortably between the 50mm vertical wires of the mesh!
            translate([-20, 0, 0])
                rotate([90, 0, 90])
                    linear_extrude(height = 40)
                        hook_profile_2d();
        }
        
        // 1. VESA mounting holes (M3)
        // Countersunk/counterbored so the M3 screw heads sit below the surface
        for(x = [-25, 25]) {
            for(y = [-25, 25]) {
                translate([x, y, -1]) {
                    // M3 clearance shaft
                    cylinder(h=10, r=1.7);
                    // Counterbore for M3 socket head (head dia 5.5mm -> r=3.0)
                    translate([0, 0, 5 - 3.5 + 1]) 
                        cylinder(h=4.0, r=3.0);
                }
            }
        }
    }
}

// Render the hook
color("SlateGray") padel_hook();
