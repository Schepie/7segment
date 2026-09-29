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
//
// 3. Integrated Carrying Strap Mount (Top-Facing vs Rear-Facing):
//    - Top-Facing Eye ("top", Picture 1): Monolithic triangular strap eye on top roof.
//    - Rear-Facing Eye ("rear", Picture 2): Monolithic strap eye extending horizontally
//      from the back of the bracket with dual 45° transition tapers.
//      - The top of the bracket is 100% flat and flush.
//      - Direct screw access: The rear flange extends straight down from below the 45°
//        taper (at Y = 0), leaving >6.0 mm of flat clearance above the M3 screw centers
//        and 8.5 mm of radial clearance to the eye tongue so screwdrivers and Allen keys
//        have 100% unobstructed, straight-line coaxial access!
//    - 100% support-free printing flat on its side with continuous perimeters!
// ==============================================================================

/* [Configuration & Part Selection] */
part = 6; // [1:"single_standard - 1 Clean U-Bracket (Top or Bottom)", 2:"pair_standard - Pair of Clean U-Brackets (Top + Bottom)", 3:"single_hook_top_eye - 1 Hook Bracket with Top Eye (Picture 1)", 4:"pair_hook_top_eye - Pair of Hook Brackets with Top Eye", 5:"tournament_set4_top - Full Set: 2x Top Eye Hooks + 2x Bottom Clean", 6:"single_hook_rear_eye - 1 Hook Bracket with Rear Eye (Picture 2)", 7:"pair_hook_rear_eye - Pair of Hook Brackets with Rear Eye (Picture 2)", 8:"tournament_set4_rear - Full Set: 2x Rear Eye Hooks + 2x Bottom Clean", 9:"preview_strap_bracket - Closeup 3D Preview: Hook Bracket with 5x9mm Strap Hook", 10:"preview_padel_mesh - 3D Preview: Scoreboard with Hooks on Fence", 11:"preview_standard - 3D Preview: Clamped 2-Digit Assembly", 12:"cutaway_hook - Cross-Section Cutaway of Hook & Wire Seating"]

/* [Fastening & Hardware Options] */
screw_head_style = "countersunk"; // ["countersunk": Flat M3 DIN 7991 (compatible with thumbscrews), "counterbore": Cylindrical socket head M3 DIN 912 / Button head ISO 7380]

/* [Integrated Carrying Strap Eye] */
strap_eye_mount       = true;   // Integrate monolithic triangular strap eye directly onto U-hook bracket
strap_eye_position    = "rear"; // ["rear": Rear-Facing Strap Eye (on the back, Picture 2), "top": Top-Facing Strap Eye (on the roof, Picture 1)]
strap_eye_h           = 24.0;   // Length / height of triangular eye (mm)
strap_eye_thick       = 5.0;    // Bar thickness for the hook to grab (mm)
strap_eye_top_w       = 20.0;   // Outer width of top/tip arch (mm)
strap_eye_hole_w      = 12.0;   // Inside opening width (mm, ample clearance for 9mm hook with 3mm free play)
strap_hook_t          = 5.0;    // Strap hook thickness (mm)
strap_hook_h          = 9.0;    // Strap hook height/width (mm)

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
wire_d                  = 4.2;  // Standard padel fence wire diameter (supports 3.5 to 5.0 mm)
vertical_wire_clearance = 5.5;  // Clearance for vertical fence wire sitting between panel and horizontal wire (+5.5mm extra clearance)
throat_d                = 5.6;  // Hook throat diameter for smooth drop-on fit
hook_arm_t              = 4.2;  // Heavy-duty structural hook arm thickness
front_clearance         = 1.2;  // Extra clearance between vertical wire and bracket front flange
hook_lip_depth          = 16.0; // Downward retention lip depth in front of wire (prevents jumping on impact)

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
// Padel court welded mesh construction: vertical wires come FIRST (between panel and horizontal wire)
// Distance from front flange outer face = front_clearance + vertical_wire_clearance (~6.7 mm)
// Distance from panel face = wall_thick + front_clearance + vertical_wire_clearance + wire_d/2 (~11.8 mm)
wire_center_z = slot_w + wall_thick + front_clearance + vertical_wire_clearance + wire_d / 2; // ~30.9 mm
wire_center_y = -wall_thick; // Level with web outer face (~ -3.0 mm)
hook_top_y    = wire_center_y - throat_d/2 - hook_arm_t; // Highest point of hook arch (~ -10.0 mm)
hook_front_z  = wire_center_z + throat_d/2 + hook_arm_t; // Frontmost edge of hook (~ 38.0 mm)
lip_bottom_y  = hook_top_y + hook_lip_depth + throat_d/2 + hook_arm_t; // Bottom tip of lip (~ 13.0 mm)

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

// ==============================================================================
// 3A. INTEGRATED TOP-FACING STRAP EYE (Picture 1)
// ==============================================================================

module integrated_strap_eye_solid(
    tri_h       = strap_eye_h,
    tri_base_w  = bracket_w,
    tri_top_w   = strap_eye_top_w,
    tri_thick   = strap_eye_thick
) {
    z_center   = slot_w / 2;
    
    // Main arch in XY, extruded along Z
    translate([0, 0, z_center - tri_thick/2]) {
        linear_extrude(height = tri_thick) {
            hull() {
                translate([-tri_base_w/2 + 3.0, hook_top_y + 0.1]) circle(r = 3.0);
                translate([ tri_base_w/2 - 3.0, hook_top_y + 0.1]) circle(r = 3.0);
                translate([0, hook_top_y - tri_h + tri_top_w/2]) circle(d = tri_top_w);
            }
        }
    }
    
    // Longitudinal gusset along Z (resists pulling forward/backward)
    hull() {
        translate([0, hook_top_y - 3.0, z_center])
            cube([tri_base_w - 6.0, 6.0, tri_thick], center = true);
        translate([0, hook_top_y + 0.1, z_center])
            cube([tri_base_w - 2.0, 0.2, tri_thick + 8.0], center = true);
    }
    // Lateral buttress to outer edges (resists twisting & lateral bending)
    hull() {
        translate([0, hook_top_y - 2.0, z_center])
            cube([tri_base_w, 4.0, tri_thick], center = true);
        translate([0, hook_top_y + 0.1, z_center])
            cube([tri_base_w, 0.2, slot_w], center = true);
    }
}

module integrated_strap_eye_hole(
    tri_h       = strap_eye_h,
    tri_top_w   = strap_eye_top_w,
    tri_thick   = strap_eye_thick,
    hole_w      = strap_eye_hole_w
) {
    z_center   = slot_w / 2;
    
    // Generous inside opening: 12mm wide x 14mm tall, accommodates 5mm x 9mm hook with ease
    translate([0, 0, z_center - tri_thick/2 - 5.0]) {
        linear_extrude(height = tri_thick + 10.0) {
            hull() {
                translate([-hole_w/2 + 2.0, hook_top_y - 4.0]) circle(r = 2.0);
                translate([ hole_w/2 - 2.0, hook_top_y - 4.0]) circle(r = 2.0);
                translate([0, hook_top_y - tri_h + tri_top_w/2]) circle(d = hole_w);
            }
        }
    }
}

// ==============================================================================
// 3B. INTEGRATED REAR-FACING STRAP EYE (Picture 2)
// ==============================================================================
// Extends horizontally backwards (-Z) with dual 45° transition tapers:
// - Top taper blends smoothly into the flat top roof (Y = hook_top_y).
// - Bottom taper terminates at Y = 0.0 mm (panel rim), leaving the entire rear flange
//   (Y = 0 to 17mm) 100% flat and unobstructed for M3 screws and screwdrivers!

module integrated_strap_eye_rear_solid(
    tri_h       = strap_eye_h,
    tri_base_w  = bracket_w,
    tri_top_w   = strap_eye_top_w,
    tri_thick   = strap_eye_thick
) {
    z_base   = -wall_thick;             // -3.0 mm
    y_center = hook_top_y / 2;          // -5.0 mm
    y_top    = y_center - tri_thick/2;  // -7.5 mm
    y_bot    = y_center + tri_thick/2;  // -2.5 mm
    
    // 1. Main horizontal eye tongue extending in -Z
    translate([0, y_top, 0]) {
        rotate([-90, 0, 0]) {
            linear_extrude(height = tri_thick) {
                hull() {
                    translate([-tri_base_w/2 + 3.0, -z_base - 0.1]) circle(r = 3.0);
                    translate([ tri_base_w/2 - 3.0, -z_base - 0.1]) circle(r = 3.0);
                    translate([0, -z_base + tri_h - tri_top_w/2]) circle(d = tri_top_w);
                }
            }
        }
    }
    
    // 2. Top 45-degree taper (sloping up-right from y = -7.5 mm to roof at y = -10.0 mm)
    t_top = abs(hook_top_y - y_top); // 2.5 mm
    hull() {
        translate([0, y_top, z_base + 0.1])
            cube([tri_base_w, 0.1, 0.1], center = true);
        translate([0, y_top, z_base - t_top])
            cube([tri_base_w - 4.0, 0.1, 0.1], center = true);
        translate([0, hook_top_y, z_base + 0.1])
            cube([tri_base_w, 0.1, 0.1], center = true);
    }
    
    // 3. Bottom 45-degree taper (sloping down-right from y = -2.5 mm to rear flange at y = 0.0 mm)
    t_bot = abs(0.0 - y_bot); // 2.5 mm
    hull() {
        translate([0, y_bot, z_base + 0.1])
            cube([tri_base_w, 0.1, 0.1], center = true);
        translate([0, y_bot, z_base - t_bot])
            cube([tri_base_w - 4.0, 0.1, 0.1], center = true);
        translate([0, 0.0, z_base + 0.1])
            cube([tri_base_w, 0.1, 0.1], center = true);
    }
}

module integrated_strap_eye_rear_hole(
    tri_h       = strap_eye_h,
    tri_top_w   = strap_eye_top_w,
    tri_thick   = strap_eye_thick,
    hole_w      = strap_eye_hole_w
) {
    z_base   = -wall_thick;
    y_center = hook_top_y / 2;
    
    // Through-hole through vertical thickness of rear eye
    translate([0, y_center - 10.0, 0]) {
        rotate([-90, 0, 0]) {
            linear_extrude(height = tri_thick + 20.0) {
                hull() {
                    translate([-hole_w/2 + 2.0, -z_base + 4.0]) circle(r = 2.0);
                    translate([ hole_w/2 - 2.0, -z_base + 4.0]) circle(r = 2.0);
                    translate([0, -z_base + tri_h - tri_top_w/2]) circle(d = hole_w);
                }
            }
        }
    }
}

// Full Hook Bracket with Configurable Strap Eye Position (Top or Rear)
module panel_seam_u_hook_bracket(with_eye = strap_eye_mount, eye_pos = strap_eye_position) {
    difference() {
        union() {
            panel_seam_u_hook_bracket_solid();
            if (with_eye) {
                if (eye_pos == "rear") {
                    integrated_strap_eye_rear_solid();
                } else {
                    integrated_strap_eye_solid();
                }
            }
        }
        
        // 2x M3 Countersunk Holes through Rear Flange
        // Completely flat, unobstructed access on rear flange from Y = 0 to 17 mm
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
            
        // Inside opening of triangular strap eye
        if (with_eye) {
            if (eye_pos == "rear") {
                integrated_strap_eye_rear_hole();
            } else {
                integrated_strap_eye_hole();
            }
        }
    }
}

// Print-Ready Orientation: Lying flat on its side (Z_bed is X-axis)
// This aligns 100% of layer lines along the tensile hook load path for maximum strength!
module panel_seam_u_hook_bracket_printable(with_eye = strap_eye_mount, eye_pos = strap_eye_position) {
    translate([0, 0, bracket_w/2])
        rotate([0, 90, 0])
            panel_seam_u_hook_bracket(with_eye = with_eye, eye_pos = eye_pos);
}

// ==============================================================================
// 4. 3D PREVIEW & SIMULATION CONTEXT
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
        // Positioned at Z = -wire_d because vertical wires come FIRST (between panel and horizontal wire)
        for (ix = [-3 : 3]) {
            translate([ix * 50.0 + 25.0, 0, -wire_d])
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

module preview_padel_court_mounting(cutaway = false, eye_pos = strap_eye_position) {
    pw = 138.4;
    ph = 230.4;
    x_d1 = -pw / 2;
    x_d2 =  pw / 2;
    
    // Wire center in scoreboard coordinates:
    wire_y_sb = ph/2 + wall_thick;
    wire_z_sb = wire_center_z - 5.5 - slot_clearance/2; // ~25.2 mm
    
    difference() {
        union() {
            // 1. Two Digit Panels
            translate([x_d1, 0, 0]) simulated_digit_panel("1");
            translate([x_d2, 0, 0]) simulated_digit_panel("2");
            
            // 2. Top Extended Padel Mesh Hook U-Bracket
            multmatrix([
                [1,  0, 0, 0],
                [0, -1, 0, ph/2],
                [0,  0, 1, -5.5 - slot_clearance/2],
                [0,  0, 0, 1]
            ]) {
                color("#e11d48") // Anodized Red Accent
                    panel_seam_u_hook_bracket(with_eye = strap_eye_mount, eye_pos = eye_pos);
            }
                    
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
                // Horizontal wire sitting in hook throat
                translate([0, wire_y_sb, wire_z_sb])
                    rotate([0, 90, 0])
                        color("#94a3b8")
                            cylinder(h = 80, d = wire_d, center = true, $fn = 30);
                // Vertical wire sitting first against the panel
                translate([-25.0, wire_y_sb, wire_z_sb - wire_d])
                    rotate([90, 0, 0])
                        color("#64748b")
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

module preview_strap_bracket(eye_pos = strap_eye_position) {
    color("#e11d48")
        panel_seam_u_hook_bracket(with_eye = strap_eye_mount, eye_pos = eye_pos);
    if (strap_eye_mount) {
        if (eye_pos == "rear") {
            y_center = hook_top_y / 2;
            z_tip    = -wall_thick - strap_eye_h + strap_eye_top_w/2;
            // Exact 5mm x 9mm Strap Hook seated in the rear triangular eye
            color("#22c55e", 0.95)
                translate([0, y_center, z_tip])
                    rotate([0, 90, 0])
                        linear_extrude(height = 10.0, center = true)
                            resize([strap_hook_h, strap_hook_t])
                                circle(d = strap_hook_h, $fn=40);
        } else {
            z_center = slot_w / 2;
            // Exact 5mm x 9mm Strap Hook seated in the top arch of the integrated triangle
            color("#22c55e", 0.95)
                translate([0, hook_top_y - strap_eye_h + strap_eye_top_w/2, z_center])
                    rotate([90, 0, 0])
                        linear_extrude(height = 10.0, center = true)
                            resize([strap_hook_h, strap_hook_t])
                                circle(d = strap_hook_h, $fn=40);
        }
    }
}

// ==============================================================================
// 5. MAIN SELECTOR
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
    // Single Hook Bracket with Top Eye (Picture 1)
    panel_seam_u_hook_bracket_printable(with_eye = strap_eye_mount, eye_pos = "top");
} else if (part == 4) {
    // Pair of Hook Brackets with Top Eye (for Digits 1-2 and Digits 3-4 top rims)
    spacing_x = bracket_w + 10.0;
    translate([-spacing_x/2, 0, 0]) panel_seam_u_hook_bracket_printable(with_eye = strap_eye_mount, eye_pos = "top");
    translate([ spacing_x/2, 0, 0]) panel_seam_u_hook_bracket_printable(with_eye = strap_eye_mount, eye_pos = "top");
} else if (part == 5) {
    // Full Tournament Set: 2x Top Eye Hooks + 2x Bottom Clean U-Brackets
    spacing_x = bracket_w + 10.0;
    translate([-spacing_x/2, 0, 0]) panel_seam_u_hook_bracket_printable(with_eye = strap_eye_mount, eye_pos = "top");
    translate([ spacing_x/2, 0, 0]) panel_seam_u_hook_bracket_printable(with_eye = strap_eye_mount, eye_pos = "top");
    translate([-spacing_x/2, total_y + 12.0, 0]) panel_seam_u_bracket_printable();
    translate([ spacing_x/2, total_y + 12.0, 0]) panel_seam_u_bracket_printable();
} else if (part == 6) {
    // Single Hook Bracket with Rear Eye (Picture 2, Print-ready on side, zero supports)
    panel_seam_u_hook_bracket_printable(with_eye = strap_eye_mount, eye_pos = "rear");
} else if (part == 7) {
    // Pair of Hook Brackets with Rear Eye (Picture 2)
    spacing_x = bracket_w + 10.0;
    translate([-spacing_x/2, 0, 0]) panel_seam_u_hook_bracket_printable(with_eye = strap_eye_mount, eye_pos = "rear");
    translate([ spacing_x/2, 0, 0]) panel_seam_u_hook_bracket_printable(with_eye = strap_eye_mount, eye_pos = "rear");
} else if (part == 8) {
    // Full Tournament Set: 2x Rear Eye Hooks + 2x Bottom Clean U-Brackets
    spacing_x = bracket_w + 10.0;
    translate([-spacing_x/2, 0, 0]) panel_seam_u_hook_bracket_printable(with_eye = strap_eye_mount, eye_pos = "rear");
    translate([ spacing_x/2, 0, 0]) panel_seam_u_hook_bracket_printable(with_eye = strap_eye_mount, eye_pos = "rear");
    translate([-spacing_x/2, total_y + 12.0, 0]) panel_seam_u_bracket_printable();
    translate([ spacing_x/2, total_y + 12.0, 0]) panel_seam_u_bracket_printable();
} else if (part == 9) {
    // Closeup 3D Preview: Hook Bracket with 5x9mm Hook (reflects strap_eye_position)
    preview_strap_bracket(eye_pos = strap_eye_position);
} else if (part == 10) {
    // 3D Preview: Scoreboard with Hooks on Padel Fence
    preview_padel_court_mounting(cutaway = false, eye_pos = strap_eye_position);
} else if (part == 11) {
    // Standard 2-digit preview with Hooks
    preview_padel_court_mounting(cutaway = false, eye_pos = strap_eye_position);
} else if (part == 12) {
    // Cross-Section Cutaway of Hook & Wire Seating
    preview_padel_court_mounting(cutaway = true, eye_pos = strap_eye_position);
}
