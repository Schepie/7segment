// =============================================================================
// Padel Racket Handle Wearable BLE Score Button (CR2032 Powered)
// Designed for Padel Racket Handle Neck Mounting (Contoured Saddle Mount)
// Features: Ergonomic scalloped bezel, tactile push-button, velcro/silicone wings
// Electronics: CR2032 Coin Cell + Seeed Studio XIAO BLE (nRF52840) + 6x6 Tactile Switch
// =============================================================================

/* [Render / Display Options] */
// Select what to display in preview or export
view_mode = "assembled"; // ["assembled", "exploded", "print_layout", "base", "cover", "button", "handle_fit_test"]

// Preview guides and simulation
show_racket_preview = true; // Show translucent padel racket handle in assembled mode
show_electronics_preview = true; // Show CR2032, XIAO BLE board, and tactile switch
show_strap_preview = true; // Show simulated velcro / silicone strap

/* [Padel Racket Handle Dimensions] */
handle_width    = 32.0; // Width across flats at top of handle (standard ~30-34 mm)
handle_depth    = 26.0; // Thickness/depth of handle (standard ~24-28 mm)
handle_chamfer  = 6.0;  // 45° corner chamfer size for octagonal handle profile
handle_height   = 70.0; // Visual length of handle segment for preview

/* [Button Enclosure Outer Dimensions] */
bezel_dia       = 33.0; // Outer diameter of circular button bezel (mm)
bezel_height    = 8.0;  // Height of top cover/bezel (mm)
base_height     = 6.5;  // Height of base saddle module (mm)
wall_t          = 1.6;  // Wall thickness for rigid 3D printing (mm)
scallop_count   = 12;   // Number of ergonomic thumb grip flutes around perimeter
scallop_r       = 2.8;  // Radius of grip flutes (mm)
scallop_depth   = 1.2;  // Indentation depth of grip flutes (mm)

/* [Strap & Wing Parameters] */
wing_width      = 49.0; // Total width across strap wings (mm)
strap_slot_w    = 18.0; // Width of slot for velcro / silicone band (mm)
strap_slot_t    = 2.4;  // Thickness of strap slot (mm)
wing_thickness  = 3.8;  // Thickness of side mounting wings (mm)

/* [Push Button Cap Parameters] */
button_dia      = 18.2; // Diameter of central push button cap (mm)
button_travel   = 1.0;  // Push actuation travel distance (mm)
button_rim_flange = 1.2;// Retention flange width to keep button captive (mm)
button_rib_count = 12;  // Number of radial grip ridges on button top face

/* [Internal Electronics Compartment] */
cr2032_dia      = 20.2; // CR2032 diameter with 0.2mm tolerance (mm)
cr2032_thick    = 3.4;  // CR2032 thickness with tolerance (mm)
xiao_length     = 21.6; // Seeed XIAO BLE PCB length (mm)
xiao_width      = 18.0; // Seeed XIAO BLE PCB width (mm)
xiao_thick      = 2.2;  // Seeed XIAO BLE PCB thickness (mm)
switch_size     = 6.2;  // Standard 6x6 mm tactile button footprint (mm)
switch_height   = 5.0;  // Switch total height including stem (mm)

/* [Tolerances & Quality] */
fit_clearance   = 0.35; // 3D print clearance tolerance (mm)
$fn = 64;               // High smooth circle resolution

// =============================================================================
// Helper 2D / 3D Profiles
// =============================================================================

// 2D Octagonal Padel Handle Cross Section
module padel_handle_profile(w = handle_width, d = handle_depth, c = handle_chamfer) {
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

// 3D Padel Handle Extrusion for Preview & Subtraction
module padel_handle(extra_clearance = 0, length = handle_height) {
    w = handle_width + extra_clearance;
    d = handle_depth + extra_clearance;
    c = handle_chamfer + extra_clearance/2;
    linear_extrude(height = length, center = true)
        padel_handle_profile(w, d, c);
}

// =============================================================================
// PART 1: Saddle Base (Onderdeel 1: Zadel & Batterijhouder)
// =============================================================================
module base_part() {
    difference() {
        union() {
            // Main central circular hub
            cylinder(h = base_height, d = bezel_dia - 0.2);
            
            // Lateral strap mounting wings (curved to hug handle)
            hull() {
                translate([0, 0, base_height / 2])
                    cube([bezel_dia, bezel_dia * 0.7, base_height], center = true);
                
                // Left strap wing
                translate([-wing_width / 2 + 3.0, 0, wing_thickness / 2])
                    rounded_wing_tip(wing_thickness, strap_slot_w + 6);
                
                // Right strap wing
                translate([ wing_width / 2 - 3.0, 0, wing_thickness / 2])
                    rounded_wing_tip(wing_thickness, strap_slot_w + 6);
            }
            
            // Snap-fit rim / mating lip for the top cover
            translate([0, 0, base_height])
                difference() {
                    cylinder(h = 2.4, d = bezel_dia - 2 * wall_t - 0.1);
                    cylinder(h = 2.6, d = bezel_dia - 2 * wall_t - 1.8);
                }
            
            // 4x Snap-fit locking bead bumps around the mating rim
            for (a = [45, 135, 225, 315]) {
                rotate([0, 0, a])
                    translate([(bezel_dia - 2 * wall_t - 0.1)/2, 0, base_height + 1.4])
                        sphere(r = 0.6, $fn = 20);
            }
        }
        
        // --- 1. Saddle Cutout (Conforms snugly to the Padel Handle) ---
        translate([0, 0, -handle_depth / 2])
            rotate([0, 90, 90])
                padel_handle(extra_clearance = 0.5, length = 80);
        
        // --- 2. Strap Slots for Velcro or Silicone O-Ring ---
        // Left Strap Slot
        translate([-wing_width/2 + 5.5, 0, wing_thickness/2 + 0.5])
            rotate([0, -10, 0])
                cube([strap_slot_t, strap_slot_w, wing_thickness + 4], center = true);
                
        // Right Strap Slot
        translate([ wing_width/2 - 5.5, 0, wing_thickness/2 + 0.5])
            rotate([0, 10, 0])
                cube([strap_slot_t, strap_slot_w, wing_thickness + 4], center = true);
        
        // Chamfers on strap slot entries for smooth strap threading
        for (sx = [-wing_width/2 + 5.5, wing_width/2 - 5.5]) {
            translate([sx, 0, 0])
                cube([strap_slot_t + 1.8, strap_slot_w - 2, 2.5], center = true);
        }
        
        // --- 3. Internal CR2032 Battery Pocket ---
        translate([0, 0, base_height - cr2032_thick])
            cylinder(h = cr2032_thick + 2.5, d = cr2032_dia + 0.3);
            
        // Battery Finger Eject Notch (allows easily popping battery out with a fingernail/pin)
        translate([0, -(cr2032_dia/2 + 1.5), base_height - cr2032_thick/2])
            cube([6.0, 5.0, cr2032_thick + 2.0], center = true);
            
        // Negative / Positive Contact Wire Channels
        translate([0, cr2032_dia/2 - 2.0, base_height - cr2032_thick - 1.0])
            cube([4.0, 6.0, 2.5], center = true);
            
        // Center negative contact floor pocket
        translate([0, 0, base_height - cr2032_thick - 0.8])
            cylinder(h = 1.0, d = 10.0);
            
        // --- 4. Microcontroller (Seeed Xiao BLE) Pocket ---
        translate([0, 0, base_height - cr2032_thick - 0.5])
            cube([xiao_width + 0.4, xiao_length + 0.4, 1.2], center = true);
    }
}

// Helper module for wing tip rounding
module rounded_wing_tip(th, w) {
    hull() {
        translate([0, -w/2 + 3, 0]) cylinder(h = th, r = 3, center = true);
        translate([0,  w/2 - 3, 0]) cylinder(h = th, r = 3, center = true);
    }
}

// =============================================================================
// PART 2: Scalloped Bezel Cover (Onderdeel 2: Bezel met Grip-groeven)
// =============================================================================
module cover_part() {
    difference() {
        union() {
            // Main cylindrical dome with top chamfer
            cylinder(h = bezel_height - 1.5, d = bezel_dia);
            translate([0, 0, bezel_height - 1.5])
                cylinder(h = 1.5, d1 = bezel_dia, d2 = bezel_dia - 3.0);
        }
        
        // --- 1. Ergonomic Grip Scallops / Flutes around perimeter ---
        for (i = [0 : scallop_count - 1]) {
            rotate([0, 0, i * (360 / scallop_count)])
                translate([bezel_dia / 2 - scallop_depth + scallop_r, 0, bezel_height / 2 + 1.0])
                    scale([1.0, 0.75, 1.8])
                        sphere(r = scallop_r, $fn = 24);
        }
        
        // --- 2. Central Button Aperture & Retaining Flange ---
        // Main button opening (top hole)
        translate([0, 0, -1])
            cylinder(h = bezel_height + 4, d = button_dia + fit_clearance * 2);
            
        // Internal captive retention counterbore (for button flange)
        translate([0, 0, -0.1])
            cylinder(h = 3.2, d = button_dia + button_rim_flange * 2 + fit_clearance * 2);
            
        // --- 3. Internal Cavity for Base Snap-Fit Collar & Electronics ---
        translate([0, 0, -0.1])
            difference() {
                cylinder(h = 3.8, d = bezel_dia - 2 * wall_t + fit_clearance);
                
                // Snap-fit internal retaining groove
                translate([0, 0, 1.4])
                    for (a = [45, 135, 225, 315]) {
                        rotate([0, 0, a])
                            translate([(bezel_dia - 2 * wall_t - 0.1)/2, 0, 0])
                                sphere(r = 0.75, $fn = 20);
                    }
            }
            
        // Chamfer on bottom inner rim for easy push-on snap assembly
        translate([0, 0, -0.1])
            cylinder(h = 1.0, d1 = bezel_dia - 2 * wall_t + 1.2, d2 = bezel_dia - 2 * wall_t);
    }
}

// =============================================================================
// PART 3: Tactile Push-Button Cap (Onderdeel 3: Knopdop met Textuur)
// =============================================================================
module button_part() {
    btn_h = 4.2; // Height of button cap
    
    union() {
        difference() {
            union() {
                // Main cylindrical button body
                cylinder(h = btn_h, d = button_dia);
                
                // Bottom captive retention flange (stops button from falling out)
                cylinder(h = 1.2, d = button_dia + button_rim_flange * 2 - 0.3);
                
                // Top rounded dome crown
                translate([0, 0, btn_h - 0.8])
                    cylinder(h = 0.8, d1 = button_dia, d2 = button_dia - 1.6);
            }
            
            // Finger center concavity for ergonomic thumb indexing
            translate([0, 0, btn_h + 9.2])
                sphere(r = 10.0, $fn = 48);
        }
        
        // --- Radial Grip Ridges on Button Face (Tactile spokes) ---
        for (a = [0 : button_rib_count - 1]) {
            rotate([0, 0, a * (360 / button_rib_count)])
                translate([button_dia / 4, 0, btn_h - 0.25])
                    cube([button_dia / 2.8, 0.7, 0.45], center = true);
        }
        
        // --- Central Plunger Stem (Actuates the 6x6 Tactile Switch) ---
        translate([0, 0, -1.8])
            cylinder(h = 2.0, d = 4.2);
    }
}

// =============================================================================
// Simulated Hardware & Electronics for Previews
// =============================================================================
module electronics_preview() {
    // 1. CR2032 Battery (Metallic Silver)
    color([0.85, 0.87, 0.90, 0.9])
    translate([0, 0, base_height - cr2032_thick/2])
        cylinder(h = 3.2, d = 20.0, center = true);
        
    // 2. Seeed Studio XIAO BLE (nRF52840) Board (Matte Black PCB + Gold pads)
    color([0.15, 0.15, 0.15, 0.95])
    translate([0, 0, base_height + 0.8])
        cube([17.5, 21.0, 1.6], center = true);
        
    // 3. 6x6mm Tactile Micro Switch
    color([0.25, 0.25, 0.25])
    translate([0, 0, base_height + 2.8])
        cube([6.0, 6.0, 3.5], center = true);
        
    // Tactile button brass actuator stem
    color([0.9, 0.7, 0.2])
    translate([0, 0, base_height + 4.8])
        cylinder(h = 1.5, d = 3.2, center = true);
}

// Simulated Padel Racket Handle (Translucent Carbon/Graphite)
module racket_handle_preview() {
    color([0.2, 0.25, 0.3, 0.35])
    translate([0, 0, -handle_depth / 2])
        rotate([0, 90, 90])
            padel_handle(extra_clearance = 0, length = handle_height);
}

// Simulated Velcro Strap (Braided Black Fabric)
module strap_preview() {
    color([0.1, 0.1, 0.1, 0.75])
    translate([0, 0, -handle_depth/2 + 2.0])
        rotate([0, 90, 90])
            difference() {
                padel_handle(extra_clearance = 3.0, length = strap_slot_w);
                padel_handle(extra_clearance = 0.5, length = strap_slot_w + 2);
            }
}

// =============================================================================
// Scene Rendering & Layout Modes
// =============================================================================

if (view_mode == "assembled") {
    // --- Complete Assembled Wearable Clicker on Padel Racket Handle ---
    color([0.2, 0.2, 0.22]) base_part();
    color([0.15, 0.15, 0.16]) translate([0, 0, base_height - 0.2]) cover_part();
    color([0.85, 0.15, 0.15]) translate([0, 0, base_height + 3.2]) button_part();
    
    if (show_electronics_preview) electronics_preview();
    if (show_racket_preview) racket_handle_preview();
    if (show_strap_preview) strap_preview();
}
else if (view_mode == "exploded") {
    // --- Exploded Assembly Diagram ---
    if (show_racket_preview) racket_handle_preview();
    
    color([0.2, 0.2, 0.22]) translate([0, 0, 0]) base_part();
    if (show_electronics_preview) translate([0, 0, 10]) electronics_preview();
    color([0.15, 0.15, 0.16]) translate([0, 0, 26]) cover_part();
    color([0.85, 0.15, 0.15]) translate([0, 0, 42]) button_part();
}
else if (view_mode == "print_layout") {
    // --- Ready-to-Print Plate (All 3 parts oriented flat for FDM / Resin 3D printing) ---
    // 1. Base (sits upright flat)
    translate([-bezel_dia * 0.75, 0, 0])
        base_part();
        
    // 2. Top Cover (rotated 180° so top face with scallops sits flat or upright)
    translate([bezel_dia * 0.75, 0, 0])
        cover_part();
        
    // 3. Button Cap (sits flat on flange)
    translate([0, bezel_dia * 0.75, 0])
        button_part();
}
else if (view_mode == "base") {
    base_part();
}
else if (view_mode == "cover") {
    cover_part();
}
else if (view_mode == "button") {
    button_part();
}
else if (view_mode == "handle_fit_test") {
    // Small quick test coupon to verify fit on your specific padel racket handle in 15 mins!
    intersection() {
        base_part();
        translate([0, 0, 2.5]) cube([wing_width + 4, 16, 12], center = true);
    }
}
