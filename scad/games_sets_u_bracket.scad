// ==============================================================================
// Games & Sets 3-Panel Unified U-Profile Bridge Bracket
// For Modular 7-Segment Padel Scoreboard / Bambu Lab / FDM 3D Printing
// ==============================================================================
//
// Purpose & Mechanical Problem Solved:
// In the 5-module padel scoreboard ([Digit 1] + [Digit 2] + [Games & Sets] + [Digit 3] + [Digit 4]),
// panels were previously only joined on the rear backplate plane (Z = -5.5mm) across
// each seam with independent flat brackets.
//
// Because the assembly has an 18.5 mm panel depth and NO structural connection
// on the front face, the joint acts like a hinge: handling, lifting, or standing
// causes the scoreboard to flex and bend at the seams between the Games & Sets panel
// and the adjacent digits.
//
// This Unified U-Profile Bridge Bracket solves the problem permanently:
// 1. Spans across all 3 central modules in ONE continuous monolithic piece (84 mm wide):
//    - Left Team 1 Digit (Digit 2)
//    - Center Games & Sets Panel (56 mm wide)
//    - Right Team 2 Digit (Digit 3)
// 2. High-Rigidity U-Channel Cross-Section:
//    - Rear Flange: Bolts through the 4 M3 corner screw positions (X = -34, -22, +22, +34 mm)
//      directly into the brass heat-set inserts.
//    - Rim Web: Spans across the panel rim (18.9 mm slot width).
//    - Front Flange: Extends 9.5 mm down the front face of all 3 panels.
// 3. Eliminates Bending:
//    - Clamping both the front face (Z = +13.0 mm) and rear face (Z = -5.5 mm) creates
//      a rigid channel beam with high area moment of inertia, completely locking the 3
//      panels in plane.
// 4. Universal Top & Bottom Symmetry:
//    - Can be used interchangeably on the top rim and bottom rim.
//    - Printing a pair (2 brackets) fully boxes the scoreboard structure.
//    - Web face is 100% solid, flush, and smooth.
// 5. 100% Support-Free Printing:
//    - Prints flat on its web with the U-channel opening pointing upward.
// ==============================================================================

/* [Configuration & Part Selection] */
part = 1; // [1:"single - 1 U-Profile Bracket (Print-ready on web, solid & smooth)", 2:"pair - Pair of U-Profile Brackets (Top + Bottom on bed)", 3:"preview_assembled - 3D Assembly Preview: Clamped 3-Panel Scoreboard", 4:"preview_top_only - 3D Preview: Top Bracket Only", 5:"cutaway_profile - Cross-Section Cutaway View"]

/* [Fastening & Hardware Options] */
screw_head_style = "countersunk"; // ["countersunk": Flat M3 DIN 7991 (compatible with thumbscrews), "counterbore": Cylindrical socket head M3 DIN 912 / Button head ISO 7380]

/* [Dimensions - Panel Interface] */
panel_thick     = 18.5; // Panel depth (13.0mm frontplate + 5.5mm backplate)
slot_clearance  = 0.40; // 18.9 mm internal slot width
spacer_width    = 56.0; // Central Games & Sets module width
screw_inset     = 6.0;  // Inset of M3 screws from panel side edge
screw_rim_inset = 6.0;  // Inset of M3 screws from outer rim

/* [Dimensions - U-Profile Bracket] */
wall_thick      = 3.0;  // Structural wall thickness of flanges and web
outer_margin    = 8.0;  // Bracket extension past outer screws (X = +/-34mm)
rear_flange_len = 17.0; // Rear flange height past rim (11mm past M3 hole center)
front_lip_len   = 9.5;  // Front lip depth past rim (stays >5mm clear of 15mm diffusers)
fillet_r        = 2.5;  // Outer corner radius

/* [Front Flange Cutout - SETS Text Clearance] */
enable_sets_cutout = true;  // Cutout in front lip to expose "SETS" text on Games & Sets panel
sets_cutout_w      = 24.0;  // Width of cutout along X (centered at X = 0)
sets_cutout_depth  = 7.0;   // Cutout depth from lip tip (7.0mm leaves 2.5mm lip, 9.5mm is flush to rim)
sets_cutout_r      = 2.0;   // Fillet radius for cutout inside corners

/* [Hardware Dimensions - M3 Clearance] */
screw_hole_d    = 3.4;  // M3 pass-through clearance diameter
cs_outer_d      = 6.5;  // M3 DIN 7991 countersink diameter
cs_depth        = 1.8;  // Countersink cone depth
cb_outer_d      = 6.2;  // Counterbore socket recess diameter
cb_depth        = 2.0;  // Counterbore recess depth

/* [Rubber Bumper Recess Parameters] */
bumper_d        = 8.5;  // Standard 8mm rubber bumpon diameter
bumper_depth    = 0.8;  // Recess depth into web outer face

/* [Print Resolution] */
$fn = 60;

// ==============================================================================
// DERIVED GEOMETRY CALCULATIONS
// ==============================================================================
slot_w        = panel_thick + slot_clearance;          // 18.9 mm inner opening
total_y       = wall_thick + slot_w + wall_thick;      // 24.9 mm total footprint width
bracket_w     = (34.0 + outer_margin) * 2;             // 84.0 mm total length
x_min         = -bracket_w / 2;                        // -42.0 mm
x_max         =  bracket_w / 2;                        // +42.0 mm

// Total heights including web floor in print orientation:
h_rear_total  = wall_thick + rear_flange_len;          // 20.0 mm
h_front_total = wall_thick + front_lip_len;            // 12.5 mm

// 4 M3 screw X positions:
screw_x_positions = [-34.0, -22.0, 22.0, 34.0];
bumper_x_positions = [-28.0, 28.0];

// ==============================================================================
// 1. PRINT-READY U-PROFILE BRACKET CORE
// ==============================================================================

module flange_profile_2d(w, h, r_tip) {
    // 2D profile in X-Z: straight square corners at the web (Z = 0), rounded at the tips
    hull() {
        translate([-w/2, 0]) square([w, 0.1]);
        translate([-w/2 + r_tip, h - r_tip]) circle(r = r_tip);
        translate([ w/2 - r_tip, h - r_tip]) circle(r = r_tip);
    }
}

module games_sets_u_bracket_printable() {
    difference() {
        // --- 1. SEAMLESS SOLID BODY ---
        union() {
            // A. Base Web (resting flat on bed, Z = 0 to wall_thick)
            // Straight square corners along the top rim
            translate([-bracket_w/2, 0, 0])
                cube([bracket_w, total_y, wall_thick]);
                
            // B. Rear Flange Wall (at Y in [0, wall_thick], rising to h_rear_total)
            translate([0, wall_thick, 0])
                rotate([90, 0, 0])
                    linear_extrude(height = wall_thick)
                        flange_profile_2d(bracket_w, h_rear_total, fillet_r);
            
            // C. Front Flange Wall (at Y in [wall_thick + slot_w, total_y], rising to h_front_total)
            translate([0, total_y, 0])
                rotate([90, 0, 0])
                    linear_extrude(height = wall_thick)
                        flange_profile_2d(bracket_w, h_front_total, fillet_r);
        }
        
        // --- 2. CHAMFERS & LEAD-IN GUIDES ---
        
        // Internal corner lead-in chamfers (0.5mm) at the bottom corners of the slot
        translate([0, wall_thick, wall_thick])
            rotate([0, 90, 0])
                rotate([0, 0, 45])
                    cube([0.7, 0.7, bracket_w + 2.0], center = true);
        translate([0, wall_thick + slot_w, wall_thick])
            rotate([0, 90, 0])
                rotate([0, 0, 45])
                    cube([0.7, 0.7, bracket_w + 2.0], center = true);

        // Front lip lead-in chamfer (45° mouth at top-inner lip)
        // Makes sliding the bracket onto the assembled scoreboard effortless
        translate([0, wall_thick + slot_w, h_front_total])
            rotate([0, 90, 0])
                rotate([0, 0, 45])
                    cube([1.4, 1.4, bracket_w + 2.0], center = true);

        // --- 3. 4x M3 SCREW CLEARANCE HOLES & COUNTERSINKS ---
        // Located at Z = wall_thick + screw_rim_inset = 9.0 mm
        // Hole axis is perpendicular through rear flange (along Y)
        for (x = screw_x_positions) {
            translate([x, -0.1, wall_thick + screw_rim_inset]) {
                rotate([-90, 0, 0]) {
                    // Clearance shank hole
                    cylinder(h = wall_thick + 0.2, d = screw_hole_d);
                    
                    // Head countersink / counterbore on outside rear face (Y = 0)
                    if (screw_head_style == "countersunk") {
                        // DIN 7991 countersink
                        cylinder(h = cs_depth + 0.1, d1 = cs_outer_d, d2 = screw_hole_d);
                    } else if (screw_head_style == "counterbore") {
                        // Socket head counterbore
                        cylinder(h = cb_depth + 0.1, d = cb_outer_d);
                    }
                }
            }
        }
        // --- 4. FRONT FLANGE "SETS" TEXT CLEARANCE CUTOUT ---
        if (enable_sets_cutout && sets_cutout_depth > 0) {
            z_floor = max(wall_thick, h_front_total - sets_cutout_depth);
            z_top   = h_front_total + 1.0;
            w       = sets_cutout_w;
            r       = min(sets_cutout_r, (z_top - z_floor)/2, w/4);
            
            // Subtracted through the front flange (Y in [wall_thick + slot_w - 0.5, total_y + 0.5])
            translate([0, total_y + 0.5, 0])
                rotate([90, 0, 0])
                    linear_extrude(height = wall_thick + 1.0)
                        hull() {
                            translate([-w/2 + r, z_floor + r]) circle(r = r);
                            translate([ w/2 - r, z_floor + r]) circle(r = r);
                            translate([-w/2, z_top - 0.1]) square([w, 0.1]);
                        }
                        
            // Lead-in chamfer for the remaining shallow lip at the bottom of the cutout
            if (z_floor > wall_thick + 0.5) {
                translate([0, wall_thick + slot_w, z_floor])
                    rotate([0, 90, 0])
                        rotate([0, 0, 45])
                            cube([1.4, 1.4, max(0.1, w - 2*r)], center = true);
            }
        }
        // (Web outside face remains 100% solid, flat, and smooth with zero holes or markings)
    }
}

// ==============================================================================
// 2. MOUNTED PANEL COORDINATES FOR 3D PREVIEW
// ==============================================================================
module games_sets_u_bracket_mounted() {
    // In print coordinates:
    // Y in [0, wall_thick] is Rear Flange.
    // Y in [wall_thick, wall_thick + slot_w] is Panel Slot.
    // Y in [wall_thick + slot_w, total_y] is Front Flange.
    // Z = 0 is web outside, Z = wall_thick is inner rim.
    //
    // In scoreboard coordinates:
    // Panel backplate is at Z = -5.5 mm.
    // Panel frontplate is at Z = +13.0 mm.
    // Rim is at Y = +/-115.2 mm.
    //
    // Map:
    // We want print-Y to map to scoreboard-Z (Rear to Front):
    // Z_sb = (print_Y - wall_thick) - 5.5 - slot_clearance/2
    // We want print-Z to map to scoreboard-Y (Web to Flanges):
    // For bottom bracket: inner rim is at Y = -115.2 mm, flanges extend in +Y.
    // Rotate +90 around X:
    // X -> X, Y -> -Z, Z -> Y (flanges extend in +Y, but Y is inverted).
    // Let's use an explicit transformation:
    translate([0, -wall_thick, -5.5 - slot_clearance/2 - wall_thick])
        rotate([-90, 0, 0])
            games_sets_u_bracket_printable();
}

// ==============================================================================
// 3. 3D ASSEMBLY PREVIEW & CONTEXT
// ==============================================================================

module simulated_digit_panel(panel_label = "2") {
    pw = 138.4;
    ph = 230.4;
    
    color("#1e293b", 0.75) {
        difference() {
            translate([-pw/2, -ph/2, -5.5])
                cube([pw, ph, 18.5]);
            translate([-pw/2 + 10, -ph/2 + 15, 0.5])
                cube([pw - 20, ph - 30, 13.0]);
        }
    }
    color("#f8fafc", 0.6)
        translate([0, 0, 12.4])
            linear_extrude(0.6)
                text(panel_label, size = 110, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
}

module simulated_games_sets_panel() {
    gw = 56.0;
    gh = 230.4;
    
    color("#0f172a", 0.8) {
        difference() {
            translate([-gw/2, -gh/2, -5.5])
                cube([gw, gh, 18.5]);
            for (col = [-11, 11]) {
                for (y = [-91.67 : 16.667 : 41.67])
                    translate([col, y, 0]) cylinder(h = 14, r = 4.5);
                for (y = [75.0, 91.67])
                    translate([col, y, 0]) cylinder(h = 14, r = 4.5);
            }
        }
    }
    for (col = [-11, 11]) {
        for (y = [-91.67 : 16.667 : 41.67])
            translate([col, y, 12.5]) color(col < 0 ? "#00d2ff" : "#ff3366") cylinder(h = 0.8, r = 4.2);
        for (y = [75.0, 91.67])
            translate([col, y, 12.5]) color("#ffb300") cylinder(h = 0.8, r = 4.2);
    }
    // Frontplate Text: "SETS" (Y = +105.0) and "GAMES" (Y = +58.33)
    color("#f8fafc", 0.95) {
        translate([0, 105.0, 12.7])
            linear_extrude(0.6)
                text("SETS", size = 4.0, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
        translate([0, 58.33, 12.7])
            linear_extrude(0.6)
                text("GAMES", size = 3.8, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
    }
}

module preview_3panel_assembly(show_top = true, show_bottom = true, cutaway_y = false) {
    pw = 138.4;
    gw = 56.0;
    ph = 230.4;
    
    x_d2 = - (gw/2 + pw/2); // -97.2 mm
    x_gs = 0.0;             // Center
    x_d3 =   (gw/2 + pw/2); // +97.2 mm
    
    difference() {
        union() {
            // 1. Three Scoreboard Panels
            translate([x_d2, 0, 0]) simulated_digit_panel("2");
            translate([x_gs, 0, 0]) simulated_games_sets_panel();
            translate([x_d3, 0, 0]) simulated_digit_panel("3");
            
            // 2. Top U-Profile Bracket
            // Maps print-Z (rim-to-flanges) downward into -Y, print-Y to scoreboard-Z
            if (show_top) {
                multmatrix([
                    [1, 0,  0, 0],
                    [0, 0, -1, ph/2 + wall_thick],
                    [0, 1,  0, -5.5 - slot_clearance/2 - wall_thick],
                    [0, 0,  0, 1]
                ])
                color("#e11d48") // Vibrant Anodized Red Accent
                    games_sets_u_bracket_printable();
            }
            
            // 3. Bottom U-Profile Bracket
            // Maps print-Z (rim-to-flanges) upward into +Y, print-Y to scoreboard-Z
            if (show_bottom) {
                multmatrix([
                    [1, 0, 0, 0],
                    [0, 0, 1, -ph/2 - wall_thick],
                    [0, 1, 0, -5.5 - slot_clearance/2 - wall_thick],
                    [0, 0, 0, 1]
                ])
                color("#e11d48")
                    games_sets_u_bracket_printable();
            }
        }
        
        // Cross-section cutaway: remove +X half to view Y-Z cross-section profile of bracket & panel
        if (cutaway_y) {
            translate([0, -200, -100])
                cube([300, 400, 200]);
        }
    }
}

// ==============================================================================
// 4. MAIN SELECTOR
// ==============================================================================

if (part == 1) {
    // Single U-profile bracket (Print-ready flat on web, 100% solid & smooth, zero supports)
    games_sets_u_bracket_printable();
} else if (part == 2) {
    // Pair of U-profile brackets arranged on print bed (Top + Bottom)
    spacing_y = total_y + 10.0;
    translate([0, -spacing_y/2, 0])
        games_sets_u_bracket_printable();
    translate([0, spacing_y/2, 0])
        games_sets_u_bracket_printable();
} else if (part == 3) {
    // 3D Assembly Preview: Top & Bottom Brackets Clamping 3 Panels
    preview_3panel_assembly(show_top = true, show_bottom = true, cutaway_y = false);
} else if (part == 4) {
    // 3D Preview: Top Bracket Only
    preview_3panel_assembly(show_top = true, show_bottom = false, cutaway_y = false);
} else if (part == 5) {
    // Cross-Section Cutaway View
    preview_3panel_assembly(show_top = true, show_bottom = true, cutaway_y = true);
}
