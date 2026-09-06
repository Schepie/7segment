// ==============================================================================
// Detailed Visualization: 4-Pin Magnetic Pogo Pin Connector in Modular Housing
// ==============================================================================
// This file provides detailed, isolated views of the pogo pin connector mounted
// inside the 3D-printed housing, including the mounting pocket, bosses, wiring,
// sense resistor, and mated seam interface.
//
// Select a view mode below (or pass via command line -D mode=\"...\"):
//   "inside"   - Interior view showing mounting ears, bosses, wires & sense pocket
//   "outside"  - Exterior view showing the flush mating face, gold pins & magnets
//   "mating"   - Two adjacent panels mating across the seam (Male <-> Female)
//   "cutaway"  - Cross-section cutaway showing internal wall profiles and seating
//   "exploded" - Exploded view showing connector insertion direction into housing
// ==============================================================================

mode = "inside"; // ["inside", "outside", "mating", "cutaway", "exploded"]

/* [Transparency / Opacity] */
alpha_housing   = 1.0; // [0.0:0.05:1.0]
alpha_connector = 1.0; // [0.0:0.05:1.0]
alpha_hardware  = 1.0; // [0.0:0.05:1.0]

$fn = 32;

// --- Key Dimensions from 7segment_pogo.scad ---
digit_w       = 140.4;
wall_x        = digit_w / 2;     // 70.2 mm (outer face of right wall)
inner_x       = wall_x - 2.0;    // 68.2 mm (inner face of 2.0mm wall)
pogo_z        = 6.0;             // Centered along Z (12mm tunnel depth)

pogo_ear_span   = 23.6; // Outer span across mounting ears
pogo_ear_pitch  = 18.5; // Center-to-center hole spacing
pogo_hole_d     = 1.8;  // Pilot hole for M2 screw
pogo_hole_depth = 5.5;  // Screw boss depth
pogo_body_w     = 15.0; // Central body width
pogo_body_h     = 8.2;  // Central body height
pogo_flange_t   = 2.0;  // Ear flange thickness
pogo_boss_r     = 3.2;  // Boss outer radius
pogo_pass_d     = 10.0; // Inward wiring clearance cavity

// -------------------------------------------------------------
// 1. Detailed 4-Pin Magnetic Connector Model
// -------------------------------------------------------------
module pogo_connector_detailed(is_male = true, alpha = alpha_connector) {
    // Main molded thermoplastic body (Black/Dark Slate)
    color("#1e293b", alpha) {
        // Central body housing pins & magnets
        cube([4.8, 14.6, 7.8], center=true);
        
        // Mounting ears with M2 screw holes
        for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
            difference() {
                translate([0, y, 0])
                    hull() {
                        cube([2.0, 4.6, 7.6], center=true);
                        translate([0, (y > 0 ? 1 : -1) * 0.5, 0]) 
                            rotate([0, 90, 0]) 
                                cylinder(h=2.0, r=3.8, center=true, $fn=24);
                    }
                // Screw clearance hole
                translate([0, y, 0])
                    rotate([0, 90, 0])
                        cylinder(h=3.5, r=1.1, center=true, $fn=20);
            }
        }
    }
    
    // Neodymium Polarization / Alignment Magnets (Silver chrome)
    color("#cbd5e1", alpha) {
        for (my = [-5.2, 5.2]) {
            translate([1.5, my, 0]) 
                rotate([0, 90, 0]) 
                    cylinder(h=2.0, r=1.5, center=true, $fn=24);
        }
    }
    
    // Gold-Plated Electrical Contacts
    color("#f59e0b", alpha) {
        for (i = [-1.5, -0.5, 0.5, 1.5]) {
            py = i * 2.54;
            if (is_male) {
                // Spring-loaded pogo pin barrel & tip (protrudes 1.2mm beyond face)
                translate([2.4, py, 0]) rotate([0, 90, 0]) cylinder(h=0.8, r=0.75, center=true, $fn=16);
                translate([3.0, py, 0]) rotate([0, 90, 0]) cylinder(h=1.4, r=0.45, center=true, $fn=16);
            } else {
                // Flat female target contact pad (flush / slight recess)
                translate([2.4, py, 0]) rotate([0, 90, 0]) cylinder(h=0.4, r=0.9, center=true, $fn=16);
            }
            // Solder bucket / terminal pin extending inward
            translate([-3.2, py, 0]) 
                rotate([0, 90, 0]) 
                    cylinder(h=2.5, r=0.4, center=true, $fn=12);
        }
    }
}

// -------------------------------------------------------------
// 2. M2 Fasteners
// -------------------------------------------------------------
module m2_fastener(alpha = alpha_hardware) {
    color("#94a3b8", alpha) { // Stainless steel metallic finish
        // Pan head
        cylinder(h=1.3, r=1.9, center=true, $fn=24);
        // Threaded shaft (M2 x 5mm)
        translate([0, 0, -2.8])
            cylinder(h=5.0, r=0.95, center=true, $fn=16);
    }
}

// -------------------------------------------------------------
// 3. Color-Coded 4-Wire Harness & Sense Resistor
// -------------------------------------------------------------
module wiring_and_resistor(alpha = alpha_hardware) {
    wire_colors = [
        ["#ef4444", "Pin 1: +5V Power"],
        ["#0f172a", "Pin 2: GND"],
        ["#22c55e", "Pin 3: WS2812B Data"],
        ["#3b82f6", "Pin 4: Auto-Sense"]
    ];
    
    // 4 flexible silicone wires leading from solder terminals
    for (i = [-1.5, -0.5, 0.5, 1.5]) {
        idx = i + 1.5;
        py = i * 2.54;
        color(wire_colors[idx][0], alpha) {
            // Solder joint blob
            translate([-3.2, py, 0])
                sphere(r=0.7, $fn=12);
            // Insulated wire body routing inward
            translate([-3.8, py, 0])
                rotate([0, -90, 0])
                    cylinder(h=18, r=0.55, $fn=16);
        }
    }
    
    // Sense Resistor (e.g. 4.7kΩ for colon / unique ID for digit panels)
    // Tucked into the dedicated sense pocket
    translate([-4.0, 8.0, -3.0]) {
        // Ceramic resistor body (Blue / Beige)
        color("#0284c7", alpha)
            rotate([0, 90, 0])
                cylinder(h=3.6, r=1.1, center=true, $fn=20);
        // Solder lead wires to Pin 4 and GND
        color("#94a3b8", alpha) {
            rotate([0, 90, 0]) cylinder(h=7.0, r=0.25, center=true, $fn=12);
            // Wire jumper to GND (Pin 2 at py=-1.27)
            translate([0, -4.5, 1.5]) rotate([35, 0, 0]) cylinder(h=8.0, r=0.3, center=true, $fn=12);
        }
    }
}

// -------------------------------------------------------------
// 4. Housing Wall Section (Isolated around connector)
// -------------------------------------------------------------
module housing_wall_section(cut_half = false, alpha = alpha_housing) {
    color("#334155", alpha) { // Dark Slate housing plastic
        difference() {
            // Solid side wall block with internal M2 screw bosses
            union() {
                // Outer wall (2mm thick)
                translate([inner_x + 1.0, 0, pogo_z])
                    cube([2.0, 38, 22], center=true);
                // Bottom floor / ledge
                translate([inner_x - 4.0, 0, pogo_z - 9.0])
                    cube([10.0, 38, 2.0], center=true);
                    
                // Internal M2 Screw Bosses
                for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
                    hull() {
                        translate([inner_x - 0.25, y, pogo_z])
                            cube([0.5, pogo_boss_r * 2, pogo_body_h + 1.8], center=true);
                        translate([inner_x - 5.0, y, pogo_z])
                            rotate([0, 90, 0])
                                cylinder(h=0.5, r=pogo_boss_r, center=true, $fn=24);
                    }
                }
            }
            
            // Subtractions matching 7segment_pogo.scad:
            // 1. Central body rectangular through-opening
            translate([wall_x, 0, pogo_z])
                cube([6, pogo_body_w, pogo_body_h], center=true);
                
            // 2. Ear recess on inside shoulder
            translate([inner_x + 0.5, 0, pogo_z])
                cube([pogo_flange_t + 1.0, pogo_ear_span, pogo_body_h + 0.6], center=true);
                
            // 3. Inward wiring & solder pin clearance
            translate([inner_x - 5.0, 0, pogo_z])
                cube([pogo_pass_d + 0.1, pogo_body_w, pogo_body_h + 1.0], center=true);
                
            // 4. Pilot screw holes in bosses
            for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
                translate([inner_x, y, pogo_z])
                    rotate([0, -90, 0]) // Drilled inward into boss
                        cylinder(h=pogo_hole_depth + 1.0, r=pogo_hole_d/2, $fn=20);
            }
            
            // 5. Sense Resistor Pocket
            translate([inner_x - 4.0, 8.0, pogo_z - 3.0])
                cube([5.0, 3.5, 2.5], center=true);
                
            // Optional: slice in half along Y=0 for cutaway
            if (cut_half) {
                translate([inner_x - 5.0, -25.0, pogo_z])
                    cube([30, 50, 30], center=true);
            }
        }
    }
}

// =============================================================
// RENDER VIEWS
// =============================================================

// Center around connector face at (0,0,0)
translate([-wall_x, 0, -pogo_z]) {

    if (mode == "inside") {
        // VIEW 1: Interior view (Looking from inside the housing cavity)
        housing_wall_section(cut_half = false);
        
        // Connector seated flush in pocket
        translate([inner_x, 0, pogo_z]) {
            pogo_connector_detailed(is_male = true);
            wiring_and_resistor();
            
            // M2 screws inserted into bosses
            for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
                translate([-5.0, y, 0])
                    rotate([0, -90, 0])
                        m2_fastener();
            }
        }
    }
    
    else if (mode == "outside") {
        // VIEW 2: Exterior view (Flush plug face with pogo pins & magnets)
        housing_wall_section(cut_half = false);
        
        translate([inner_x, 0, pogo_z])
            pogo_connector_detailed(is_male = true);
    }
    
    else if (mode == "cutaway") {
        // VIEW 3: Centerline Cross-Section Slice
        housing_wall_section(cut_half = true);
        
        difference() {
            translate([inner_x, 0, pogo_z]) {
                pogo_connector_detailed(is_male = true);
                wiring_and_resistor();
                // Screw on the remaining upper ear
                translate([-5.0, pogo_ear_pitch/2, 0])
                    rotate([0, -90, 0])
                        m2_fastener();
            }
            // Cut half of connector too
            translate([inner_x - 5.0, -25.0, pogo_z])
                cube([30, 50, 30], center=true);
        }
    }
    
    else if (mode == "exploded") {
        // VIEW 4: Exploded Assembly View (shows insertion direction into housing)
        housing_wall_section(cut_half = false);
        
        // Connector pulled back 16mm into cavity
        translate([inner_x - 16.0, 0, pogo_z]) {
            pogo_connector_detailed(is_male = true);
            wiring_and_resistor();
        }
        
        // M2 Screws pulled back 24mm
        for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
            translate([inner_x - 24.0, y, pogo_z])
                rotate([0, -90, 0])
                    m2_fastener();
        }
    }
    
    else if (mode == "mating") {
        // VIEW 5: Seam Mating (Male panel on left, Female panel on right, 10mm gap)
        seam_gap = 10.0;
        
        // Left Housing Wall (Male transmitter)
        housing_wall_section(cut_half = false);
        translate([inner_x, 0, pogo_z])
            pogo_connector_detailed(is_male = true);
            
        // Right Housing Wall (Female receiver facing left)
        translate([wall_x * 2 + seam_gap, 0, 0])
            mirror([1, 0, 0]) {
                housing_wall_section(cut_half = false);
                translate([inner_x, 0, pogo_z])
                    pogo_connector_detailed(is_male = false);
            }
    }
}
