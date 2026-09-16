// ==============================================================================
// Modular 7-Segment Display Stand System (Tafelstandaard)
// For Modular 7-Segment Clock & Padel Scoreboard
// Designed for Bambu Lab / Prusa / FDM 3D Printing (100% Support-Free)
// ==============================================================================
//
// Features:
// 1. Tool-Free Slide-In Cradle Feet (Compact Design):
//    - Precision 18.9 mm slot (+0.4mm tolerance) lets panels drop in smoothly.
//    - Low-profile 11.5 mm front lip prevents forward slip while staying well below
//      the 15.0 mm bottom LED segment bezel (100% unobstructed light diffusers).
//    - Tall 42.0 mm rear backrest spine supports the backplate firmly.
//    - Ergonomic 8° BACKWARD viewing tilt: the display face leans backward so it is
//      angled upwards towards the viewer's eyes on a table/desk.
//    - Sleek compact footprint: flush front and solid structural body.
//    - Exactly 2 circular recesses of 13.0 mm diameter on the flat underside
//      to mount standard 13 mm anti-slip rubber pads (solid flat bottom).
//    - 100% Support-Free 3D Printing: prints flat on its base with zero overhangs.
//
// 2. Bolt-On M3 Screw-Mount Kickstand Legs:
//    - Fastens directly into the existing M3 bottom corner screw holes (6mm inset)
//      or seam holes (12mm pitch) on the backplate.
//    - Rigid triangular kickstand leg props the display at the same 8° backward tilt.
//
// ==============================================================================

/* [Configuration & Part Selection] */
part = 2; // [1:"cradle_single - 1 Cradle Foot (with M3 Seam Holes)", 2:"cradle_pair - Pair of Cradle Feet (L+R)", 3:"cradle_set4 - Set of 4 Cradle Feet", 4:"screw_single - 1 Bolt-on Rear Kickstand Leg", 5:"screw_pair - Pair of Bolt-on Kickstand Legs", 6:"preview_seam - Assembled Seam Preview (Replaces U-Bracket)", 7:"preview_single - Assembled Single Panel Preview", 8:"rear_view - Rear View (Screw Holes & Counterbores)", 9:"bottom_view - Underside View (Rubber Pad Recesses)"]

/* [Mechanical Dimensions - Cradle Stand] */
panel_thick     = 18.5; // Nominal display thickness (13.0mm frontplate + 5.5mm backplate)
slot_clearance  = 0.40; // Clearance for smooth slide-in fit without scratching (18.9mm slot)
tilt_angle      = 8.0;  // Ergonomic backward tilt in degrees (leans back towards user's eyes)

foot_w          = 28.0; // Standardized to 28.0 mm (matches panel_seam_u_bracket for seam mounting)
base_floor      = 5.0;  // Solid bottom floor thickness below the display slot (mm)
front_toe_len   = 0.0;  // Flush front face (no protruding toe)
rear_leg_len    = 10.0; // Compact rear heel (mm)

front_lip_h     = 11.5; // Front lip retention height above slot base (mm, must be < 15.0mm)
front_lip_thick = 4.5;  // Front lip wall thickness (mm)
rear_spine_h    = 42.0; // Rear backrest support height above slot base (mm)
rear_wall_thick = 6.0;  // Rear wall thickness at base of slot (mm)

fillet_r        = 2.5;  // Edge radius for sleek finish and good bed adhesion

/* [Direct Panel Mounting - M3 Screw Holes (Replaces U-Bracket)] */
screw_holes_mode = "seam"; // ["seam": 2x M3 holes at 12mm pitch (replaces bottom U-bracket across seam), "center": 1x M3 hole at foot center, "none": Slide-in only without holes]
screw_head_style = "countersunk"; // ["countersunk": M3 DIN 7991 flush cone, "counterbore": flat bottom for socket/button head]
hole_pitch       = 12.0; // Distance between seam holes (6mm + 6mm across seam)
screw_rim_inset  = 6.0;  // Inset of M3 brass inserts from panel bottom rim (mm)
screw_hole_d     = 3.4;  // M3 pass-through clearance diameter (mm)
flange_thick     = 3.2;  // Wall thickness between slot and screw head seat (mm)
screw_cb_d       = 8.5;  // Counterbore diameter for screw head & tool access (mm)
cs_outer_d       = 6.5;  // Countersink cone diameter for M3 DIN 7991 (mm)
cs_depth         = 1.8;  // Countersink cone depth (mm)

/* [Anti-Slip Bumper Recesses - 2x 13mm Circles] */
enable_bumpers  = true; // Add bottom recesses for rubber feet
bumper_d        = 13.0; // Recess diameter: exactly 13.0 mm circular pads
bumper_depth    = 0.8;  // Recess depth into bottom face (mm)
pad_margin      = 2.5;  // Margin from front and rear edges to pad perimeter (mm)

/* [Print Resolution] */
$fn = 60;

// ==============================================================================
// INTERNAL CALCULATIONS & DERIVED VALUES (BACKWARD TILT GEOMETRY)
// ==============================================================================
effective_slot_w = panel_thick + slot_clearance; // 18.9 mm
slot_pivot_y     = front_toe_len + front_lip_thick;

slot_cos = cos(tilt_angle);
slot_sin = sin(tilt_angle);

// Front lip top (tilting backward into +Y as Z climbs)
y_lip_top = slot_pivot_y + front_lip_h * slot_sin;
z_lip_top = base_floor + front_lip_h * slot_cos;

// Rear backrest spine top inner edge (matches top-rear corner of rotated display slot)
y_spine_inner_top = slot_pivot_y + effective_slot_w * slot_cos + rear_spine_h * slot_sin;
z_spine_inner_top = base_floor + effective_slot_w * slot_sin + rear_spine_h * slot_cos;

// Rear spine outer edge (adding wall thickness)
y_spine_outer_top = y_spine_inner_top + rear_wall_thick;
z_spine_outer_top = z_spine_inner_top;

// Total depth along Y from front face to rear heel
total_depth_y = y_spine_outer_top + rear_leg_len;

// Exact Y center positions for the two 13mm circular pad recesses
y_pad_front = pad_margin + bumper_d / 2;
y_pad_rear  = total_depth_y - pad_margin - bumper_d / 2;

// ------------------------------------------------------------------------------
// CRADLE STAND FOOT MODULE (COMPACT, SOLID, 2x 13mm PAD RECESSES)
// ------------------------------------------------------------------------------
module cradle_stand_foot() {
    difference() {
        // Main solid body: 2D side profile extruded along X using multmatrix mapping
        multmatrix([
            [0, 0, 1, 0],
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 0, 1]
        ])
        linear_extrude(height = foot_w) {
            polygon(points = [
                [0, 0],                                    // Front bottom
                [total_depth_y, 0],                        // Rear heel bottom
                [total_depth_y, 2.5],                      // Rear heel fillet point
                [y_spine_outer_top, z_spine_outer_top],    // Spine top outer edge
                [y_spine_inner_top, z_spine_inner_top],    // Spine top inner edge
                [y_lip_top, z_lip_top],                    // Front lip top inner edge
                (front_toe_len > 0 ? [front_toe_len, base_floor] : [0, z_lip_top]),
                (front_toe_len > 0 ? [0, 3.0] : [0, 0])
            ]);
        }
        
        // 1. Backward-Tilted Display Slot Cutout (-tilt_angle around X)
        translate([-1, slot_pivot_y, base_floor]) {
            rotate([-tilt_angle, 0, 0]) {
                // Main pocket
                cube([foot_w + 2, effective_slot_w, 200]);
                
                // Chamfered lead-in funnel on top of front lip
                translate([0, -1.0, front_lip_h - 2.0])
                    rotate([20, 0, 0])
                        cube([foot_w + 2, effective_slot_w + 4.0, 16.0]);
            }
        }
        
        // 2. Exactly 2 circular recesses of 13.0 mm diameter for anti-slip pads (Z = 0)
        // Solid flat bottom with no rectangular channel/trench
        if (enable_bumpers) {
            // Front 13mm circular recess
            translate([foot_w / 2, y_pad_front, -0.1])
                cylinder(h = bumper_depth + 0.1, d = bumper_d, $fn = 60);
                
            // Rear 13mm circular recess
            translate([foot_w / 2, y_pad_rear, -0.1])
                cylinder(h = bumper_depth + 0.1, d = bumper_d, $fn = 60);
        }

        // 3. M3 Panel Mounting Screw Holes & Rear Tool-Access Counterbores
        // Drilled perpendicular to panel backplate inside the tilted slot coordinate frame
        if (screw_holes_mode != "none") {
            x_holes = (screw_holes_mode == "seam") ? 
                      [foot_w/2 - hole_pitch/2, foot_w/2 + hole_pitch/2] : 
                      [foot_w/2];
            
            translate([0, slot_pivot_y, base_floor]) {
                rotate([-tilt_angle, 0, 0]) {
                    for (hx = x_holes) {
                        translate([hx, effective_slot_w, screw_rim_inset]) {
                            rotate([-90, 0, 0]) {
                                // M3 Screw clearance hole through flange
                                translate([0, 0, -0.5])
                                    cylinder(h = flange_thick + 1.0, d = screw_hole_d);
                                    
                                // Countersink cone (DIN 7991) at the rear seating face
                                if (screw_head_style == "countersunk") {
                                    translate([0, 0, flange_thick - cs_depth])
                                        cylinder(h = cs_depth + 0.05, d1 = screw_hole_d, d2 = cs_outer_d);
                                }
                                
                                // Rear tool-access counterbore well extending through outer spine
                                translate([0, 0, flange_thick])
                                    cylinder(h = 60.0, d = screw_cb_d);
                            }
                        }
                    }
                }
            }
        }
    }
}

// ------------------------------------------------------------------------------
// CRADLE MULTI-PART BED LAYOUTS
// ------------------------------------------------------------------------------
module cradle_stand_pair(spacing = 6.0) {
    translate([-foot_w - spacing/2, 0, 0])
        cradle_stand_foot();
        
    translate([spacing/2, 0, 0])
        cradle_stand_foot();
}

module cradle_stand_set4(spacing = 6.0) {
    for (ix = [-1, 1]) {
        for (iy = [0, 1]) {
            translate([ix * (foot_w/2 + spacing/2) + (ix < 0 ? -foot_w/2 : 0), iy * (total_depth_y + spacing), 0])
                cradle_stand_foot();
        }
    }
}

// ------------------------------------------------------------------------------
// BOLT-ON M3 SCREW-MOUNT KICKSTAND LEG
// ------------------------------------------------------------------------------
// Fastens with M3 screws directly into bottom corner holes (6mm inset)
// or bottom seam holes (12mm pitch).
// Designed to print flat on its side for maximum layer-line bending strength.
module screw_mount_kickstand(tilt = tilt_angle) {
    leg_thick    = 10.0;  // Width of kickstand leg (mm)
    flange_h     = 24.0;  // Height of attachment plate
    flange_w     = 24.0;  // Width across seam
    hole_pitch   = 12.0;  // Distance between seam holes (or single corner)
    leg_reach    = 76.0;  // Reach behind backplate
    
    // Geometry printed flat on print bed (X-Y plane) for fast, support-free printing
    difference() {
        union() {
            // Triangular truss body
            linear_extrude(height = leg_thick) {
                polygon(points = [
                    [0, 0],
                    [flange_h, 0],
                    [flange_h, 3.2],
                    [6.0, leg_reach],
                    [0, leg_reach],
                    [0, 0]
                ]);
            }
            
            // Mounting flange plate extending across screw hole positions
            translate([0, -flange_w/2 + leg_thick/2, 0])
                cube([flange_h, flange_w, 3.2]);
                
            // Round foot pad at leg tip
            translate([3.0, leg_reach - 4.0, leg_thick/2])
                cylinder(h = leg_thick, r = 8.0, center = true);
        }
        
        // M3 Screw clearance holes (3.4 mm) with flush countersinks
        // Two holes spaced 12.0mm apart (seam mounting)
        for (oy = [-hole_pitch/2, hole_pitch/2]) {
            translate([6.0, oy + leg_thick/2, -0.1]) {
                cylinder(h = 3.4, d = 3.4);
                translate([0, 0, 3.2 - 1.8 + 0.1])
                    cylinder(h = 1.9, d1 = 3.4, d2 = 6.6);
            }
        }
        // Single central hole option
        translate([16.0, leg_thick/2, -0.1]) {
            cylinder(h = 3.4, d = 3.4);
            translate([0, 0, 3.2 - 1.8 + 0.1])
                cylinder(h = 1.9, d1 = 3.4, d2 = 6.6);
        }
        
        // Circular bumper recess on foot pad (13mm pad)
        translate([3.0, leg_reach - 4.0, leg_thick - bumper_depth])
            cylinder(h = bumper_depth + 0.1, d = bumper_d);
    }
}

module screw_mount_pair(spacing = 8.0) {
    translate([0, -spacing/2 - 12.0, 0]) screw_mount_kickstand();
    translate([0, spacing/2 + 12.0, 0]) screw_mount_kickstand();
}

// ------------------------------------------------------------------------------
// ASSEMBLED 3D PREVIEW WITH SIMULATED 7-SEGMENT DIGIT (BACKWARD VIEWING TILT)
// ------------------------------------------------------------------------------
module display_stand_assembled_preview() {
    digit_w = 138.4;
    digit_h = 230.4;
    digit_d = 18.5;
    
    // Stand feet placed under left and right sides of the digit
    foot_spacing = digit_w - 38.0;
    
    // Left Foot (Sky Blue)
    translate([-foot_spacing/2 - foot_w/2, 0, 0])
        color("#0284c7")
            cradle_stand_foot();
            
    // Right Foot (Sky Blue)
    translate([foot_spacing/2 - foot_w/2, 0, 0])
        color("#0284c7")
            cradle_stand_foot();
            
    // 13mm Rubber Bumpers preview (Charcoal circles)
    color("#1e293b") {
        for (fx = [-foot_spacing/2, foot_spacing/2]) {
            translate([fx, y_pad_front, -0.8]) cylinder(h = 0.8, d = bumper_d);
            translate([fx, y_pad_rear, -0.8]) cylinder(h = 0.8, d = bumper_d);
        }
    }
    
    // Position of the display seated in the cradle slot (LEANING BACKWARD by tilt_angle)
    translate([0, slot_pivot_y, base_floor]) {
        rotate([-tilt_angle, 0, 0]) {
            // Simulated 7-Segment Digit Panel
            // Outer Enclosure (Matte Charcoal)
            color("#0f172a", 0.95) {
                difference() {
                    translate([-digit_w/2, 0, 0])
                        cube([digit_w, digit_d, digit_h]);
                    
                    // Recessed front face for segments
                    translate([-digit_w/2 + 2, -0.1, 2])
                        cube([digit_w - 4, 1.0, digit_h - 4]);
                }
            }
            
            // Glowing LED Segments (Displaying '7' in Neon Cyan)
            color("#38bdf8") {
                // Top segment (A)
                translate([0, -0.4, digit_h - 23.2])
                    cube([65, 0.8, 12], center = true);
                // Top-right segment (B)
                translate([30, -0.4, digit_h - 60])
                    cube([12, 0.8, 62], center = true);
                // Bottom-right segment (C)
                translate([30, -0.4, digit_h - 135])
                    cube([12, 0.8, 62], center = true);
            }
            
            // Bottom segment position marker (Segment D, unlit dark slate)
            // Visually confirms 100% clearance above the front lip!
            color("#334155") {
                translate([0, -0.4, 23.2])
                    cube([65, 0.8, 12], center = true);
            }
            
            // Backplate detail (Slate)
            color("#334155")
                translate([-digit_w/2 + 3, digit_d - 5.5, 3])
                    cube([digit_w - 6, 5.3, digit_h - 6]);
        }
    }
    
    // Table surface preview (Translucent frosted glass)
    color("#e2e8f0", 0.25)
        translate([0, 20, -0.5])
            cube([digit_w * 1.5, 100, 1.0], center = true);
}

// ------------------------------------------------------------------------------
// ASSEMBLED 3D PREVIEW: DISPLAY STAND BOLTED ACROSS PANEL SEAM (REPLACING U-BRACKET)
// ------------------------------------------------------------------------------
module display_stand_seam_preview() {
    digit_w = 138.4;
    digit_h = 230.4;
    digit_d = 18.5;
    
    // Stand foot placed directly centered across the seam (X = 0)
    translate([-foot_w/2, 0, 0])
        color("#0284c7")
            cradle_stand_foot();
            
    // 13mm Rubber Bumpers preview (Charcoal circles)
    color("#1e293b") {
        translate([0, y_pad_front, -0.8]) cylinder(h = 0.8, d = bumper_d);
        translate([0, y_pad_rear, -0.8]) cylinder(h = 0.8, d = bumper_d);
    }
    
    // Tilted Panels seated in the stand slot
    translate([0, slot_pivot_y, base_floor]) {
        rotate([-tilt_angle, 0, 0]) {
            // Simulated M3 Screws bolting through the stand rear spine into the backplate
            color("#cbd5e1") {
                for (hx = [-hole_pitch/2, hole_pitch/2]) {
                    translate([hx, effective_slot_w + flange_thick, screw_rim_inset]) {
                        rotate([90, 0, 0]) {
                            cylinder(h = 10.0, d = 3.0);
                            cylinder(h = 1.8, d1 = 6.0, d2 = 3.0);
                        }
                    }
                }
            }
            
            // Digit 1 on Left (X in [-digit_w, 0])
            translate([-digit_w, 0, 0]) {
                color("#0f172a", 0.95)
                    cube([digit_w - 0.2, digit_d, digit_h]);
                // Glowing Cyan segments ('4')
                color("#38bdf8") {
                    translate([digit_w/2, -0.4, digit_h/2]) cube([60, 0.8, 12], center=true);
                    translate([digit_w/2 - 28, -0.4, digit_h*0.72]) cube([12, 0.8, 55], center=true);
                    translate([digit_w/2 + 28, -0.4, digit_h/2]) cube([12, 0.8, 120], center=true);
                }
            }
            
            // Digit 2 on Right (X in [0, digit_w])
            translate([0.2, 0, 0]) {
                color("#0f172a", 0.95)
                    cube([digit_w - 0.2, digit_d, digit_h]);
                // Glowing Red segments ('2')
                color("#ef4444") {
                    translate([digit_w/2, -0.4, digit_h - 23.2]) cube([65, 0.8, 12], center=true);
                    translate([digit_w/2 + 28, -0.4, digit_h*0.72]) cube([12, 0.8, 55], center=true);
                    translate([digit_w/2, -0.4, digit_h/2]) cube([65, 0.8, 12], center=true);
                    translate([digit_w/2 - 28, -0.4, digit_h*0.28]) cube([12, 0.8, 55], center=true);
                    translate([digit_w/2, -0.4, 23.2]) cube([65, 0.8, 12], center=true);
                }
            }
        }
    }
    
    // Table surface preview (Translucent frosted glass)
    color("#e2e8f0", 0.25)
        translate([0, 20, -0.5])
            cube([digit_w * 2.2, 100, 1.0], center = true);
}

// ==============================================================================
// TOP-LEVEL SELECTOR
// ==============================================================================
if (part == 1 || part == "cradle_single") {
    color("#0284c7") cradle_stand_foot();
} else if (part == 2 || part == "cradle_pair") {
    color("#0284c7") cradle_stand_pair(spacing = 6.0);
} else if (part == 3 || part == "cradle_set4") {
    color("#0284c7") cradle_stand_set4(spacing = 6.0);
} else if (part == 4 || part == "screw_single") {
    color("#0284c7") screw_mount_kickstand();
} else if (part == 5 || part == "screw_pair") {
    color("#0284c7") screw_mount_pair(spacing = 8.0);
} else if (part == 6 || part == "preview_seam" || part == "assembly") {
    display_stand_seam_preview();
} else if (part == 7 || part == "preview_single") {
    display_stand_assembled_preview();
} else if (part == 8 || part == "rear_view") {
    rotate([0, 0, 180])
        color("#0284c7")
            cradle_stand_foot();
} else if (part == 9 || part == "bottom_view") {
    rotate([180, 0, 0])
        color("#0284c7")
            cradle_stand_foot();
}
