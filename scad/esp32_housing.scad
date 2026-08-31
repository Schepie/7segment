// ESP32-C3-Zero Mini Housing

// Board dimensions (with tolerance)
board_l = 25;
board_w = 20;
board_h = 6;
wall = 2;

// Box dimensions
box_l = board_l + wall*2;
box_w = board_w + wall*2;
box_h = board_h + wall*2;

module esp32_housing() {
    difference() {
        union() {
            // Main box
            cube([box_l, box_w, box_h]);
            
            // Mounting flange to attach to the digit's M3 hole
            translate([box_l, box_w/2 - 10/2, 0])
                cube([15, 10, box_h]);
        }
        
        // Hollow inner cavity for the board
        translate([wall, wall, wall])
            cube([board_l, board_w, board_h]);
            
        // Opening for USB-C port (front)
        translate([-5, box_w/2 - 6, wall - 0.1])
            cube([10, 12, board_h + 0.2]);
            
        // Opening for wires to the LED strip (back)
        translate([box_l - 5, box_w/2 - 6, wall - 0.1])
            cube([10, 12, board_h + 0.2]);
            
        // M3 screw hole on the mounting flange (to bolt to the display)
        translate([box_l + 7.5, box_w/2, -1])
            cylinder(h=box_h + 2, r=1.6, $fn=20);
    }
}

esp32_housing();
