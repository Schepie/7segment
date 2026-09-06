// 3D Assembly Visualization: Backplate with Mounted LED Strips, Connectors & ESP32
use <7segment_v1.scad>

$fn = 24;

// 1. Backplate (Panel 1 with ESP32 snap cradle and cable channel)
color("#475569") // Slate Gray
    backplate(1);

// -------------------------------------------------------------
// Helper: 5050 RGB LED Package (5x5mm white body with yellow phosphor)
// -------------------------------------------------------------
module led_5050() {
    color("#f8fafc") // White plastic carrier
        cube([5, 5, 1.2], center=true);
    color("#eab308") // Yellow phosphor circular center
        translate([0, 0, 0.4])
            cylinder(h=0.5, r=1.8, center=true);
}

// -------------------------------------------------------------
// Helper: LED Strip Segment with realistic 5050 LEDs & solder pads
// -------------------------------------------------------------
module led_strip_mounted(len, num_leds=3) {
    w = 12; // strip_width
    thick = 0.5; // PCB thickness
    
    // Black Flexible PCB Substrate
    color("#1e293b")
        translate([0, 0, -thick/2])
            cube([len, w, thick], center=true);
            
    // Copper solder pads at both ends
    color("#d97706") {
        for (sx = [-len/2 + 2, len/2 - 2]) {
            for (sy = [-3.5, 0, 3.5]) {
                translate([sx, sy, 0.05])
                    cube([3, 2, 0.1], center=true);
            }
        }
    }
    
    // Evenly spaced 5050 LEDs
    spacing = len / (num_leds + 1);
    for (i = [1 : num_leds]) {
        translate([-len/2 + i * spacing, 0, 0.6])
            led_5050();
    }
}

// -------------------------------------------------------------
// Helper: 90° L-Connector / T-Junction Connector Block (25x25mm)
// -------------------------------------------------------------
module corner_connector(is_t=false) {
    color("#e2e8f0") { // Off-white plastic clip body
        difference() {
            cube([25, 25, 3.8], center=true);
            // Solderless clip snap seams
            translate([0, 0, 1.8]) cube([23, 23, 0.5], center=true);
            // Cable/strip pass slots
            translate([0, 0, 0]) cube([13, 26, 2], center=true);
            translate([0, 0, 0]) cube([26, 13, 2], center=true);
        }
    }
    // Copper metal clip contacts inside
    color("#b45309") {
        for (pos = [-4, 0, 4]) {
            translate([pos, 0, 0.2]) cube([1.5, 18, 0.5], center=true);
            translate([0, pos, 0.2]) cube([18, 1.5, 0.5], center=true);
        }
    }
}

// -------------------------------------------------------------
// 2. Mounted LED Strips (Sitting flush in the 2mm recesses at Z = -1)
// -------------------------------------------------------------
translate([0, 0, -0.7]) {
    // Horizontal Strips (56 mm)
    translate([0, 94, 0])  led_strip_mounted(56, 3); // Segment A (Top)
    translate([0, 0, 0])   led_strip_mounted(56, 3); // Segment G (Middle)
    translate([0, -94, 0]) led_strip_mounted(56, 3); // Segment D (Bottom)
    
    // Vertical Strips (Top: 56 mm)
    translate([-47.0, 47.0, 0]) rotate([0, 0, 90]) led_strip_mounted(56, 3); // Segment F (Top-Left)
    translate([47.0, 47.0, 0])  rotate([0, 0, 90]) led_strip_mounted(56, 3); // Segment B (Top-Right)
    
    // Vertical Strips (Bottom: Left is 62 mm, Right is 56 mm)
    translate([-47.0, -44.0, 0]) rotate([0, 0, 90]) led_strip_mounted(62, 4); // Segment E (Bottom-Left: 62 mm)
    translate([47.0, -47.0, 0])  rotate([0, 0, 90]) led_strip_mounted(56, 3); // Segment C (Bottom-Right: 56 mm)
}

// -------------------------------------------------------------
// 3. Corner Connectors (Sitting inside junction pockets at Z = -2)
// -------------------------------------------------------------
translate([0, 0, -1.9]) {
    // Top Corners (25x25mm)
    translate([-47.0, 94, 0]) corner_connector();
    translate([47.0, 94, 0])  corner_connector();
    
    // Middle Connectors (spanning the 38mm transition zone in the 40x26mm cavities centered at Y=0)
    translate([-47.0, 0, 0]) {
        color("#e2e8f0") difference() {
            cube([25, 38, 3.8], center=true);
            translate([0, 0, 1.8]) cube([23, 36, 0.5], center=true);
            translate([0, 0, 0]) cube([13, 39, 2], center=true);
            translate([0, 0, 0]) cube([26, 13, 2], center=true);
        }
    }
    translate([47.0, 0, 0]) {
        color("#e2e8f0") difference() {
            cube([25, 38, 3.8], center=true);
            translate([0, 0, 1.8]) cube([23, 36, 0.5], center=true);
            translate([0, 0, 0]) cube([13, 39, 2], center=true);
            translate([0, 0, 0]) cube([26, 13, 2], center=true);
        }
    }
    
    // Bottom Corners (25x25mm)
    translate([-47.0, -94, 0]) corner_connector();
    translate([47.0, -94, 0])  corner_connector();
}

// -------------------------------------------------------------
// 4. ESP32-C3 SuperMini Board (Mounted in Snap Cradle at X=0, Y=-50)
// -------------------------------------------------------------
translate([0, -50, 0.8]) {
    // Green PCB (18 x 22 x 1.6mm)
    color("#15803d") // Deep PCB green
        cube([18, 22, 1.6], center=true);
        
    // Gold contact pads along left and right sides
    color("#fbbf24") {
        for (sy = [-8 : 2.54 : 8]) {
            translate([-8, sy, 0.85]) cube([1.5, 1.5, 0.1], center=true);
            translate([8, sy, 0.85])  cube([1.5, 1.5, 0.1], center=true);
        }
    }
    
    // Silver Metal Shield Can (ESP32-C3 SoC)
    color("#cbd5e1")
        translate([0, 2, 1.6])
            cube([12, 11, 1.8], center=true);
            
    // Silver USB-C Connector Port (South end)
    color("#94a3b8")
        translate([0, -10, 1.6])
            cube([8.5, 7, 2.8], center=true);
            
    // Gold On-board Ceramic/PCB Antenna (North end)
    color("#d97706")
        translate([0, 9.5, 0.9])
            cube([10, 2, 0.3], center=true);
            
    // Status LEDs & Passives
    color("#ef4444") translate([-4, -5, 0.9]) cube([1.2, 0.8, 0.4], center=true); // Power LED (Red)
    color("#38bdf8") translate([4, -5, 0.9]) cube([1.2, 0.8, 0.4], center=true);  // Activity LED (Blue)
}

// -------------------------------------------------------------
// 5. 3-Wire Ribbon Cable: ESP32 to Middle LED Strip (Through backplate channel)
// Red = 5V, Green = Data, Black = GND
// -------------------------------------------------------------
translate([0, -25, -0.6]) {
    // Red Wire (5V)
    color("#ef4444") translate([-2.5, 0, 0]) rotate([90, 0, 0]) cylinder(h=48, r=0.8, center=true);
    // Green Wire (Data GPIO)
    color("#22c55e") translate([0, 0, 0])    rotate([90, 0, 0]) cylinder(h=48, r=0.8, center=true);
    // Black Wire (GND)
    color("#0f172a") translate([2.5, 0, 0])  rotate([90, 0, 0]) cylinder(h=48, r=0.8, center=true);
}
