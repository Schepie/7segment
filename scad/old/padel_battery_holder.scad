// =============================================================================
// Padel Court Wire Mesh Battery Pack Holder (Sitecom 20,000mAh 30W Powerbank)
// Designed for Action Art. No. 3222798 (118 x 71 x 29.6 mm)
// Mounts to standard 50x50 mm Padel Court Steel Wire Mesh & 7-Segment VESA Mount
// =============================================================================

// --- Configuration & Preview Toggles ---
show_holder = true;           // Render the 3D-printable battery holder
// --- Preview & Simulation Options ---
show_battery_preview = false;  // Show translucent Sitecom powerbank
show_mesh_preview = false;     // Show 50x50 mm padel court wire mesh
mesh_side = "front";          // "front" = horizontal wires facing holder; "opposite" = vertical wire facing holder

// --- Powerbank Dimensions (Action Sitecom 3222798 20,000mAh) ---
batt_w = 71.0;                // Battery physical width (71.0 mm)
batt_d = 29.6;                // Battery physical thickness/depth (29.6 mm)
batt_h = 118.0;               // Battery physical height (118.0 mm)
batt_radius = 5.0;            // Battery corner rounding

// --- Fit Tolerances & Cradle Sizing ---
fit_tol_w = 1.4;              // Width clearance (+0.7mm per side)
fit_tol_d = 1.2;              // Depth clearance (+0.6mm per side)
inner_w = batt_w + fit_tol_w; // 72.4 mm
inner_d = batt_d + fit_tol_d; // 30.8 mm
cradle_h = 85.0;              // 85.0 mm cradle height (top 33mm exposed for easy removal)
wall_t = 2.8;                 // Robust 2.8mm structural wall thickness
floor_t = 3.2;                // Solid 3.2mm base floor
outer_radius = 6.0;           // Outer aesthetic corner rounding

outer_w = inner_w + wall_t * 2; // 78.0 mm
outer_d = inner_d + wall_t * 2; // 36.4 mm

// --- Padel Fence Mesh Parameters (FIP Regulation Standard) ---
mesh_pitch = 50.0;            // 50.0 mm center-to-center square wire grid
wire_dia = 4.0;               // Standard wire diameter (supports 3.0 to 4.8 mm)
hook_throat_dia = 5.6;        // Generous 5.6 mm throat for smooth sliding over wire
hook_lip_depth = 18.0;        // Long 18.0 mm downward retention lip (matches technical blueprint)
hook_entry_width = 8.8;       // Wide 8.8 mm flared entry mouth for easy alignment
hook_w = 14.0;                // Broad 14.0 mm wide hooks for superior strength & stability
hook_offset_z = cradle_h - 10.0; // Top hook wire center level (75.0 mm above base)

// --- VESA Mount Parameters (Optional direct scoreboard bolting) ---
vesa_pitch = 0.0;            // 50x50 mm VESA mounting hole pattern
m3_hole_dia = 0;            // M3 screw clearance diameter

// =============================================================================
// Helper Shapes
// =============================================================================

// 2D Rounded Rectangle centered at origin
module rounded_rect(w, d, r) {
    hull() {
        translate([-w/2 + r, -d/2 + r]) circle(r = r, $fn = 36);
        translate([ w/2 - r, -d/2 + r]) circle(r = r, $fn = 36);
        translate([ w/2 - r,  d/2 - r]) circle(r = r, $fn = 36);
        translate([-w/2 + r,  d/2 - r]) circle(r = r, $fn = 36);
    }
}

// 3D Rounded Prism Extrusion
module rounded_prism(w, d, h, r) {
    linear_extrude(height = h)
        rounded_rect(w, d, r);
}

// Universal Slide-From-Top Padel Mesh Gravity Hook Profile (extruded along X)
// Accommodates BOTH:
//   - Option 1 (Front Mesh): Horizontal wire is directly against back wall (Y = -2.2 mm)
//   - Option 2 (Opposite Mesh): Horizontal wire is pushed 4mm out by vertical wire (Y = -6.2 mm)
module padel_wire_gravity_hook(width = hook_w, is_top = true) {
    wire1_y = -2.2;         // Inner wire seat (Option 1: Front Mesh)
    wire2_y = -6.2;         // Outer wire seat (Option 2: Opposite Mesh)
    wire_r = 2.4;           // Generous radius for Ø4.0mm wire (with 0.4mm clearance)
    lip_t = 3.2;            // Thickness of outer downward lip
    lip_len = hook_lip_depth; // 18.0 mm long downward lip
    
    rotate([0, -90, 0])
    linear_extrude(height = width, center = true) {
        difference() {
            // Outer solid J-hook shape
            hull() {
                // Top rounded roof spanning over both wire positions
                translate([wire_r + 2.6, wire1_y])
                    circle(r = wire_r + 2.8, $fn = 36);
                translate([wire_r + 2.6, wire2_y])
                    circle(r = wire_r + 2.8, $fn = 36);
                // Top connection stalk to back wall
                translate([wire_r + 2.6, -0.5])
                    square([1.0, 1.0], center = true);
                // Lower 45° support gusset against back wall
                translate([-10.0, -1.0])
                    square([1.0, 2.0], center = true);
                // Bottom tip of the long outer downward lip
                translate([-lip_len, wire2_y - wire_r - lip_t/2])
                    circle(r = lip_t/2, $fn = 24);
                // Mid-lip outer contour for smooth organic taper
                translate([-lip_len/2, wire2_y - wire_r - lip_t/2])
                    circle(r = lip_t/2 + 0.2, $fn = 24);
            }
            
            // Wire slot subtraction (Dual-Seat Universal Cavity):
            // 1. Top semicircular wire resting saddles (gravity seats for Option 1 & Option 2)
            hull() {
                translate([0, wire1_y])
                    circle(r = wire_r, $fn = 36);
                translate([0, wire2_y])
                    circle(r = wire_r, $fn = 36);
            }
                
            // 2. Wide downward open slot (continuous through the bottom)
            hull() {
                translate([-lip_len/2 - 5, wire1_y])
                    square([lip_len + 12, wire_r * 2], center = true);
                translate([-lip_len/2 - 5, wire2_y])
                    square([lip_len + 12, wire_r * 2], center = true);
            }
                
            // 3. Flared bottom entry chamfer for effortless drop-on wire alignment
            polygon([
                [-lip_len + 5.0, wire1_y + wire_r],
                [-lip_len + 5.0, wire2_y - wire_r],
                [-lip_len - 5.0, wire2_y - wire_r - 2.5],
                [-lip_len - 5.0, wire1_y + wire_r + 2.5]
            ]);
            
            // 4. Ensure completely open space below the hook
            translate([-lip_len - 15, -35])
                square([25, 45]);
        }
    }
}

// Lower stabilizer saddle (also drops over the lower 50mm wire for dual-tier lock)
module padel_lower_stabilizer(width = hook_w) {
    padel_wire_gravity_hook(width = width, is_top = false);
}

// =============================================================================
// Main Battery Holder Module
// =============================================================================

module padel_battery_holder() {
    difference() {
        union() {
            // 1. Main outer cradle body
            translate([0, 0, 0])
                rounded_prism(outer_w, outer_d, cradle_h, outer_radius);
            
            // 2. Dual Top Padel Mesh Gravity Hooks (Spaced 50 mm apart on X = +/- 25 mm)
            // Allows effortless sliding down over horizontal fence wire from the top
            for (x = [-mesh_pitch/2, mesh_pitch/2]) {
                translate([x, -outer_d/2, hook_offset_z])
                    padel_wire_gravity_hook(hook_w, is_top = true);
            }
            
            // 3. Lower Fence Mesh Stabilizers (Exactly 50 mm below top hooks)
            for (x = [-mesh_pitch/2, mesh_pitch/2]) {
                translate([x, -outer_d/2, hook_offset_z - mesh_pitch])
                    padel_lower_stabilizer(hook_w);
            }
            
            // 4. Integrated USB-C Cable Clip (Right side wall)
            translate([outer_w/2, 0, cradle_h/2]) {
                difference() {
                    hull() {
                        translate([0, -4.0, -12.0]) cube([4.5, 8.0, 24.0]);
                        translate([2.5, -4.0, -10.0]) cube([2.0, 8.0, 20.0]);
                    }
                    // Vertical cable retention groove (dia 4.0 mm for standard USB-C braided cable)
                    translate([2.4, 0, -13.0])
                        cylinder(h = 26.0, r = 2.1, $fn = 24);
                    // Snap slot opening (2.6 mm retention gap)
                    translate([2.0, -1.3, -13.0])
                        cube([4.0, 2.6, 26.0]);
                }
            }
        }
        
        // --- SUBTRACTIONS ---
        
        // A. Main Internal Battery Cavity
        translate([0, 0, floor_t])
            rounded_prism(inner_w, inner_d, cradle_h + 10, batt_radius);
            
        // B. Front Cutout Window (Charge Gauge & Power Button View + Grip)
        translate([0, outer_d/2, floor_t + cradle_h/2 - 5]) {
            // Main rounded viewing window
            hull() {
                translate([-22.0, -5, -20.0]) rotate([-90, 0, 0]) cylinder(h = 10, r = 6.0, $fn = 30);
                translate([ 22.0, -5, -20.0]) rotate([-90, 0, 0]) cylinder(h = 10, r = 6.0, $fn = 30);
                translate([ 22.0, -5,  22.0]) rotate([-90, 0, 0]) cylinder(h = 10, r = 6.0, $fn = 30);
                translate([-22.0, -5,  22.0]) rotate([-90, 0, 0]) cylinder(h = 10, r = 6.0, $fn = 30);
            }
        }
        
        // C. Bottom USB-C Port Cutout & Push-Up Thumb Slot
        translate([0, 0, -0.1]) {
            hull() {
                translate([-18.0, 0, 0]) cylinder(h = floor_t + 0.2, r = 8.0, $fn = 36);
                translate([ 18.0, 0, 0]) cylinder(h = floor_t + 0.2, r = 8.0, $fn = 36);
            }
        }
        
        // D. Top Front Beveled Access Ramp (for smooth, snag-free battery insertion)
        translate([0, outer_d/2 - 2.0, cradle_h])
            rotate([35, 0, 0])
                cube([outer_w + 2, 8, 8], center = true);
/*
        // E. 4x VESA 50x50 mm M3 Screw Mounting Holes (through back wall)
        // Allows direct bolting to scoreboard backplate if fence mounting is not used
        for (x = [-vesa_pitch/2, vesa_pitch/2]) {
            for (z = [hook_offset_z - mesh_pitch, hook_offset_z]) {
                translate([x, -outer_d/2 - 5, z]) {
                    rotate([-90, 0, 0]) {
                        cylinder(h = wall_t + 10, r = m3_hole_dia/2, $fn = 24);
                        // Countersink / socket head pocket on inside
                        translate([0, 0, wall_t + 3.0])
                            cylinder(h = 10, r = 3.2, $fn = 24);
                    }
                }
            }
        }
        */
        // F. Drainage & Ventilation Slots in bottom floor
        for (x = [-24.0, 24.0]) {
            translate([x, 0, -0.1])
                cylinder(h = floor_t + 0.2, r = 2.5, $fn = 20);
        }
        
        // G. Copyright Logo 'GSC©' Engraving (Left Side Wall, Vertical 90°)
        translate([-outer_w/2 + 0.6, 0, cradle_h/2]) {
            rotate([90, 0, -90]) {
                rotate([0, 0, 90]) {
                    linear_extrude(height = 1.0) {
                        // Main bold vertical GSC lettering (reads bottom-to-top)
                        translate([-2.5, 0])
                            text("GSC", size = 11.5, font = "Liberation Sans:style=Bold", halign = "center", valign = "center", spacing = 1.08);
                        // Small Copyright symbol © (offset clearly with 2mm breathing room)
                        translate([16.5, 4.8])
                            text("©", size = 3.8, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
                    }
                }
            }
        }
    }
}

// =============================================================================
// Simulation / Preview Models
// =============================================================================

// Ghost 3D model of the Sitecom 20,000mAh 30W Powerbank
module sitecom_battery_model() {
    color([0.2, 0.25, 0.3, 0.75]) {
        translate([0, 0, floor_t + 1.0]) {
            // Main body
            rounded_prism(batt_w, batt_d, batt_h, batt_radius);
            
            // Integrated USB-C cable top loop
            translate([-batt_w/2 + 10, 0, batt_h])
                color([0.1, 0.1, 0.1, 0.9])
                    cube([12, 6, 8], center = true);
                    
            // Battery Status LED Indicator (4 white dots)
            for (i = [-3:2:3]) {
                translate([i * 3.5, batt_d/2 + 0.2, 50.0])
                    color([0.0, 0.9, 1.0, 1.0])
                        sphere(r = 0.8, $fn = 16);
            }
            
            // Power button simulation
            translate([batt_w/2 + 0.2, 0, 48.0])
                color([0.4, 0.4, 0.4, 0.9])
                    cube([0.8, 8.0, 4.0], center = true);
        }
    }
}

// 50x50 mm Padel Court Steel Wire Mesh Simulation
module padel_mesh_grid() {
    color([0.5, 0.55, 0.6, 0.85]) {
        if (mesh_side == "opposite") {
            // OPTION 2: OPPOSITE SIDE OF MESH
            // Vertical wire at center (X=0) presses directly against back wall (Y = -outer_d/2 - 2.0 mm)
            for (x = [-2:2]) {
                translate([x * mesh_pitch, -outer_d/2 - wire_dia/2, hook_offset_z - 50])
                    cylinder(h = 220, r = wire_dia/2, center = true, $fn = 24);
            }
            // Horizontal Wires welded on far side (Y = -outer_d/2 - 6.0 mm, seated in outer hook cavity)
            for (z = [-1:3]) {
                translate([0, -outer_d/2 - wire_dia - wire_dia/2, hook_offset_z - z * mesh_pitch])
                    rotate([0, 90, 0])
                        cylinder(h = 200, r = wire_dia/2, center = true, $fn = 24);
            }
        } else {
            // OPTION 1: FRONT SIDE OF MESH
            // Horizontal wires face holder directly against back wall (Y = -outer_d/2 - 2.0 mm, seated in inner hook cavity)
            for (z = [-1:3]) {
                translate([0, -outer_d/2 - wire_dia/2, hook_offset_z - z * mesh_pitch])
                    rotate([0, 90, 0])
                        cylinder(h = 200, r = wire_dia/2, center = true, $fn = 24);
            }
            // Vertical wires welded on far side (Y = -outer_d/2 - 6.0 mm)
            for (x = [-2:2]) {
                translate([x * mesh_pitch, -outer_d/2 - wire_dia - wire_dia/2, hook_offset_z - 50])
                    cylinder(h = 220, r = wire_dia/2, center = true, $fn = 24);
            }
        }
    }
}

// =============================================================================
// Scene Render
// =============================================================================

if (show_holder) {
    color("#2563eb") // Vibrant Royal Blue finish
        padel_battery_holder();
}

if (show_battery_preview) {
    sitecom_battery_model();
}

if (show_mesh_preview) {
    padel_mesh_grid();
}
