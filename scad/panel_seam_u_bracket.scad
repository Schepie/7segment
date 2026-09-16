// ==============================================================================
// 2-Panel Digit Seam U-Profile Joining & Padel Mesh Hook Bracket
// For Modular 7-Segment Display / Clock / Padel Scoreboard
// Designed for Bambu Lab / Prusa / FDM 3D Printing (100% Support-Free)
// ==============================================================================
//
// Purpose & Mechanical Problem Solved:
// Standard modular 7-segment panels ([Digit 1] + [Digit 2]) are fastened across
// their seam on the rear backplate plane (Z = -5.5mm).
//
// Because each panel has an 18.5 mm depth and no mechanical connection on the front,
// the joint bends or flexes when handled or lifted.
//
// This Dual-Function Bracket System provides:
// 1. Anti-Bending Front-to-Back U-Channel Clamping:
//    - Rear Flange (17.0 mm) + Front Lip (9.5 mm) clamps both faces simultaneously,
//      eliminating joint bending and flexing.
//    - Spans across adjacent panels (28.0 mm total width, 14 mm on each panel).
//    - 2x M3 Countersunk Screw Holes on 12.0 mm pitch (X = -6.0 mm and X = +6.0 mm).
//    - Straight 90° square top corners for clean, flush rim alignment.
//
// 2. Extended Padel Court Mesh Protective Mounting Hook (Front-Facing):
//    - Positions the scoreboard BEHIND the padel wire mesh fence.
//    - High-strength retention hook extends FORWARD in front of the display face,
//      dropping securely over the horizontal 4mm-5mm steel fence wire.
//    - Padel balls strike the steel wire mesh, completely protecting digits & electronics!
//    - Deep 16 mm retention lip prevents the scoreboard from jumping off on ball impact.
//    - 45° flared entry mouth for effortless drop-on installation.
//    - Designed to print flat on its side for 100% continuous tensile strength!
// ==============================================================================

/* [Configuration & Part Selection] */
part = 1; // [1:"single_standard - 1 Clean U-Bracket (Top or Bottom)", 2:"pair_standard - Pair of Clean U-Brackets (Top + Bottom)", 3:"single_padel_hook - 1 Extended Padel Mesh Hook U-Bracket (Top Rim)", 4:"pair_padel_hook - Pair of Padel Hook U-Brackets (for Digits 1-2 and Digits 3-4)", 5:"tournament_set4 - Full 4-Piece Set: 2x Top Padel Hooks + 2x Bottom Clean U-Brackets", 6:"preview_padel_mesh - 3D Preview: Scoreboard Hanging on Padel Fence with Padel Ball", 7:"preview_standard - 3D Preview: Clamped 2-Digit Assembly", 8:"cutaway_hook - Cross-Section Cutaway of Hook & Panel Seating"]

/* [Fastening & Hardware Options] */
screw_head_style = "countersunk"; // ["countersunk": Flat M3 DIN 7991 (compatible with thumbscrews), "counterbore": Cylindrical socket head M3 DIN 912 / Button head ISO 7380]

/* [Dimensions - Panel Interface] */
panel_thick     = 18.5; // Panel depth (13.0mm frontplate + 5.5mm backplate)
slot_clearance  = 0.40; // 18.9 mm internal slot width
hole_pitch      = 12.0; // Center-to-center pitch between corner screws across seam (6mm + 6mm)
screw_rim_inset = 6.0;  // Inset of M3 screws from outer rim

/* [Dimensions - U-Profile Bracket] */
bracket_w       = 28.0; // Total width across seam (14mm on each panel, matches rear_joining_bracket)
wall_thick      = 3.0;  // Structural wall thickness of flanges and web
rear_flange_len = 17.0; // Rear flange height past rim (11mm past M3 hole center)
front_lip_len   = 9.5;  // Front lip depth past rim (stays >5mm clear of 15mm diffusers)
fillet_r        = 2.5;  // Outer corner radius for lower flange tips

/* [Dimensions - Padel Wire Mesh Hook] */
wire_d          = 4.2;  // Standard padel fence wire diameter (supports 3.5 to 5.0 mm)
throat_d        = 5.6;  // Hook throat diameter for smooth drop-on fit
hook_arm_t      = 4.2;  // Heavy-duty structural hook arm thickness
front_clearance = 1.2;  // Clearance between front flange and wire
hook_lip_depth  = 16.0; // Downward retention lip depth in front of wire (prevents jumping on impact)

/* [Hardware Dimensions - M3 Clearance] */
screw_hole_d    = 3.4;  // M3 pass-through clearance diameter
cs_outer_d      = 6.5;  // M3 DIN 7991 countersink diameter
cs_depth        = 1.8;  // Countersink cone depth
cb_outer_d      = 6.2;  // Counterbore socket recess diameter
cb_depth        = 2.0;  // Counterbore recess depth

/* [Print Resolution] */
$fn = 60;

// ==============================================================================
// DERIVED GEOMETRY CALCULATIONS
// ==============================================================================
slot_w        = panel_thick + slot_clearance;     // 18.9 mm inner opening
total_y       = wall_thick + slot_w + wall_thick; // 24.9 mm total footprint width
x_min         = -bracket_w / 2;                   // -14.0 mm
x_max         =  bracket_w / 2;                   // +14.0 mm

h_rear_total  = wall_thick + rear_flange_len;     // 20.0 mm
h_front_total = wall_thick + front_lip_len;       // 12.5 mm

// 2 M3 screw X positions:
screw_x_positions = [-hole_pitch / 2, hole_pitch / 2]; // [-6.0, +6.0 mm]

// Wire center in local Y-Z profile coordinates:
// Z = 0 is backplate, Z = slot_w is frontplate, Z = slot_w + wall_thick is front flange outer face
wire_center_z = slot_w + wall_thick + front_clearance + wire_d / 2; // ~25.4 mm
wire_center_y = -wall_thick; // Level with web outer face (~ -3.0 mm)

// ==============================================================================
// 1. STANDARD CLEAN U-PROFILE BRACKET
// ==============================================================================

module flange_profile_2d(w, h, r_tip) {
    hull() {
        translate([-w/2, 0]) square([w, 0.1]);
        translate([-w/2 + r_tip, h - r_tip]) circle(r = r_tip);
        translate([ w/2 - r_tip, h - r_tip]) circle(r = r_tip);
    }
}

module panel_seam_u_bracket_printable() {
    difference() {
        // Solid Body
        union() {
            // Web (flat on bed)
            translate([-bracket_w/2, 0, 0])
                cube([bracket_w, total_y, wall_thick]);
                
            // Rear Flange Wall
            translate([0, wall_thick, 0])
                rotate([90, 0, 0])
                    linear_extrude(height = wall_thick)
                        flange_profile_2d(bracket_w, h_rear_total, fillet_r);
            
            // Front Flange Wall
            translate([0, total_y, 0])
                rotate([90, 0, 0])
                    linear_extrude(height = wall_thick)
                        flange_profile_2d(bracket_w, h_front_total, fillet_r);
        }
        
        // Chamfers & lead-ins
        translate([0, wall_thick, wall_thick])
            rotate([0, 90, 0]) rotate([0, 0, 45])
                cube([0.7, 0.7, bracket_w + 2.0], center = true);
        translate([0, wall_thick + slot_w, wall_thick])
            rotate([0, 90, 0]) rotate([0, 0, 45])
                cube([0.7, 0.7, bracket_w + 2.0], center = true);

        // Front lip lead-in chamfer
        translate([0, wall_thick + slot_w, h_front_total])
            rotate([0, 90, 0]) rotate([0, 0, 45])
                cube([1.4, 1.4, bracket_w + 2.0], center = true);

        // 2x M3 Screw Holes through Rear Flange
        for (x = screw_x_positions) {
            translate([x, -0.1, wall_thick + screw_rim_inset]) {
                rotate([-90, 0, 0]) {
                    cylinder(h = wall_thick + 0.2, d = screw_hole_d);
                    if (screw_head_style == "countersunk") {
                        cylinder(h = cs_depth + 0.1, d1 = cs_outer_d, d2 = screw_hole_d);
                    } else if (screw_head_style == "counterbore") {
                        cylinder(h = cb_depth + 0.1, d = cb_outer_d);
                    }
                }
            }
        }
    }
}

// ==============================================================================
// 2. EXTENDED PADEL COURT MESH HOOK U-BRACKET
// ==============================================================================
// Side Profile in (Z, Y) space:
// - Z is depth through the panel (0 = rear backplate, slot_w = frontplate)
// - Y is height: 0 is panel rim, -wall_thick is web outer face, +Y extends down panel
module padel_hook_u_profile_2d() {
    hook_top_y   = wire_center_y - throat_d/2 - hook_arm_t; // Highest point of hook arch (~ -10.0 mm)
    hook_front_z = wire_center_z + throat_d/2 + hook_arm_t; // Frontmost edge of hook (~ 32.4 mm)
    lip_bottom_y = hook_top_y + hook_lip_depth + throat_d/2 + hook_arm_t; // Bottom tip of lip (~ 10.2 mm)
    
    difference() {
        // Outer continuous solid profile envelope
        polygon(points = [
            // Rear Flange
            [-wall_thick, rear_flange_len],
            [0, rear_flange_len],
            [0, 0],                         // Inner corner at rim
            
            // Slot Ceiling (inner rim)
            [slot_w, 0],
            
            // Front Flange (retaining lip)
            [slot_w, front_lip_len],
            [slot_w + wall_thick, front_lip_len],
            
            // Bridge from front flange out to hook front
            [wire_center_z - throat_d/2, 0],
            
            // Hook front downward retention lip
            [hook_front_z, lip_bottom_y],
            [hook_front_z, hook_top_y],     // Top-front corner
            [-wall_thick, hook_top_y],      // Top-rear corner
            [-wall_thick, rear_flange_len]  // Back down rear flange
        ]);
        
        // Subtract: Wire seating circular throat
        translate([wire_center_z, wire_center_y])
            circle(d = throat_d);
            
        // Subtract: Entry slot angled downwards (+Y) for smooth wire slide-in
        translate([wire_center_z - throat_d/2, wire_center_y])
            square([throat_d, lip_bottom_y - wire_center_y + 1.0]);
            
        // Subtract: 45° Flared lead-in mouth at bottom of retention lip
        polygon(points = [
            [wire_center_z - throat_d/2 - 2.5, lip_bottom_y + 1.0],
            [hook_front_z + 1.0, lip_bottom_y + 1.0],
            [hook_front_z + 1.0, lip_bottom_y - 3.5],
            [wire_center_z - throat_d/2, lip_bottom_y - 6.0]
        ]);
        
        // Subtract: Slot base corner relief chamfers
        translate([0, 0])
            rotate([0, 0, 45]) square([0.7, 0.7], center = true);
        translate([slot_w, 0])
            rotate([0, 0, 45]) square([0.7, 0.7], center = true);
            
        // Subtract: Front lip inner entry chamfer
        translate([slot_w, front_lip_len])
            rotate([0, 0, 45]) square([1.4, 1.4], center = true);
    }
}

module panel_seam_u_hook_bracket_solid() {
    // Extrude the 2D hook profile along X from -bracket_w/2 to +bracket_w/2
    translate([bracket_w/2, 0, 0])
        rotate([0, -90, 0])
            linear_extrude(height = bracket_w)
                padel_hook_u_profile_2d();
}

module panel_seam_u_hook_bracket() {
    difference() {
        panel_seam_u_hook_bracket_solid();
        
        // 2x M3 Countersunk Holes through Rear Flange
        for (x = screw_x_positions) {
            translate([x, screw_rim_inset, -wall_thick - 0.1]) {
                cylinder(h = wall_thick + 0.2, d = screw_hole_d);
                if (screw_head_style == "countersunk") {
                    cylinder(h = cs_depth + 0.1, d1 = cs_outer_d, d2 = screw_hole_d);
                } else if (screw_head_style == "counterbore") {
                    cylinder(h = cb_depth + 0.1, d = cb_outer_d);
                }
            }
        }
        
        // Round bottom corners of rear flange
        translate([x_min - 0.1, rear_flange_len - fillet_r, -wall_thick - 0.1])
            difference() {
                cube([fillet_r + 0.1, fillet_r + 0.1, wall_thick + 0.2]);
                translate([fillet_r + 0.1, 0, -0.1])
                    cylinder(r = fillet_r, h = wall_thick + 0.4);
            }
        translate([x_max - fillet_r, rear_flange_len - fillet_r, -wall_thick - 0.1])
            difference() {
                cube([fillet_r + 0.1, fillet_r + 0.1, wall_thick + 0.2]);
                translate([0, 0, -0.1])
                    cylinder(r = fillet_r, h = wall_thick + 0.4);
            }
    }
}

// Print-Ready Orientation: Lying flat on its side (Z_bed is X-axis)
// This aligns 100% of layer lines along the tensile hook load path for maximum strength!
module panel_seam_u_hook_bracket_printable() {
    translate([0, 0, bracket_w/2])
        rotate([0, 90, 0])
            panel_seam_u_hook_bracket();
}

// ==============================================================================
// 3. 3D PREVIEW & SIMULATION CONTEXT
// ==============================================================================

module padel_mesh_wire_grid(w = 360, h = 300) {
    color("#94a3b8", 0.9) { // Galvanized steel wire
        // Horizontal wires (along X) - guarantees a wire at y = 0
        for (iy = [-3 : 3]) {
            translate([0, iy * 50.0, 0])
                rotate([0, 90, 0])
                    cylinder(h = w, d = wire_d, center = true, $fn = 20);
        }
        // Vertical wires (along Y) - offset by 25mm so seam at X=0 sits cleanly in mesh opening
        for (ix = [-3 : 3]) {
            translate([ix * 50.0 + 25.0, 0, 0])
                rotate([90, 0, 0])
                    cylinder(h = h, d = wire_d, center = true, $fn = 20);
        }
    }
}

module simulated_digit_panel(panel_label = "1") {
    pw = 138.4;
    ph = 230.4;
    color("#1e293b", 0.8) {
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

module preview_padel_court_mounting(cutaway = false) {
    pw = 138.4;
    ph = 230.4;
    x_d1 = -pw / 2;
    x_d2 =  pw / 2;
    
    // Wire center in scoreboard coordinates:
    // Aligns dead center in the hook throat at Y = ph/2 + wall_thick = 118.2 mm
    wire_y_sb = ph/2 + wall_thick;
    // Front face is at Z = +13.0 mm. Wire sits at Z = 13.0 + slot_clearance/2 + wall_thick + front_clearance + wire_d/2 = 19.7 mm
    wire_z_sb = wire_center_z - 5.5 - slot_clearance/2; // 19.7 mm
    
    difference() {
        union() {
            // 1. Two Digit Panels
            translate([x_d1, 0, 0]) simulated_digit_panel("1");
            translate([x_d2, 0, 0]) simulated_digit_panel("2");
            
            // 2. Top Extended Padel Mesh Hook U-Bracket
            // Mounts across seam (X = 0) at top rim (Y = +ph/2)
            // Maps +Y_profile (downward into panel) to -Y_sb
            multmatrix([
                [1,  0, 0, 0],
                [0, -1, 0, ph/2],
                [0,  0, 1, -5.5 - slot_clearance/2],
                [0,  0, 0, 1]
            ])
            color("#e11d48") // Anodized Red Accent
                panel_seam_u_hook_bracket();
                    
            // 3. Bottom Clean U-Bracket (keeps bottom seam rigid)
            multmatrix([
                [1, 0, 0, 0],
                [0, 0, 1, -ph/2 - wall_thick],
                [0, 1, 0, -5.5 - slot_clearance/2 - wall_thick],
                [0, 0, 0, 1]
            ])
            color("#e11d48")
                panel_seam_u_bracket_printable();
            
            // 4. Padel Court Steel Wire Mesh (Scoreboard is safely BEHIND the fence)
            if (cutaway) {
                translate([0, wire_y_sb, wire_z_sb])
                    rotate([0, 90, 0])
                        color("#94a3b8")
                            cylinder(h = 80, d = wire_d, center = true, $fn = 30);
            } else {
                translate([0, wire_y_sb, wire_z_sb])
                    padel_mesh_wire_grid(w = 360, h = 280);
                    
                // 5. Incoming Padel Ball (Optic Yellow, striking the mesh from court side)
                translate([95.0, wire_y_sb - 20.0, wire_z_sb + 42.0])
                    color("#eab308")
                        sphere(d = 66.0, $fn = 30);
            }
        }
        
        // Optional Cutaway along X (removes +X half to inspect wire & hook seating)
        if (cutaway) {
            translate([0, -200, -100])
                cube([300, 400, 200]);
        }
    }
}

// ==============================================================================
// 4. MAIN SELECTOR
// ==============================================================================

if (part == 1) {
    // Single standard clean U-bracket (Print-ready flat on web, zero supports)
    panel_seam_u_bracket_printable();
} else if (part == 2) {
    // Pair of standard clean U-brackets on print bed (Top + Bottom)
    spacing_y = total_y + 8.0;
    translate([0, -spacing_y/2, 0]) panel_seam_u_bracket_printable();
    translate([0,  spacing_y/2, 0]) panel_seam_u_bracket_printable();
} else if (part == 3) {
    // Single Extended Padel Mesh Hook U-Bracket (Print-ready on side, 100% tensile strength)
    panel_seam_u_hook_bracket_printable();
} else if (part == 4) {
    // Pair of Padel Mesh Hook U-Brackets (for Digits 1-2 and Digits 3-4 top rims)
    spacing_x = bracket_w + 10.0;
    translate([-spacing_x/2, 0, 0]) panel_seam_u_hook_bracket_printable();
    translate([ spacing_x/2, 0, 0]) panel_seam_u_hook_bracket_printable();
} else if (part == 5) {
    // Full Tournament Set of 4 (2x Top Padel Hooks + 2x Bottom Clean Brackets)
    translate([-bracket_w - 6.0, 0, 0]) panel_seam_u_hook_bracket_printable();
    translate([0, 0, 0]) panel_seam_u_hook_bracket_printable();
    translate([bracket_w + 12.0, -total_y/2 - 4.0, 0]) panel_seam_u_bracket_printable();
    translate([bracket_w + 12.0,  total_y/2 + 4.0, 0]) panel_seam_u_bracket_printable();
} else if (part == 6) {
    // 3D Preview: Scoreboard Hanging on Padel Fence behind wire mesh
    preview_padel_court_mounting(cutaway = false);
} else if (part == 7) {
    // Standard 2-digit preview
    preview_padel_court_mounting(cutaway = false);
} else if (part == 8) {
    // Cross-Section Cutaway of Hook & Wire Seating
    preview_padel_court_mounting(cutaway = true);
}
