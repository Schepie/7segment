// Colon Spacer for Modular 7-Segment Display (Pogo Pin Edition)
// Fits between digits (e.g. between Digit 2 and Digit 3 for an HH:MM clock)
// Features 2 illuminated colon dots and flush-mount 4-pin magnetic pogo connectors
// on both the left and right walls for seamless, cable-free chaining.

// --- Key Parameters ---
spacer_width = 36;      // Width of the colon spacer in mm
show_pogo_hardware = true; // Set to true to preview 3D pogo connectors sitting in mounting pockets

pitch = 94;             // Matches 7segment_pogo digit pitch (94 mm)
strip_width = 12;       
white_wall = 1.2;       
margin_x = 15;          
margin_y = 15;          

tunnel_depth = 12;      
diffuser_thick = 1.0;   
backplate_floor = 1.5;  
connector_thick = 4.0;  
backplate_thick = connector_thick + backplate_floor; // 5.5 mm
strip_recess_depth = 2.0; // Depth of LED recess in backplate

colon_radius = 6;       // Inner radius of the colon dots
colon_y_offset = 47;    // Y distance from center for the two dots (+/- 47mm)

// --- 4-Pin Magnetic Pogo Pin Connector Parameters ---
pogo_ear_span       = 23.6; // Total outer span across mounting ears
pogo_ear_pitch      = 18.5; // Center-to-center spacing between ear screw holes
pogo_hole_d         = 1.8;  // Pilot hole diameter for M2 self-tapping screws
pogo_hole_depth     = 5.5;  // Depth of screw hole into mounting boss
pogo_body_w         = 15.0; // Central body width
pogo_body_h         = 8.2;  // Central body height (Z-axis)
pogo_flange_thick   = 2.0;  // Thickness of connector mounting ear flange
pogo_boss_r         = 3.2;  // Outer radius of M2 screw bosses
pogo_pass_depth     = 10.0; // Inward wiring clearance
pogo_z              = 6.0;  // Centered along Z in the 12mm tunnel depth

// --- Calculated Dimensions ---
diffuser_w = strip_width + 2;      
total_seg_w = diffuser_w + white_wall * 2; 

digit_height = pitch * 2 + total_seg_w + margin_y * 2; // 234.4 mm (matches 7segment_pogo)
total_depth = tunnel_depth + diffuser_thick;           // 13 mm

// -------------------------------------------------------------
// Pogo Pin Connector Support Modules
// -------------------------------------------------------------



module colon_pogo_cutout(is_left = false) {
    side = is_left ? -1 : 1;
    wall_x = side * spacer_width / 2;
    inner_x = side * (spacer_width / 2 - 2.0);
    
    // 1. Through-wall window for central magnetic connector contact face ONLY (15.0 x 8.2 mm)
    // Completely leaves the outer 1.0mm wall covering the side mounting ears
    translate([wall_x, 0, pogo_z])
        cube([6, pogo_body_w, pogo_body_h], center=true);
        
    // 2. Lower U-notch below connector (Z = -backplate_thick to Z = 1.9mm) across full ear width (25.4mm)
    // Filled flush by the backplate outer wall extension upon assembly
    h_low = (pogo_z - pogo_body_h/2) - (-backplate_thick);
    translate([wall_x, 0, -backplate_thick + h_low/2])
        cube([6, pogo_ear_span + 0.4, h_low + 0.1], center=true);
        
    // 3. Internal ear pocket & insertion slot on the inside of the wall (behind outer 1.0mm wall)
    // Accommodates the 25.0mm total ear span inside the housing without exposing ears to outside
    translate([inner_x + side * 0.4, 0, pogo_z])
        cube([pogo_flange_thick + 0.8, pogo_ear_span, pogo_body_h + 0.4], center=true);
        
    // 4. Inward wiring clearance
    translate([inner_x - side * (pogo_pass_depth/2), 0, (pogo_z + pogo_body_h/2 - backplate_thick)/2])
        cube([pogo_pass_depth + 0.1, pogo_body_w, pogo_z + pogo_body_h/2 + backplate_thick + 0.2], center=true);
        
    // 5. Sense Resistor Stash Pocket (for 4.7k resistor inside colon)
    translate([inner_x - side * 4.0, side * 8.0, pogo_z - 3.0])
        cube([5.0, 3.5, 2.5], center=true);
}

// Integrated pogo cradle on colon_backplate:
// Supplies the outer wall section below the connector, the horizontal connector seating shelf, and the rear clamping tabs
module colon_pogo_backplate_cradle() {
    for (side = [-1, 1]) {
        wall_x = side * (spacer_width / 2);
        inner_x = side * (spacer_width / 2 - 2.0);
        h_wall = (pogo_z - pogo_body_h/2) - (-backplate_thick);
        
        // 1. Outer side wall extension below connector across full ear span (Z = -backplate_thick to Z = 1.9mm)
        translate([wall_x - side * 1.0, 0, -backplate_thick + h_wall/2])
            cube([2.0, pogo_ear_span - 0.2, h_wall], center=true);
            
        // 2. Connector seating floor / support shelf under connector body and ears
        translate([inner_x - side * 0.5, 0, pogo_z - pogo_body_h/2 - 0.5])
            cube([3.0, pogo_ear_span, 1.0], center=true);
            
        // 3. Vertical rear clamping wedge tabs behind connector ears
        tab_x = inner_x - side * pogo_flange_thick;
        tab_thick = 2.0;
        
        for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
            translate([tab_x - side * tab_thick/2, y, 0]) {
                hull() {
                    translate([0, 0, 0.5])
                        cube([tab_thick, 5.0, 1.0], center=true);
                    translate([0, 0, pogo_z])
                        cube([tab_thick, 5.0, 1.0], center=true);
                    translate([-side * 0.6, 0, pogo_z + 2.0])
                        cube([tab_thick - 1.2, 5.0, 1.0], center=true);
                }
            }
        }
    }
}

// Visual 3D model of the 4-pin magnetic connector
module pogo_connector_model(is_male = true) {
    color("#1e293b") {
        cube([4.8, 14.6, 7.8], center=true);
        for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
            difference() {
                translate([0, y, 0])
                    hull() {
                        cube([2.0, 4.6, 7.6], center=true);
                        translate([0, (y > 0 ? 1 : -1) * 0.5, 0]) rotate([0, 90, 0]) cylinder(h=2.0, r=3.8, center=true, $fn=20);
                    }
                translate([0, y, 0])
                    rotate([0, 90, 0])
                        cylinder(h=3.0, r=1.1, center=true, $fn=16);
            }
        }
    }
    color("#cbd5e1") {
        for (my = [-5.2, 5.2]) {
            translate([1.5, my, 0]) rotate([0, 90, 0]) cylinder(h=2.0, r=1.5, center=true, $fn=20);
        }
    }
    color("#f59e0b") {
        for (i = [-1.5, -0.5, 0.5, 1.5]) {
            py = i * 2.54;
            if (is_male) {
                translate([2.8, py, 0]) rotate([0, 90, 0]) cylinder(h=1.6, r=0.5, center=true, $fn=12);
            } else {
                translate([2.4, py, 0]) rotate([0, 90, 0]) cylinder(h=0.4, r=0.8, center=true, $fn=12);
            }
            translate([-3.4, py, 0]) rotate([0, 90, 0]) cylinder(h=2.5, r=0.4, center=true, $fn=12);
        }
    }
}

// --- Modular Lightguide Snap-Fit Option ---
enable_lightguide_snap_locks = true; // Set to true for snap-lock tabs (separate printing & testing). Set false for unified 2-color print.

// Snap-lock detents & tabs geometry for testable lightguides
module colon_lightguide_snap_teeth(is_subtraction = false) {
    if (enable_lightguide_snap_locks) {
        tooth_w = 3.2;
        tooth_h = 2.2;
        tooth_reach = is_subtraction ? 0.7 : 0.5;
        
        for (y = [colon_y_offset, -colon_y_offset]) {
            for (side = [-1, 1]) {
                translate([side * (colon_radius + white_wall), y, 2.5]) {
                    if (is_subtraction) {
                        // Pocket cutout in black housing
                        cube([tooth_reach * 2 + 0.2, tooth_w + 0.4, tooth_h + 0.4], center=true);
                    } else {
                        // Outward latching tooth on white lightguide with 45° lead-in ramp
                        rotate([0, side > 0 ? 0 : 180, 0])
                            linear_extrude(tooth_w, center=true)
                                polygon([
                                    [0, -tooth_h/2],
                                    [tooth_reach, -tooth_h/4],
                                    [tooth_reach, tooth_h/4],
                                    [0, tooth_h/2]
                                ]);
                    }
                }
            }
        }
    }
}

// Vertical compliance flex slits allowing snap teeth to deflect elastically during insertion
module colon_lightguide_flex_slits() {
    if (enable_lightguide_snap_locks) {
        slit_w = 0.8;
        slit_l = 4.0;
        slit_h = 5.5;
        for (y = [colon_y_offset, -colon_y_offset]) {
            for (side = [-1, 1]) {
                for (dy = [-2.0, 2.0]) {
                    translate([side * (colon_radius + white_wall), y + dy, slit_h/2 - 0.1])
                        cube([slit_l, slit_w, slit_h + 0.2], center=true);
                }
            }
        }
    }
}

// Localized wire clearance archways (bottom 1.8mm at wire entry & exit ends only)
// Leaves the white reflector cylinder 100% solid and enclosed around the LED emitter to maximize brightness
module colon_wire_clearance_notches(notch_h = 1.8) {
    for (y = [colon_y_offset, -colon_y_offset]) {
        // 1. Inner wire entry archway (connecting center channel to inner solder pads)
        translate([0, y - 7.5, notch_h/2 - 0.1])
            cube([10.5, 7.0, notch_h + 0.2], center=true);
            
        // 2. Outer wire exit archway (connecting outer solder pads to loop-up turnaround well)
        translate([0, y + 7.5, notch_h/2 - 0.1])
            cube([10.5, 7.0, notch_h + 0.2], center=true);
    }
}

module colon_frontplate_black() {
    difference() {
        union() {
            // 1. Main hollow shell frame with outer skirt extending down over backplate (-backplate_thick to total_depth)
            difference() {
                translate([-spacer_width/2, -digit_height/2, -backplate_thick])
                    cube([spacer_width, digit_height, total_depth + backplate_thick]);
                translate([-spacer_width/2 + 2.0, -digit_height/2 + 2.0, -backplate_thick - 0.1])
                    cube([spacer_width - 4.0, digit_height - 4.0, total_depth + backplate_thick - 1.2 + 0.1]);
            }
            
            // 2. Solid black light-blocking collars around each colon dot (prevents internal light bleed)
            for (y = [colon_y_offset, -colon_y_offset]) {
                translate([0, y, 0]) 
                    cylinder(h=total_depth, r=colon_radius + white_wall + 1.6, $fn=40);
            }
                
            // 3. Corner backplate screw bosses
            translate([spacer_width/2 - 6, digit_height/2 - 6, 0]) cylinder(h=total_depth - 1.2, r=4.2, $fn=20);
            translate([-spacer_width/2 + 6, digit_height/2 - 6, 0]) cylinder(h=total_depth - 1.2, r=4.2, $fn=20);
            translate([spacer_width/2 - 6, -digit_height/2 + 6, 0]) cylinder(h=total_depth - 1.2, r=4.2, $fn=20);
            translate([-spacer_width/2 + 6, -digit_height/2 + 6, 0]) cylinder(h=total_depth - 1.2, r=4.2, $fn=20);
        }
        
        // White colon lightguide cylindrical boreholes (through-holes to front face)
        for (y = [colon_y_offset, -colon_y_offset]) {
            translate([0, y, -1]) cylinder(h=total_depth + 2, r=colon_radius + white_wall, $fn=40);
        }
        
        // Snap-lock detent pockets in black housing bore
        colon_lightguide_snap_teeth(is_subtraction = true);
        
        // Screw holes for backplate (M3 heat-set inserts)
        translate([spacer_width/2 - 6, digit_height/2 - 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([-spacer_width/2 + 6, digit_height/2 - 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([spacer_width/2 - 6, -digit_height/2 + 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([-spacer_width/2 + 6, -digit_height/2 + 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        
        // Pogo connector mounting cutouts on both left and right walls
        colon_pogo_cutout(is_left = true);
        colon_pogo_cutout(is_left = false);
        
        // Central wiring pass-through tunnel connecting left and right pogo connectors
        translate([0, 0, pogo_z])
            cube([spacer_width + 2, 8.0, 6.0], center=true);
            
        // Wire & solder joint clearance notches
        colon_wire_clearance_notches(1.8);
    }
}

module colon_frontplate_white() {
    difference() {
        union() {
            // Outer white reflector walls + top diffuser
            for (y = [colon_y_offset, -colon_y_offset]) {
                translate([0, y, 0]) cylinder(h=total_depth, r=colon_radius + white_wall, $fn=40);
            }
            
            // Outward snap-lock teeth on lightguide sides
            colon_lightguide_snap_teeth(is_subtraction = false);
        }
        
        // Hollow light tunnel cavity, leaving 1.0mm solid diffuser face on top
        for (y = [colon_y_offset, -colon_y_offset]) {
            translate([0, y, 0]) cylinder(h=tunnel_depth, r=colon_radius, $fn=40);
        }
        
        // Compliance flex slits allowing snap teeth to deflect on insertion
        colon_lightguide_flex_slits();
        
        // Wire & solder joint clearance notches (bottom 1.8mm at ends only)
        colon_wire_clearance_notches(1.8);
    }
}

// Visual mechanical LED placement indicators debossed in backplate (No text labels)
module colon_led_placement_indicators() {
    for (y_center = [colon_y_offset, -colon_y_offset]) {
        // 1. Center alignment crosshair ticks on left & right shoulders (at X = +/-6.0mm, Y = center)
        translate([0, y_center, -0.3]) {
            linear_extrude(0.4) {
                // Centerline tick marks
                for (side = [-1, 1]) {
                    translate([side * 6.0, 0])
                        square([side > 0 ? -2.2 : 2.2, 0.6], center=true);
                        
                    // 5050 LED body bounds ticks (Y = +/-2.5mm)
                    for (dy = [-2.5, 2.5]) {
                        translate([side * 6.0, dy])
                            square([side > 0 ? -1.4 : 1.4, 0.4], center=true);
                    }
                }
            }
        }
        
        // 2. PCB corner alignment L-brackets at the 4 corners of the 12x20mm PCB
        translate([0, y_center, -0.3]) {
            linear_extrude(0.4) {
                for (sx = [-6.0, 6.0]) {
                    for (sy = [-10.0, 10.0]) {
                        translate([sx, sy]) {
                            // L-shaped corner bracket
                            translate([sx > 0 ? -2.0 : 0, -0.3]) square([2.0, 0.6]);
                            translate([-0.3, sy > 0 ? -2.0 : 0]) square([0.6, 2.0]);
                        }
                    }
                }
            }
        }
    }
}

module colon_backplate() {
    difference() {
        union() {
            // Main flat plate
            translate([-(spacer_width - 4.4)/2, -(digit_height - 4.4)/2, -backplate_thick])
                cube([spacer_width - 4.4, digit_height - 4.4, backplate_thick]);
                
            // Pogo connector cradles (outer side wall extensions, seating shelves, and rear clamping tabs)
            colon_pogo_backplate_cradle();
        }
            
        // Recesses for LED PCBs (12x20mm, 2mm deep)
        for (y = [colon_y_offset, -colon_y_offset]) {
            translate([-6, y - 10, -strip_recess_depth])
                cube([12, 20, strip_recess_depth + 0.1]);
        }
        
        // Outer wire loop-up turnaround pockets (7mm long, 2mm deep) at far end of each LED
        // Gives plenty of room for wires coming from underneath to curve up and solder onto outer pads
        for (dir = [1, -1]) {
            translate([-6, dir * (colon_y_offset + 10) - (dir > 0 ? 0 : 7), -strip_recess_depth])
                cube([12, 7, strip_recess_depth + 0.1]);
        }
        
        // Under-LED wire pass-through channels (allows BI/BO backup data wires to route underneath the LED PCBs)
        // Reduced to 3.0mm (50% reduction) to provide maximum solid support floor under the LED PCB
        for (y = [colon_y_offset, -colon_y_offset]) {
            translate([0, y, -strip_recess_depth - 0.9])
                cube([3.0, 30.0, 1.8 + 0.1], center=true);
        }
        
        // Wire channel connecting the two LEDs vertically
        translate([0, 0, -strip_recess_depth/2]) 
            cube([12, colon_y_offset * 2, strip_recess_depth + 0.1], center=true);
            
        // Visual LED placement indicators (LED target frame & corner brackets)
        colon_led_placement_indicators();
            
        // Mounting screw holes (M3 clearance, 3.2mm) with countersink
        for (x = [spacer_width/2 - 6, -spacer_width/2 + 6]) {
            for (y = [digit_height/2 - 6, -digit_height/2 + 6]) {
                translate([x, y, -backplate_thick - 0.1]) {
                    cylinder(h=backplate_thick + 0.2, r=1.6, $fn=20);       
                    cylinder(h=1.6, r1=3.2, r2=1.6, $fn=20);                
                }
            }
        }
        
        // Label debossed on rear of colon
        translate([0, 0, -backplate_thick - 0.1])
            linear_extrude(1.0)
                mirror([1, 0, 0])
                    text("COLON", size=5, font="Liberation Sans:style=Bold", halign="center", valign="center");
    }
}

// --- 3D Electronics & Wiring Visualization ---
show_wiring = true; // Set to true to preview LED PCBs, solder pads, sense resistor, and wiring harness

// Helper: 3D wire segment connecting point A to point B
module wire_segment(p1, p2, r=0.45) {
    hull() {
        translate(p1) sphere(r=r, $fn=12);
        translate(p2) sphere(r=r, $fn=12);
    }
}

// Helper: Chain of points forming a smooth 3D curved wire
module wire_curve(points, r=0.45) {
    for (i = [0 : len(points) - 2]) {
        wire_segment(points[i], points[i+1], r);
    }
}

module colon_led_pcb_model(y_pos = 0) {
    translate([0, y_pos, -1.0]) {
        // Black PCB substrate (12x20mm)
        color("#1e293b")
            cube([12, 20, 1.0], center=true);
            
        // 4 Copper solder pads (+5V, DI/DO, BI/BO, GND) at top and bottom ends of PCB
        color("#d97706") {
            for (sy = [-8.5, 8.5]) {
                for (sx = [-3.75, -1.25, 1.25, 3.75]) {
                    translate([sx, sy, 0.55])
                        cube([1.8, 1.8, 0.1], center=true);
                }
            }
        }
        
        // 5050 RGB LED package
        translate([0, 0, 1.1]) {
            color("#f8fafc") cube([5.0, 5.0, 1.2], center=true);
            color("#eab308") translate([0, 0, 0.4]) cylinder(h=0.5, r=1.8, center=true, $fn=20);
        }
    }
}

module colon_electronics_wiring_preview() {
    // 1. Mounted 4-Pin LED PCBs (Sitting in 2mm recesses at Y = +47 and Y = -47)
    colon_led_pcb_model(colon_y_offset);
    colon_led_pcb_model(-colon_y_offset);
    
    // 2. Sense Resistor (4.7kΩ, tucked in sense pocket at X = 12, Y = 8, Z = 3)
    translate([12.0, 8.0, pogo_z - 3.0]) {
        color("#0284c7") // Ceramic body
            rotate([0, 90, 0])
                cylinder(h=3.6, r=1.1, center=true, $fn=20);
        color("#94a3b8") { // Metal leads
            rotate([0, 90, 0]) cylinder(h=6.5, r=0.25, center=true, $fn=12);
            // Solder lead to Pin 4 (Sense)
            translate([2.0, -4.0, 1.5]) rotate([-30, 0, 0]) cylinder(h=7.0, r=0.25, center=true, $fn=12);
            // Solder lead to Pin 2 (GND)
            translate([2.0, -9.0, 1.5]) rotate([30, 0, 0]) cylinder(h=7.0, r=0.25, center=true, $fn=12);
        }
    }
    
    // 3. Complete 4-Wire Harness Curves (+5V, DI, BI, GND)
    // LEFT POGO PIN 1 (+5V, Red) -> BOTTOM LED +5V pad (at X=-3.75, Y=-38.5)
    color("#ef4444") {
        wire_curve([
            [-13.5, -3.81, pogo_z],
            [-11.5, -3.81, pogo_z],
            [-8.5, -8.0, 2.5],
            [-5.0, -15.0, 0.0],
            [-3.75, -22.0, -0.6],
            [-3.75, -38.5, -0.4]
        ]);
        translate([-3.75, -38.5, -0.3]) sphere(r=0.8, $fn=12);
    }
    
    // LEFT POGO PIN 2 (GND, Black) -> BOTTOM LED GND pad (at X=+3.75, Y=-38.5)
    color("#0f172a") {
        wire_curve([
            [-13.5, -1.27, pogo_z],
            [-11.5, -1.27, pogo_z],
            [-8.0, -5.0, 2.2],
            [1.0, -14.0, 0.0],
            [3.75, -22.0, -0.6],
            [3.75, -38.5, -0.4]
        ]);
        translate([3.75, -38.5, -0.3]) sphere(r=0.8, $fn=12);
    }
    
    // LEFT POGO PIN 3 (Data In, Green) -> BOTTOM LED DI pad (at X=-1.25, Y=-38.5)
    color("#22c55e") {
        wire_curve([
            [-13.5, 1.27, pogo_z],
            [-11.5, 1.27, pogo_z],
            [-7.5, 0.0, 2.5],
            [-2.0, -10.0, 0.2],
            [-1.25, -22.0, -0.6],
            [-1.25, -38.5, -0.4]
        ]);
        translate([-1.25, -38.5, -0.3]) sphere(r=0.8, $fn=12);
    }
    
    // BOTTOM LED DO (Yellow wire at X=-1.25) -> TOP LED DI pad (at X=-1.25, Y=+38.5)
    color("#facc15") {
        wire_curve([
            [-1.25, -55.5, -0.4],
            [-1.25, -50.0, -0.6],
            [-1.25, 0.0, -0.6],
            [-1.25, 30.0, -0.6],
            [-1.25, 38.5, -0.4]
        ]);
        translate([-1.25, -55.5, -0.3]) sphere(r=0.8, $fn=12);
        translate([-1.25, 38.5, -0.3]) sphere(r=0.8, $fn=12);
    }
    
    // BACKUP DATA PASS-THROUGH (BI / BO, Cyan wire at X=+1.25)
    // Routes underneath the LED PCBs via sub-floor tunnel, loops up in the 7mm turnaround pocket, and solders to BO pad
    color("#06b6d4") {
        wire_curve([
            // Outer BO solder pad on bottom LED (Y = -55.5, X = +1.25)
            [1.25, -55.5, -0.3],
            // Loops around in outer turnaround pocket (Y = -61.0)
            [1.25, -61.0, -0.8],
            [1.25, -61.0, -2.8],
            // Under bottom LED PCB
            [1.25, -57.0, -2.8],
            [1.25, -37.0, -2.8],
            // Through center channel
            [1.25, 0.0, -0.6],
            // Under top LED PCB
            [1.25, 37.0, -2.8],
            [1.25, 57.0, -2.8],
            // Loops around in outer turnaround pocket for top LED (Y = +61.0)
            [1.25, 61.0, -2.8],
            [1.25, 61.0, -0.8],
            // Lands on outer BO solder pad on top LED (Y = +55.5, X = +1.25)
            [1.25, 55.5, -0.3]
        ]);
        translate([1.25, -55.5, -0.3]) sphere(r=0.6, $fn=12);
        translate([1.25, 55.5, -0.3]) sphere(r=0.6, $fn=12);
    }
    
    // +5V BUS (Red wire at X=-3.75) -> TOP LED +5V pad & to RIGHT POGO PIN 1
    color("#ef4444") {
        wire_curve([
            [-3.75, -38.5, -0.4],
            [-3.75, 0.0, -0.6],
            [-3.75, 38.5, -0.4]
        ]);
        translate([-3.75, 38.5, -0.3]) sphere(r=0.8, $fn=12);
        // Extension to Right Pogo Pin 1
        wire_curve([
            [-3.75, 15.0, -0.6],
            [5.0, 5.0, 0.5],
            [8.5, -3.81, 2.5],
            [11.5, -3.81, pogo_z],
            [13.5, -3.81, pogo_z]
        ]);
    }
    
    // GND BUS (Black wire at X=+3.75) -> TOP LED GND pad & to RIGHT POGO PIN 2
    color("#0f172a") {
        wire_curve([
            [3.75, -38.5, -0.4],
            [3.75, 0.0, -0.6],
            [3.75, 38.5, -0.4]
        ]);
        translate([3.75, 38.5, -0.3]) sphere(r=0.8, $fn=12);
        // Extension to Right Pogo Pin 2
        wire_curve([
            [3.75, 12.0, -0.6],
            [6.0, 2.0, 0.5],
            [8.5, -1.27, 2.5],
            [11.5, -1.27, pogo_z],
            [13.5, -1.27, pogo_z]
        ]);
    }
    
    // TOP LED DO (Green wire at X=-1.25) -> RIGHT POGO PIN 3 (Data Out)
    color("#22c55e") {
        wire_curve([
            [-1.25, 55.5, -0.4],
            [-1.25, 50.0, -0.6],
            [-1.25, 25.0, -0.6],
            [5.0, 10.0, 1.0],
            [8.5, 1.27, 2.5],
            [11.5, 1.27, pogo_z],
            [13.5, 1.27, pogo_z]
        ]);
        translate([-1.25, 55.5, -0.3]) sphere(r=0.8, $fn=12);
    }
}

// --- Render Mode ---
render_mode = "exploded"; // ["exploded", "assembled", "wiring_view", "wiring_closeup", "lightguide_inspection", "backplate_only", "frontplate_black_only", "frontplate_white_only"]

module colon_pogo_connectors_preview() {
    // Left-facing female pogo connector (receives from Digit 2)
    translate([-spacer_width/2 + 2.0, 0, pogo_z])
        rotate([0, 180, 0])
            pogo_connector_model(is_male = false);
            
    // Right-facing male pogo connector (transmits to Digit 3)
    translate([spacer_width/2 - 2.0, 0, pogo_z])
        pogo_connector_model(is_male = true);
}

module render_colon_assembly() {
    if (render_mode == "exploded") {
        color("DimGray") colon_frontplate_black();
        translate([0, 0, 20]) color("White") colon_frontplate_white();
        translate([0, 0, -20]) color("SlateGray") colon_backplate();
        if (show_pogo_hardware) {
            colon_pogo_connectors_preview();
        }
        if (show_wiring) {
            translate([0, 0, -20]) colon_electronics_wiring_preview();
        }
    } else if (render_mode == "assembled") {
        color("DimGray") colon_frontplate_black();
        color("White") colon_frontplate_white();
        color("SlateGray") colon_backplate();
        if (show_pogo_hardware) {
            colon_pogo_connectors_preview();
        }
        if (show_wiring) {
            colon_electronics_wiring_preview();
        }
    } else if (render_mode == "lightguide_inspection") {
        // Shows white reflector cylinder seated directly over backplate and LED for optical inspection
        color("SlateGray") colon_backplate();
        color("White") colon_frontplate_white();
        colon_electronics_wiring_preview();
    } else if (render_mode == "wiring_view") {
        color("SlateGray") colon_backplate();
        colon_pogo_connectors_preview();
        colon_electronics_wiring_preview();
    } else if (render_mode == "wiring_closeup") {
        color("SlateGray") colon_backplate();
        colon_pogo_connectors_preview();
        colon_electronics_wiring_preview();
    } else if (render_mode == "backplate_only") {
        color("SlateGray") colon_backplate();
    } else if (render_mode == "frontplate_black_only") {
        color("DimGray") colon_frontplate_black();
    } else if (render_mode == "frontplate_white_only") {
        color("White") colon_frontplate_white();
    }
}

render_colon_assembly();
