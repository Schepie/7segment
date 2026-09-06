// =============================================================================
// Padel Racket Ultra-Slim Split Score Button (Dual-Sided Handle Architecture)
// - Front Pod: Ultra-thin button & BLE microcontroller (~4.8 mm thick)
// - Back Pod: Ultra-thin CR2032 coin cell battery holder (~4.5 mm thick)
// - Connected across opposite faces of the octagonal padel handle
// =============================================================================

/* [Render / Display Options] */
view_mode = "assembled"; // ["assembled", "exploded", "print_layout", "front_pod", "back_pod", "button_cap", "tpu_one_piece"]

show_racket_handle = true; // Show translucent padel handle preview
show_electronics = true;   // Show internal battery & Xiao PCB
show_strap = true;         // Show connecting velcro/silicone band

/* [Padel Handle Dimensions] */
handle_w = 32.0;       // Width across flats at top of handle (standard ~30-34 mm)
handle_d = 26.0;       // Thickness across opposite flats (standard ~24-28 mm)
handle_chamfer = 5.5;  // 45° corner chamfers for octagonal profile
handle_len = 65.0;     // Preview length

/* [Front Button Pod Dimensions] */
front_w = 22.0;        // Width of front pod (mm)
front_h = 28.0;        // Height of front pod (mm)
front_thick = 4.8;     // Ultra-thin thickness! (mm)
button_dia = 14.5;     // Diameter of tactile button (mm)
button_travel = 0.8;   // Switch travel (mm)

/* [Back Battery Pod Dimensions] */
back_w = 24.5;         // Width of back pod (mm)
back_h = 28.0;         // Height of back pod (mm)
back_thick = 4.5;      // Ultra-thin thickness! (mm)
cr2032_dia = 20.2;     // Battery diameter (mm)
cr2032_thick = 3.3;    // Battery thickness (mm)

/* [Strap & Fastening] */
strap_w = 15.0;        // Strap width (mm)
strap_t = 2.0;         // Strap slot thickness (mm)
wall_min = 1.0;        // Minimal wall thickness (mm)

$fn = 48;

// =============================================================================
// Helper 2D/3D Shapes
// =============================================================================

module rounded_rect(w, h, r) {
    hull() {
        translate([-w/2 + r, -h/2 + r]) circle(r = r);
        translate([ w/2 - r, -h/2 + r]) circle(r = r);
        translate([ w/2 - r,  h/2 - r]) circle(r = r);
        translate([-w/2 + r,  h/2 - r]) circle(r = r);
    }
}

// Octagonal Padel Handle
module padel_handle_cut(extra = 0) {
    w = handle_w + extra;
    d = handle_d + extra;
    c = handle_chamfer + extra/2;
    linear_extrude(height = 100, center = true)
        polygon(points = [
            [-w/2 + c, -d/2],
            [ w/2 - c, -d/2],
            [ w/2,     -d/2 + c],
            [ w/2,      d/2 - c],
            [ w/2 - c,  d/2],
            [-w/2 + c,  d/2],
            [-w/2,      d/2 - c],
            [-w/2,     -d/2 + c]
        ]);
}

// =============================================================================
// PART 1: Front Ultra-Slim Button Pod (Voorzijde - Duimkant)
// =============================================================================
module front_pod() {
    difference() {
        union() {
            // Main low-profile rounded body
            linear_extrude(height = front_thick)
                rounded_rect(front_w, front_h, 4.0);
                
            // Subtle raised bezel ring around button
            translate([0, 0, front_thick])
                cylinder(h = 0.6, d1 = button_dia + 2.4, d2 = button_dia + 1.2);
                
            // Strap pass-through side loops
            for (sx = [-front_w/2 - 2.5, front_w/2 + 2.5]) {
                translate([sx, 0, front_thick/2])
                    cube([4.0, strap_w + 4.0, front_thick], center = true);
            }
        }
        
        // --- 1. Curved saddle back (rests flat against front handle facet) ---
        translate([0, -handle_len/2, 0])
            rotate([-90, 0, 0])
                #translate([0, handle_d/2 + 0.2, 0])
                    padel_handle_cut(extra = 0.3);
        
        // --- 2. Button aperture & captive retention flange ---
        // Main button opening
        translate([0, 0, -1])
            cylinder(h = front_thick + 3, d = button_dia);
        // Internal counterbore for button flange
        translate([0, 0, -0.1])
            cylinder(h = 1.6, d = button_dia + 2.2);
            
        // --- 3. Electronics internal pocket (XIAO BLE / SMD Switch) ---
        translate([0, 0, -0.1])
            cube([18.2, 22.0, front_thick - 1.2], center = true);
            
        // --- 4. Strap Slots (Left & Right) ---
        for (sx = [-front_w/2 - 2.0, front_w/2 + 2.0]) {
            translate([sx, 0, front_thick/2])
                cube([strap_t, strap_w, front_thick + 2], center = true);
        }
        
        // --- 5. Wire pass-through notch for battery connection ---
        translate([0, -front_h/2 + 1.5, 0.8])
            cube([4.0, 4.0, 2.0], center = true);
    }
}

// =============================================================================
// PART 2: Button Cap (Ultra-Low Profile Tactile Cap)
// =============================================================================
module button_cap() {
    cap_h = 2.4;
    union() {
        difference() {
            union() {
                // Main disc
                cylinder(h = cap_h, d = button_dia - 0.5);
                // Bottom retention flange
                cylinder(h = 0.9, d = button_dia + 1.6);
            }
            // Ergonomic thumb dish concavity
            translate([0, 0, cap_h + 8.5])
                sphere(r = 9.0);
        }
        
        // Tactile "+" or sport icon ridge on top
        translate([0, 0, cap_h - 0.2])
            cube([button_dia * 0.55, 0.9, 0.5], center = true);
        translate([0, 0, cap_h - 0.2])
            cube([0.9, button_dia * 0.55, 0.5], center = true);
            
        // Central plunger stem for microswitch
        translate([0, 0, -1.0])
            cylinder(h = 1.1, d = 3.2);
    }
}

// =============================================================================
// PART 3: Rear Ultra-Slim Battery Pod (Achterzijde - CR2032)
// =============================================================================
module back_pod() {
    difference() {
        union() {
            // Main low-profile rounded body
            linear_extrude(height = back_thick)
                rounded_rect(back_w, back_h, 4.0);
                
            // Strap pass-through side loops
            for (sx = [-back_w/2 - 2.5, back_w/2 + 2.5]) {
                translate([sx, 0, back_thick/2])
                    cube([4.0, strap_w + 4.0, back_thick], center = true);
            }
        }
        
        // --- 1. Curved saddle back (rests against rear handle facet) ---
        translate([0, -handle_len/2, 0])
            rotate([-90, 0, 0])
                translate([0, -handle_d/2 - 0.2, 0])
                    padel_handle_cut(extra = 0.3);
        
        // --- 2. CR2032 Battery Pocket (Ø20.2 x 3.3mm) ---
        translate([0, 0, back_thick - cr2032_thick])
            cylinder(h = cr2032_thick + 2, d = cr2032_dia);
            
        // Battery Finger Eject Notch (allows popping coin cell out easily)
        translate([0, -(cr2032_dia/2 + 1.2), back_thick/2])
            cube([6.0, 4.5, back_thick + 2], center = true);
            
        // Wire terminal channels (+ and - leads to front pod)
        translate([0, cr2032_dia/2 - 1.5, 0.8])
            cube([5.0, 5.0, 2.0], center = true);
            
        // --- 3. Strap Slots (Left & Right) ---
        for (sx = [-back_w/2 - 2.0, back_w/2 + 2.0]) {
            translate([sx, 0, back_thick/2])
                cube([strap_t, strap_w, back_thick + 2], center = true);
        }
    }
}

// =============================================================================
// Scene Rendering & Layout Modes
// =============================================================================

if (view_mode == "assembled") {
    // Front Pod on Front face of handle
    translate([0, 0, handle_d/2 + 0.1])
        color([0.2, 0.2, 0.22]) front_pod();
        
    // Button Cap inside front pod
    translate([0, 0, handle_d/2 + 2.8])
        color([0.85, 0.15, 0.15]) button_cap();
        
    // Back Pod on Rear face of handle (rotated 180°)
    translate([0, 0, -handle_d/2 - back_thick - 0.1])
        color([0.2, 0.2, 0.22]) back_pod();
        
    // Preview Padel Handle
    if (show_racket_handle) {
        color([0.25, 0.3, 0.35, 0.4])
            rotate([-90, 0, 0])
                padel_handle_cut(extra = 0);
    }
    
    // Preview Strap wrapping around sides
    if (show_strap) {
        color([0.1, 0.1, 0.1, 0.8])
            rotate([-90, 0, 0])
                difference() {
                    padel_handle_cut(extra = 2.4);
                    padel_handle_cut(extra = 0.4);
                }
    }
    
    // Preview CR2032 in back pod
    if (show_electronics) {
        translate([0, 0, -handle_d/2 - 1.8])
            color([0.85, 0.87, 0.9])
                cylinder(h = 3.2, d = 20.0, center = true);
    }
}
else if (view_mode == "exploded") {
    // Exploded View showing all layers
    if (show_racket_handle) {
        color([0.25, 0.3, 0.35, 0.3])
            rotate([-90, 0, 0])
                padel_handle_cut(extra = 0);
    }
    
    // Front Pod exploded upward
    translate([0, 0, handle_d/2 + 15])
        color([0.2, 0.2, 0.22]) front_pod();
    translate([0, 0, handle_d/2 + 28])
        color([0.85, 0.15, 0.15]) button_cap();
        
    // Rear Pod exploded downward
    translate([0, 0, -handle_d/2 - 15])
        color([0.85, 0.87, 0.9]) cylinder(h = 3.2, d = 20.0, center = true);
    translate([0, 0, -handle_d/2 - 25])
        color([0.2, 0.2, 0.22]) back_pod();
}
else if (view_mode == "print_layout") {
    // Plate layout ready for 3D printing
    translate([-20, 0, 0]) front_pod();
    translate([ 20, 0, 0]) back_pod();
    translate([  0, 20, 0]) button_cap();
}
else if (view_mode == "front_pod") {
    front_pod();
}
else if (view_mode == "back_pod") {
    back_pod();
}
else if (view_mode == "button_cap") {
    button_cap();
}
