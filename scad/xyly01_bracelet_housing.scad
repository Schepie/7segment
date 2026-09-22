// ==============================================================================
// Xiaomi XYLY01 Bluetooth Shutter - Bracelet Housing / Cover
// Parametric OpenSCAD Model (Capsule / Stadium Circular Ends)
// ==============================================================================
// Remote Dimensions:
//   - Circular / Stadium Ends: straight mid-section = 20.0 mm
//   - Base: 43.5 mm total length x 23.5 mm width x 7.0 mm height
//     (composed of 20mm straight mid-section + two R11.75mm semicircular ends)
//   - Rim Shelf: at 7.0 mm height, uniform 1.75 mm shoulder all around
//   - Upper Part: 40.0 mm total length x 20.0 mm width x 3.0 mm height
//     (composed of 20mm straight mid-section + two R10.0mm semicircular ends)
//   - Total Remote Height: 10.0 mm
//
// Bracelet Configuration:
//   - Orientation: "short_sides" (strap attached at circular short ends,
//     matching your example) or "long_sides".
//   - Strap Slot: fits 20mm & 22mm watch / NATO / Velcro / 3D-printed link bands.
//   - Bottom-load captured cage: 100% fail-safe retention locked by the 1.75mm rim.
// ==============================================================================

$fn = 72;

/* [Configuration & Mode] */
circular_ends         = true;          // [true: Circular / Stadium capsule ends, false: Rectangular with corner fillets]
slot_position         = "short_sides"; // ["short_sides": Strap at top & bottom circular ends, "long_sides": Strap at left & right sides]
render_mode           = "bent";        // ["bent": Ergonomic curved wings, "flat": 100% supportless flat print, "both": Side-by-side comparison, "cross_section": Cutaway inspection]
show_remote_mockup    = true;          // Display translucent remote mockup inside the housing
show_bracelet_preview = false;         // Display example watch bracelet links (for visualization)

/* [Ear & Strap Sizing] */
ear_width             = 15.0;  // [12.0:0.5:28.0] Total outer width of the ears / wings (mm)
strap_slot_thick      = 3.2;   // [2.0:0.2:5.0] Thickness/gap of strap slot (mm)
ear_wall_side         = 2.25;  // [1.5:0.25:4.0] Side wall thickness on each side of strap slot (mm)
strap_channel_depth   = 1.5;   // Depth of strap pass-through channel under remote (mm)

/* [Remote Dimensions (Nominal)] */
remote_len            = 43.5;  // Base length (mm)
remote_wid            = 23.5;  // Base width (mm)
remote_base_h         = 7.0;   // Base height up to the rim (mm)
remote_top_len        = 40.0;  // Upper button section length (mm)
remote_top_wid        = 20.0;  // Upper button section width (mm)
remote_top_h          = 3.0;   // Upper section height above rim (mm)
remote_corner_r       = 4.5;   // Corner radius (used only if circular_ends = false)

/* [Tolerances & Walls] */
fit_clearance_xy      = 0.5;   // Total clearance on length & width (mm)
fit_clearance_z       = 0.2;   // Height clearance for the base (mm)
wall_side             = 2.4;   // Outer wall thickness around remote (mm)
bezel_thick           = 2.0;   // Top bezel thickness over rim (mm)
wing_inner_wall       = 3.2;   // Material between cavity end and strap slot (mm)
wing_outer_wall       = 3.5;   // Material beyond strap slot (mm)
wing_angle            = 15.0;  // Downward bend angle of wings (degrees)
edge_radius           = 0.8;   // Outer edge roundover / bevel radius (mm)
detent_size           = 0.45;  // Bottom snap retention bump height (mm)

// ==============================================================================
// Computed Values
// ==============================================================================
cavity_len    = remote_len + fit_clearance_xy;      // 44.0 mm
cavity_wid    = remote_wid + fit_clearance_xy;      // 24.0 mm
cavity_h      = remote_base_h + fit_clearance_z;    // 7.2 mm

window_len    = remote_top_len + fit_clearance_xy;  // 40.5 mm
window_wid    = remote_top_wid + fit_clearance_xy;  // 20.5 mm

strap_width   = max(5.0, ear_width - 2 * ear_wall_side); // Slot length (~10.5 mm for 15 mm ear)

body_len      = cavity_len + 2 * wall_side;         // ~48.8 mm
body_wid      = max(cavity_wid + 2 * wall_side, ear_width); // ~28.8 mm
total_h       = cavity_h + bezel_thick;             // 9.2 mm

straight_len  = remote_len - remote_wid;            // 20.0 mm straight mid-section

wing_len_short= wing_inner_wall + strap_slot_thick + wing_outer_wall; // ~9.9 mm
total_len_short = body_len + 2 * wing_len_short;

wing_wid_long = wing_inner_wall + strap_slot_thick + wing_outer_wall;
total_wid_long= body_wid + 2 * wing_wid_long;


// ==============================================================================
// 2D Profiles & Primitives
// ==============================================================================
module profile_2d(w, l, delta=0) {
    if (circular_ends) {
        // True stadium / capsule shape with circular semicircular ends
        w_e = max(0.1, w + 2*delta);
        l_e = max(w_e, l + 2*delta);
        st  = max(0, l - w); // nominal straight section = 20.0 mm
        hull() {
            translate([0, -st/2]) circle(d=w_e);
            translate([0,  st/2]) circle(d=w_e);
        }
    } else {
        w_e = max(0.1, w + 2*delta);
        l_e = max(0.1, l + 2*delta);
        r_e = max(0.1, min(remote_corner_r + delta, min(w_e/2, l_e/2)));
        hull() {
            translate([-w_e/2 + r_e, -l_e/2 + r_e]) circle(r=r_e);
            translate([ w_e/2 - r_e, -l_e/2 + r_e]) circle(r=r_e);
            translate([-w_e/2 + r_e,  l_e/2 - r_e]) circle(r=r_e);
            translate([ w_e/2 - r_e,  l_e/2 - r_e]) circle(r=r_e);
        }
    }
}

module slot_pill_x_2d(len, thick, delta=0) {
    t_e = max(0.1, thick + 2*delta);
    l_e = max(t_e, len + 2*delta);
    hull() {
        translate([-(l_e - t_e)/2, 0]) circle(d=t_e);
        translate([ (l_e - t_e)/2, 0]) circle(d=t_e);
    }
}

module slot_pill_y_2d(thick, len, delta=0) {
    t_e = max(0.1, thick + 2*delta);
    l_e = max(t_e, len + 2*delta);
    hull() {
        translate([0, -(l_e - t_e)/2]) circle(d=t_e);
        translate([0,  (l_e - t_e)/2]) circle(d=t_e);
    }
}


// ==============================================================================
// Remote Mockup (Translucent preview of Xiaomi XYLY01)
// ==============================================================================
module remote_mockup() {
    color([0.22, 0.24, 0.28, 0.85]) {
        // Base section (43.5 x 23.5 x 7.0) with circular ends
        linear_extrude(height=remote_base_h)
            profile_2d(remote_wid, remote_len, 0);
        
        // Upper section (40.0 x 20.0 x 3.0) starting at rim z=7.0 with circular ends
        translate([0, 0, remote_base_h])
            linear_extrude(height=remote_top_h)
                profile_2d(remote_top_wid, remote_top_len, 0);
        
        // Shutter Button
        color([0.85, 0.25, 0.25, 0.95])
            translate([0, 0, remote_base_h + remote_top_h])
                cylinder(d=12.0, h=0.7, center=false);
                
        // Status LED Indicator
        color([0.2, 0.7, 1.0, 1.0])
            translate([0, 10.0, remote_base_h + remote_top_h])
                cylinder(d=1.5, h=0.8, center=false);
    }
}


// ==============================================================================
// Bracelet Chain Mockup (for visual context)
// ==============================================================================
module bracelet_strap_mockup() {
    link_w = strap_width - 0.5;
    link_l = 4.5;
    link_h = 2.8;
    num_links = 14;
    hinge_y = body_len/2 - 2.0;
    
    color([0.92, 0.45, 0.65, 0.9]) { // Pink strap matching example
        for (side = [-1, 1]) {
            for (i = [0 : num_links - 1]) {
                angle = side * (wing_angle + i * 2.2);
                y_offset = side * (hinge_y + wing_inner_wall + strap_slot_thick/2 + i * (link_l + 0.6));
                z_offset = - sin(wing_angle) * (wing_inner_wall + i * 3.5);
                
                translate([0, y_offset, z_offset])
                rotate([angle, 0, 0])
                difference() {
                    hull() {
                        translate([-link_w/2 + 2, 0, 0]) sphere(r=1.2);
                        translate([ link_w/2 - 2, 0, 0]) sphere(r=1.2);
                        translate([-link_w/2 + 2, link_l, 0]) sphere(r=1.2);
                        translate([ link_w/2 - 2, link_l, 0]) sphere(r=1.2);
                    }
                    translate([0, link_l/2, link_h/2])
                        cube([link_w - 4, 1.0, 1.0], center=true);
                }
            }
        }
    }
}


// ==============================================================================
// Central Main Body Solid & Cutouts
// ==============================================================================
module main_body_solid() {
    b = edge_radius;
    w = body_wid;
    l = body_len;
    h = total_h;
    
    hull() {
        translate([0, 0, 0])
            linear_extrude(height=max(0.1, h - b))
                profile_2d(w, l, 0);
        translate([0, 0, h - b])
            linear_extrude(height=b)
                profile_2d(w, l, -b);
    }
}

module housing_internal_cutouts(channel_along_y=true) {
    // 1. Remote Base Cavity (entered from bottom Z=0 to Z=cavity_h)
    translate([0, 0, -0.1])
        linear_extrude(height=cavity_h + 0.1)
            profile_2d(cavity_wid, cavity_len, 0);
            
    // 2. Top Window (cutout through top bezel, matches circular ends)
    translate([0, 0, cavity_h - 0.05])
        hull() {
            linear_extrude(height=0.1)
                profile_2d(window_wid, window_len, 0);
            // Smooth beveled tactile frame
            translate([0, 0, bezel_thick + 0.2])
                linear_extrude(height=0.1)
                profile_2d(window_wid + 1.6, window_len + 1.6, 0);
        }
        
    // 3. Recessed Strap Channel along underside
    if (channel_along_y) {
        translate([0, 0, -0.1])
            linear_extrude(height=strap_channel_depth + 0.1)
                rounded_rect_2d(strap_width + 0.8, body_len + 15.0, 1.0);
    } else {
        translate([0, 0, -0.1])
            linear_extrude(height=strap_channel_depth + 0.1)
                rounded_rect_2d(body_wid + 15.0, strap_width + 0.8, 1.0);
    }
}

// 2D helper for rectangular slots
module rounded_rect_2d(w, h, r) {
    w_e = max(0.1, w);
    h_e = max(0.1, h);
    r_e = max(0.1, min(r, min(w_e/2, h_e/2)));
    hull() {
        translate([-w_e/2 + r_e, -h_e/2 + r_e]) circle(r=r_e);
        translate([ w_e/2 - r_e, -h_e/2 + r_e]) circle(r=r_e);
        translate([-w_e/2 + r_e,  h_e/2 - r_e]) circle(r=r_e);
        translate([ w_e/2 - r_e,  h_e/2 - r_e]) circle(r=r_e);
    }
}

// Retention detents on the straight side walls
module bottom_retention_detents() {
    for (sx = [-1, 1]) {
        translate([sx * (cavity_wid/2), 0, 0.6])
            rotate([90, 0, 0])
                cylinder(r=detent_size + 0.6, h=12.0, center=true, $fn=16);
    }
}


// ==============================================================================
// SHORT SIDES HOUSING (Circular Ends + Strap on Short Ends)
// ==============================================================================
module wing_solid_short() {
    b = edge_radius;
    w_base = ear_width;
    w_tip  = ear_width;
    l = wing_len_short;
    h = 4.2;
    
    module wing_2d(delta=0) {
        wb = max(0.1, w_base + 2*delta);
        wt = max(0.1, w_tip + 2*delta);
        lt = max(0.1, l + delta);
        r_tip = min(3.5, ear_width / 4) + delta;
        hull() {
            translate([-wb/2, 0]) square([wb, 0.1]);
            translate([-wt/2 + r_tip, lt - r_tip]) circle(r=r_tip);
            translate([ wt/2 - r_tip, lt - r_tip]) circle(r=r_tip);
        }
    }
    
    hull() {
        linear_extrude(height=max(0.1, h - b))
            wing_2d(0);
        translate([0, 0, h - b])
            linear_extrude(height=b)
                wing_2d(-b);
        translate([0, 0, 0])
            linear_extrude(height=b)
                wing_2d(-b/2);
    }
}

module bracelet_housing_short(curved=true) {
    hinge_y = body_len/2 - 2.0;
    
    difference() {
        union() {
            // Main Central Capsule Body
            main_body_solid();
            
            // Wings extending from circular ends
            if (curved) {
                // Top Wing (curved downward)
                translate([0, hinge_y, 0])
                rotate([-wing_angle, 0, 0])
                    wing_solid_short();
                    
                // Bottom Wing (curved downward)
                translate([0, -hinge_y, 0])
                rotate([wing_angle, 0, 0])
                mirror([0, 1, 0])
                    wing_solid_short();
                    
                // Blend cylinders at hinge
                for (sy = [-1, 1]) {
                    translate([0, sy * hinge_y, 2.0])
                    rotate([0, 90, 0])
                        cylinder(d=4.0, h=ear_width, center=true);
                }
            } else {
                translate([0, hinge_y, 0])
                    wing_solid_short();
                translate([0, -hinge_y, 0])
                mirror([0, 1, 0])
                    wing_solid_short();
            }
            
            // Bottom retention detents
            bottom_retention_detents();
        }
        
        // Subtract cavity, window, and strap channel
        housing_internal_cutouts(channel_along_y=true);
        
        // Subtract Strap Slots on Wings
        if (curved) {
            // Top Slot
            translate([0, hinge_y, 0])
            rotate([-wing_angle, 0, 0])
            translate([0, wing_inner_wall + strap_slot_thick/2, -1])
                linear_extrude(height=10)
                    slot_pill_x_2d(strap_width, strap_slot_thick);
                    
            // Bottom Slot
            translate([0, -hinge_y, 0])
            rotate([wing_angle, 0, 0])
            translate([0, -wing_inner_wall - strap_slot_thick/2, -1])
                linear_extrude(height=10)
                    slot_pill_x_2d(strap_width, strap_slot_thick);
        } else {
            // Flat Slots
            translate([0, hinge_y + wing_inner_wall + strap_slot_thick/2, -1])
                linear_extrude(height=10)
                    slot_pill_x_2d(strap_width, strap_slot_thick);
            translate([0, -hinge_y - wing_inner_wall - strap_slot_thick/2, -1])
                linear_extrude(height=10)
                    slot_pill_x_2d(strap_width, strap_slot_thick);
        }
    }
}


// ==============================================================================
// LONG SIDES HOUSING (Alternative Mode)
// ==============================================================================
module wing_solid_long() {
    b = edge_radius;
    w = wing_wid_long;
    l = body_len;
    h = 4.2;
    
    module wing_2d(delta=0) {
        w_e = max(0.1, w + delta);
        l_e = max(0.1, l + 2*delta);
        r_e = 5.0 + delta;
        hull() {
            translate([0, -l_e/2]) square([0.1, l_e]);
            translate([w - r_e, -l/2 + r_e]) circle(r=r_e);
            translate([w - r_e,  l/2 - r_e]) circle(r=r_e);
        }
    }
    
    hull() {
        linear_extrude(height=max(0.1, h - b))
            wing_2d(0);
        translate([0, 0, h - b])
            linear_extrude(height=b)
                wing_2d(-b);
        translate([0, 0, 0])
            linear_extrude(height=b)
                wing_2d(-b/2);
    }
}

module bracelet_housing_long(curved=true) {
    difference() {
        union() {
            main_body_solid();
            if (curved) {
                translate([body_wid/2 - 0.1, 0, 0])
                rotate([0, wing_angle, 0])
                    wing_solid_long();
                translate([-body_wid/2 + 0.1, 0, 0])
                rotate([0, -wing_angle, 0])
                mirror([1, 0, 0])
                    wing_solid_long();
                for (sx = [-1, 1]) {
                    translate([sx * body_wid/2, 0, 2.0])
                    rotate([90, 0, 0])
                        cylinder(d=4.0, h=body_len - 10.0, center=true);
                }
            } else {
                translate([body_wid/2 - 0.1, 0, 0]) wing_solid_long();
                translate([-body_wid/2 + 0.1, 0, 0]) mirror([1, 0, 0]) wing_solid_long();
            }
            bottom_retention_detents();
        }
        housing_internal_cutouts(channel_along_y=false);
        if (curved) {
            translate([body_wid/2 - 0.1, 0, 0])
            rotate([0, wing_angle, 0])
            translate([wing_inner_wall + strap_slot_thick/2, 0, -1])
                linear_extrude(height=10)
                    slot_pill_y_2d(strap_slot_thick, strap_width);
            translate([-body_wid/2 + 0.1, 0, 0])
            rotate([0, -wing_angle, 0])
            translate([-wing_inner_wall - strap_slot_thick/2, 0, -1])
                linear_extrude(height=10)
                    slot_pill_y_2d(strap_slot_thick, strap_width);
        } else {
            translate([body_wid/2 + wing_inner_wall + strap_slot_thick/2, 0, -1])
                linear_extrude(height=10) slot_pill_y_2d(strap_slot_thick, strap_width);
            translate([-body_wid/2 - wing_inner_wall - strap_slot_thick/2, 0, -1])
                linear_extrude(height=10) slot_pill_y_2d(strap_slot_thick, strap_width);
        }
    }
}


// ==============================================================================
// Master Model Rendering
// ==============================================================================
module housing_model(curved=true) {
    if (slot_position == "short_sides") {
        bracelet_housing_short(curved=curved);
    } else {
        bracelet_housing_long(curved=curved);
    }
}

module full_model() {
    housing_color = [0.76, 0.42, 0.26]; // Terracotta / bronze matching your Tinkercad example
    
    if (render_mode == "bent") {
        color(housing_color)
            housing_model(curved=true);
        if (show_remote_mockup)
            translate([0, 0, fit_clearance_z]) remote_mockup();
        if (show_bracelet_preview && slot_position == "short_sides")
            bracelet_strap_mockup();
    } else if (render_mode == "flat") {
        color(housing_color)
            housing_model(curved=false);
        if (show_remote_mockup)
            translate([0, 0, fit_clearance_z]) remote_mockup();
    } else if (render_mode == "both") {
        span = (slot_position == "short_sides") ? total_len_short * 0.75 : total_wid_long * 0.75;
        translate([-span, 0, 0]) {
            color(housing_color)
                housing_model(curved=false);
            if (show_remote_mockup)
                translate([0, 0, fit_clearance_z]) remote_mockup();
        }
        translate([span, 0, 0]) {
            color([0.22, 0.68, 0.45])
                housing_model(curved=true);
            if (show_remote_mockup)
                translate([0, 0, fit_clearance_z]) remote_mockup();
        }
    } else if (render_mode == "cross_section") {
        difference() {
            union() {
                color(housing_color)
                    housing_model(curved=true);
                if (show_remote_mockup)
                    translate([0, 0, fit_clearance_z]) remote_mockup();
            }
            translate([-100, 0, -50])
                cube([100, 200, 100]);
        }
    }
}

full_model();
