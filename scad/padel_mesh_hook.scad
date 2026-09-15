// ==============================================================================
// Padel Court Mesh Protective Mounting Hook System
// For Modular 7-Segment Scoreboard / Bambu Lab / FDM 3D Printing
// ==============================================================================
//
// Purpose:
// Mounts the modular 7-segment scoreboard safely on the BACK / OUTSIDE of the
// standard 50x50 mm padel court iron wire mesh fence.
// - The LED digits face INTO the court through the 50x50 mm square grid openings.
// - Padel balls hit the inside of the steel mesh, completely protecting the acrylic
//   diffusers, electronics, and digits from high-speed impact!
//
// Mounting Options Supported:
// 1. Top Seam Hook ("Hoekschroeven"): Mounts across the top seam (12.0 mm pitch)
//    between adjacent panels using M3 screws or tool-free M3 thumbscrews.
// 2. Top Corner Hook: Mounts to individual outer top corners (single M3 hole).
// 3. VESA 50x50 Over-the-Top Hook: Bolts to the 50x50 mm VESA pattern on the back
//    of any digit, extending a rigid truss arm up and over the top panel edge.
//
// Printing & Strength:
// - All hook profiles are designed to print FLAT ON THEIR SIDE on the print bed.
// - This aligns the FDM continuous extrusion layer lines along the tensile load
//   path of the hook, giving 100% resistance against layer-shear and ball vibrations!
// ==============================================================================

/* [Configuration & Part Selection] */
part = 1; // [1:"seam_pair - Pair of Top Seam Hooks (12mm pitch across panel joints)", 2:"corner_pair - Pair of Single Top Corner Hooks", 3:"vesa_hook - VESA 50x50 Over-the-Top Hook", 4:"seam_single - 1 Top Seam Hook", 5:"corner_single - 1 Top Corner Hook", 6:"preview_seam - 3D Preview: Panel on Padel Wire Mesh with Seam Hook", 7:"preview_vesa - 3D Preview: Panel on Padel Wire Mesh with VESA Hook"]

/* [Padel Wire Mesh Parameters (Standard FIP)] */
mesh_pitch      = 50.0; // Standard 50x50 mm wire grid
wire_d          = 4.2;  // Steel wire diameter (supports 3.5mm to 5.0mm)
throat_d        = 5.6;  // Hook throat diameter (smooth drop/snap over wire)
hook_lip_depth  = 16.0; // Downward retention lip depth (prevents jumping on ball impact)
entry_flare     = 8.5;  // Flared mouth width for effortless alignment onto wire

/* [Display Panel Sizing (from 7segment_pogo.scad)] */
panel_thick     = 18.5; // Total depth of panel (13.0mm frontplate + 5.5mm backplate)
top_screw_y_off = 6.0;  // Top M3 screw hole distance from top panel rim (Y = 109.2 vs 115.2)
seam_pitch      = 12.0; // Pitch between screws across seam (X = +/-6.0 mm)
bracket_t       = 3.2;  // Base plate thickness (matches rear joining bracket)

/* [Print Resolution] */
$fn = 40;

// ==============================================================================
// 2D HOOK PROFILE (Side View: Y-Z Plane)
// ==============================================================================
// Origin (0,0) is at the rear mounting face (Z = 0) at the M3 screw hole center (Y = 0)
// Panel top rim is at Y = +top_screw_y_off (6.0 mm)
// Panel front face is at Z = +panel_thick (18.5 mm)
// Hook reaches up past Y = top_screw_y_off, forward to Z = panel_thick + wire_d/2,
// and drops down in front of the wire.

hook_arm_t = 4.2; // Structural thickness of the hook arm
front_clearance = 1.0; // Gap between front of panel and wire mesh

module hook_side_profile_2d() {
    wire_center_z = panel_thick + front_clearance + wire_d/2; // Z position of wire center (~21.6 mm)
    hook_top_y    = top_screw_y_off + throat_d/2 + hook_arm_t; // Highest point of hook (~13.0 mm)
    
    difference() {
        // Outer continuous solid profile
        polygon([
            // Base plate on rear of panel
            [0, -10.0],                          // Bottom of base plate
            [bracket_t, -10.0],                  // Base plate thickness
            [bracket_t, top_screw_y_off],        // Rises to top rim of panel
            
            // Forward bridge reaching over the top of the panel
            [wire_center_z, top_screw_y_off],
            [wire_center_z + throat_d/2 + hook_arm_t, top_screw_y_off],
            [wire_center_z + throat_d/2 + hook_arm_t, hook_top_y],
            [0, hook_top_y],                     // Top rear corner
        ]);
        
        // Subtract: Wire seating pocket (centered at wire_center_z)
        translate([wire_center_z, top_screw_y_off])
            circle(d = throat_d);
            
        // Subtract: Entry throat slot angled downwards for slide-in entry
        translate([wire_center_z - throat_d/2, -1.0])
            square([throat_d, top_screw_y_off + 1.0]);
            
        // Subtract: Flared lead-in mouth at bottom of front lip
        polygon([
            [wire_center_z - throat_d/2 - 2.0, -1.1],
            [wire_center_z + throat_d/2 + 4.0, -1.1],
            [wire_center_z + throat_d/2, 3.5],
            [wire_center_z - throat_d/2, 3.5]
        ]);
    }
}

// ------------------------------------------------------------------------------
// 1. TOP SEAM HOOK BRACKET (12.0 mm Hole Pitch)
// ------------------------------------------------------------------------------
// Mounts across the top seam between two panels. Replaces or bolts over the top
// seam bracket. Width = 28.0 mm (spans X = -14 to +14 mm).
module seam_hook_bracket() {
    bracket_w = 28.0;
    
    difference() {
        // Extrude the 2D hook profile along X
        rotate([0, -90, -90])
            linear_extrude(height = bracket_w, center = true)
                hook_side_profile_2d();
                
        // 2x Countersunk M3 screw holes at X = +/- 6.0 mm (seam pitch = 12.0 mm)
        for (x = [-seam_pitch/2, seam_pitch/2]) {
            translate([x, -top_screw_y_off + top_screw_y_off, -0.1]) {
                // Main M3 clearance hole (3.4 mm)
                cylinder(h = bracket_t + 0.3, d = 3.4, $fn = 24);
                // 90-degree countersink for flathead screw or thumbscrew seating
                translate([0, 0, bracket_t - 1.8 + 0.1])
                    cylinder(h = 1.9, d1 = 3.4, d2 = 6.4, $fn = 24);
            }
        }
        
        // Central clearance notch between hook prongs (reduces weight, fits vertical mesh wire)
        translate([-bracket_w/2 + 5.0, top_screw_y_off - 1.0, 5.0])
            cube([bracket_w - 10.0, 20.0, panel_thick + 10.0]);
    }
}

// ------------------------------------------------------------------------------
// 2. TOP CORNER HOOK BRACKET (Single M3 Hole)
// ------------------------------------------------------------------------------
// Mounts to any outer top corner M3 screw hole. Width = 15.0 mm.
module corner_hook_bracket() {
    bracket_w = 15.0;
    
    difference() {
        // Extrude profile
        rotate([0, -90, -90])
            linear_extrude(height = bracket_w, center = true)
                hook_side_profile_2d();
                
        // Single central M3 countersunk hole at (0, 0)
        translate([0, 0, -0.1]) {
            cylinder(h = bracket_t + 0.3, d = 3.4, $fn = 24);
            translate([0, 0, bracket_t - 1.8 + 0.1])
                cylinder(h = 1.9, d1 = 3.4, d2 = 6.4, $fn = 24);
        }
        
        // Outer corner chamfer
        translate([-bracket_w/2 - 0.1, -10.1, -0.1])
            cube([3.0, 5.0, bracket_t + 1.0]);
    }
}

// ------------------------------------------------------------------------------
// 3. VESA 50x50 OVER-THE-TOP HOOK BRACKET
// ------------------------------------------------------------------------------
// Mounts to the 4 VESA holes (50x50 mm) in the center of any digit.
// An upright truss arm reaches 95 mm up over the top panel rim and hooks the wire.
module vesa_mesh_hook() {
    vesa_p = 50.0;
    vesa_plate_w = 64.0;
    vesa_plate_h = 64.0;
    vesa_t = 3.5;
    reach_up = 115.2 - 25.0 + 5.0; // 95.2 mm from top VESA holes (Y = 25) to top rim (Y = 115.2)
    wire_z = panel_thick + front_clearance + wire_d/2;
    
    difference() {
        union() {
            // 1. Base plate covering 50x50 VESA pattern
            translate([0, 0, vesa_t/2])
                hull() {
                    for (x = [-vesa_plate_w/2 + 4, vesa_plate_w/2 - 4]) {
                        for (y = [-vesa_plate_h/2 + 4, vesa_plate_h/2 - 4]) {
                            translate([x, y, 0])
                                cylinder(h = vesa_t, r = 4.0, center = true, $fn = 24);
                        }
                    }
                }
                
            // 2. Upright truss arm extending from VESA plate over top of panel
            translate([0, reach_up/2 + 25.0, vesa_t/2])
                cube([20.0, reach_up, vesa_t], center = true);
                
            // Triangular stiffening ribs along upright arm
            for (x = [-8.0, 8.0]) {
                translate([x, 25.0, vesa_t])
                    rotate([0, 90, 0])
                        linear_extrude(height = 3.0, center = true)
                            polygon([[0, 0], [reach_up, 0], [0, 10.0]]);
            }
            
            // 3. Forward over-the-top hook at top of truss arm
            translate([0, 115.2, 0]) {
                // Horizontal bridge across top of panel
                translate([0, 0, wire_z/2])
                    cube([24.0, 8.0, wire_z], center = true);
                    
                // Front hook drop with wire pocket
                translate([0, -throat_d/2 - 2.0, wire_z])
                    difference() {
                        cube([24.0, hook_lip_depth + 4.0, 6.0], center = true);
                        // Wire cylinder
                        translate([0, -hook_lip_depth/2 + throat_d/2 + 2.0, 0])
                            cylinder(h = 10.0, d = throat_d, center = true, $fn = 30);
                    }
            }
        }
        
        // 4x VESA M3 mounting holes
        for (x = [-vesa_p/2, vesa_p/2]) {
            for (y = [-vesa_p/2, vesa_p/2]) {
                translate([x, y, -0.1]) {
                    cylinder(h = vesa_t + 0.3, d = 3.4, $fn = 24);
                    // Counterbore for screw head
                    translate([0, 0, vesa_t - 2.0 + 0.1])
                        cylinder(h = 2.1, d = 6.4, $fn = 24);
                }
            }
        }
        
        // Center weight relief hole
        translate([0, 0, -0.1])
            cylinder(h = vesa_t + 0.3, d = 20.0, $fn = 36);
    }
}

// ------------------------------------------------------------------------------
// PRINT BED LAYOUTS (Oriented Flat for Optimal Layer Strength)
// ------------------------------------------------------------------------------
// Seam Hook Pair (laid flat on side for 100% tensile strength along hook curve)
module seam_hook_pair_on_bed() {
    // 1st Hook laid flat
    rotate([0, 90, 0])
        seam_hook_bracket();
        
    // 2nd Hook laid flat beside it
    translate([bracket_t + panel_thick + 8.0, 0, 0])
        rotate([0, 90, 0])
            seam_hook_bracket();
}

// Corner Hook Pair
module corner_hook_pair_on_bed() {
    rotate([0, 90, 0])
        corner_hook_bracket();
    translate([bracket_t + panel_thick + 8.0, 0, 0])
        rotate([0, 90, 0])
            corner_hook_bracket();
}

// ------------------------------------------------------------------------------
// ASSEMBLED 3D PREVIEW (Scoreboard behind Padel Court Iron Mesh)
// ------------------------------------------------------------------------------
module padel_mesh_wire_grid(w = 260, h = 300) {
    color("#94a3b8", 0.9) { // Steel galvanized wire
        // Horizontal wires
        for (y = [-h/2 : mesh_pitch : h/2]) {
            translate([0, y, 0])
                rotate([0, 90, 0])
                    cylinder(h = w, d = wire_d, center = true, $fn = 20);
        }
        // Vertical wires
        for (x = [-w/2 : mesh_pitch : w/2]) {
            translate([x, 0, 0])
                cylinder(h = h, d = wire_d, center = true, $fn = 20);
        }
    }
}

module padel_ball_sim(pos = [0, 0, 0]) {
    color("#eab308") // Tennis/Padel optic yellow
        translate(pos)
            sphere(d = 66.0, $fn = 30); // 66 mm diameter ball
}

module assembled_preview(use_vesa = false) {
    wire_z = panel_thick + front_clearance + wire_d/2;
    
    // 1. Padel Court Steel Wire Mesh (in front at Z = wire_z)
    translate([0, 115.2, wire_z])
        padel_mesh_wire_grid(w = 320, h = 320);
        
    // 2. Incoming Padel Ball (bouncing off front of mesh, cannot touch display!)
    padel_ball_sim([40.0, 60.0, wire_z + 45.0]);
    
    // 3. Simulated 7-Segment Display Panel (Dark Slate Body)
    color("#1e293b", 0.85) {
        translate([0, 0, panel_thick/2])
            cube([138.4, 230.4, panel_thick], center = true);
    }
    
    // Glowing LED segments preview (White/Cyan)
    color("#38bdf8") {
        translate([0, 0, panel_thick + 0.1])
            linear_extrude(0.6) {
                // Segment 8 shape preview
                for (y = [-92, 0, 92]) translate([0, y]) square([70, 14], center = true);
                for (x = [-46, 46]) {
                    translate([x, 46]) square([14, 70], center = true);
                    translate([x, -46]) square([14, 70], center = true);
                }
            }
    }
    
    // 4. Mounting Hooks
    if (!use_vesa) {
        // Top Seam Hook mounted over top edge
        color("#0284c7")
            translate([0, 109.2, 0])
                seam_hook_bracket();
    } else {
        // VESA 50x50 Hook mounted in center of backplate
        color("#0284c7")
            translate([0, 0, -bracket_t])
                vesa_mesh_hook();
    }
}

// ==============================================================================
// TOP-LEVEL SELECTOR
// ==============================================================================
if (part == 1 || part == "seam_pair") {
    seam_hook_pair_on_bed();
} else if (part == 2 || part == "corner_pair") {
    corner_hook_pair_on_bed();
} else if (part == 3 || part == "vesa_hook") {
    vesa_mesh_hook();
} else if (part == 4 || part == "seam_single") {
    seam_hook_bracket();
} else if (part == 5 || part == "corner_single") {
    corner_hook_bracket();
} else if (part == 6 || part == "preview_seam") {
    assembled_preview(use_vesa = false);
} else if (part == 7 || part == "preview_vesa") {
    assembled_preview(use_vesa = true);
}
