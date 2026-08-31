// Colon Spacer for Modular 7-Segment Display (v2 Design)
// Fits between digits and includes two dots for a clock colon.

// --- Key Parameters ---
spacer_width = 36;      // Width of the spacer in mm (slightly wider to fit the colon dots nicely)
panel_id = 2;           // Treated as a middle panel

pitch = 94;             // Matches 7segment_v1 digit pitch (94 mm)
strip_width = 12;       
white_wall = 1.2;       
margin_x = 15;          
margin_y = 15;          

tunnel_depth = 12;      
diffuser_thick = 1.0;   
backplate_floor = 1.5;  
connector_thick = 4.0;  
backplate_thick = connector_thick + backplate_floor; // 5.5 mm (matches 7segment_v1)
strip_recess_depth = 2.0; // Depth of LED recess in backplate

colon_radius = 6;       // Inner radius of the colon dots
colon_y_offset = 47;    // Y distance from center for the two dots (+/- 47mm, centered between segments)

// Inter-panel connector pass-through (Sized for standard 4-pin LED strip connectors & JST-SM)
inter_wire_w = 16.0;   // 16.0mm width clears 4-pin JST-SM (14.2mm) & 10/12mm snap clips (15.2mm)
inter_wire_h = 8.5;    // 8.5mm height clears 4-pin JST-SM locking latch (7.4mm) & snap clips (5.5mm)
inter_flange_w = 18.5; // Outer male flange width (1.25mm wall thickness)
inter_flange_h = 11.0; // Outer male flange height (1.25mm wall thickness)
inter_flange_z = 6.0;  // Centered along Z in the 12mm tunnel depth

// --- Calculated Dimensions ---
diffuser_w = strip_width + 2;      
total_seg_w = diffuser_w + white_wall * 2; 

digit_height = pitch * 2 + total_seg_w + margin_y * 2; // 234.4 mm (matches 7segment_v1 exactly)
total_depth = tunnel_depth + diffuser_thick;           // 13 mm

// Helper: debossed rectangular score line for clean punch-out breakaway membranes
module breakaway_score_rect(w, h, groove_w = 0.4, depth = 0.2) {
    difference() {
        cube([depth + 0.1, w + groove_w * 2, h + groove_w * 2], center=true);
        cube([depth + 0.3, w, h], center=true);
    }
}

// --- Components ---

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
            
            // Inter-panel alignment protrusion (Right side, robust male flange sticking out 3mm)
            translate([spacer_width/2, 0, inter_flange_z]) 
                cube([6, inter_flange_w, inter_flange_h], center=true);
        }
        
        // NOW cut out the actual white colon spaces
        for (y = [colon_y_offset, -colon_y_offset]) {
            translate([0, y, -1]) cylinder(h=total_depth + 2, r=colon_radius + white_wall, $fn=40);
        }
        
        // Snap-lock detent pockets in black housing bore
        colon_lightguide_snap_teeth(is_subtraction = true);
        
        // Screw holes for backplate to mount
        translate([spacer_width/2 - 6, digit_height/2 - 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([-spacer_width/2 + 6, digit_height/2 - 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([spacer_width/2 - 6, -digit_height/2 + 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([-spacer_width/2 + 6, -digit_height/2 + 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        
        // Inter-panel wire pass-through hole (Right side, outgoing 4-pin connector)
        translate([spacer_width/2 + 2.6 - 7.5, 0, inter_flange_z]) 
            cube([15, inter_wire_w, inter_wire_h], center=true);
            
        // Debossed guide groove on the tip face to show where to punch (0.2mm deep)
        translate([spacer_width/2 + 3.0 - 0.1, 0, inter_flange_z])
            breakaway_score_rect(inter_wire_w, inter_wire_h, groove_w=0.4, depth=0.2);
            
        // Inter-panel wire pass-through & alignment receiver (Left side, incoming 4-pin connector)
        translate([-spacer_width/2 + 0.4 + 7.5, 0, inter_flange_z]) 
            cube([15, inter_flange_w + 0.5, inter_flange_h + 0.5], center=true);
            
        // Debossed guide groove on the outside left wall to show where to punch (0.2mm deep)
        translate([-spacer_width/2 + 0.1, 0, inter_flange_z])
            breakaway_score_rect(inter_flange_w + 0.5, inter_flange_h + 0.5, groove_w=0.4, depth=0.2);
            
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
                for (side = [-1, 1]) {
                    translate([side * 6.0, 0])
                        square([side > 0 ? -2.2 : 2.2, 0.6], center=true);
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
        // Main flat plate (shrunk by 2mm per side for walls + 0.2mm clearance)
        translate([-(spacer_width - 4.4)/2, -(digit_height - 4.4)/2, -backplate_thick])
            cube([spacer_width - 4.4, digit_height - 4.4, backplate_thick]);
            
        // Recesses for LED PCBs (12x20mm, 2mm deep)
        for (y = [colon_y_offset, -colon_y_offset]) {
            translate([-6, y - 10, -strip_recess_depth])
                cube([12, 20, strip_recess_depth + 0.1]);
        }
        
        // Outer wire loop-up turnaround pockets (7mm long, 2mm deep) at far end of each LED
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
            
        // Mounting screw holes (M3 clearance, 3.2mm) with countersink for flush heads
        for (x = [spacer_width/2 - 6, -spacer_width/2 + 6]) {
            for (y = [digit_height/2 - 6, -digit_height/2 + 6]) {
                translate([x, y, -backplate_thick - 0.1]) {
                    cylinder(h=backplate_thick + 0.2, r=1.6, $fn=20);       
                    cylinder(h=1.6, r1=3.2, r2=1.6, $fn=20);                
                }
            }
        }
    }
}

// --- Render Assembly ---
color("DimGray") colon_frontplate_black();
// Translated forward by 20mm for preview
translate([0, 0, 20]) color("White") colon_frontplate_white();
// Translated backwards by 20mm for preview
translate([0, 0, -20]) color("SlateGray") colon_backplate();
