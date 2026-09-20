// ==============================================================================
// Xiaomi Shutter Button (XYLY01) / Padel Racket Remote Holder Mount
// Parametric 3D Model for OpenSCAD with Smooth Rounded Edges
//
// Key Features:
//   - Fits Xiaomi / YI Bluetooth shutter button (XYLY01)
//   - Central Cutout: 12.5 mm (W) x 30.0 mm (H) with smooth beveled rims
//   - Configurable Slot Position: "short_sides" (top & bottom) or "long_sides" (left & right)
//   - Ergonomic downward wing angle (default 15°) to hug padel racket handle or wrist
//   - Smooth 3D edge roundovers (0.75 mm radius) on all outer rims, strap slots, and opening
//   - Fully 3D printable flat without supports ("flat" mode) or ready-curved ("bent" mode)
// ==============================================================================

$fn = 64;

// ==============================================================================
// User Configurable Parameters
// ==============================================================================

/* [Slot Position & Configuration] */
// Position of the 2 strap holes relative to the center hole
slot_position      = "short_sides"; // ["short_sides":Holes on top & bottom short sides, "long_sides":Holes on left & right long sides]

// Central Opening (Snug Fit for Xiaomi Shutter Button XYLY01)
cutout_width       = 12.5;  // Inside width of central opening (short side) (mm)
cutout_height      = 30.0;  // Inside height of central opening (long side) (mm)

/* [Strap Slots (when on short sides)] */
slot_length_short  = 20.0;  // [14.0:1.0:26.0] Length of strap slot on short sides (mm)
slot_width_short   = 4.0;   // [2.0:0.5:6.0] Thickness of strap slot on short sides (mm)
inner_margin_short = 5.0;   // [3.0:0.5:8.0] Wall thickness between slot and central cutout (mm)
outer_margin_short = 4.5;   // [3.0:0.5:8.0] Wall thickness beyond strap slot at ends (mm)
side_margin_short  = 5.5;   // [3.0:0.5:8.0] Wall thickness on long sides (left/right) (mm)

/* [Strap Slots (when on long sides)] */
slot_length_long   = 24.0;  // [16.0:1.0:30.0] Length of strap slot on long sides (mm)
slot_width_long    = 4.0;   // [2.0:0.5:6.0] Thickness of strap slot on long sides (mm)
inner_margin_long  = 5.5;   // [3.0:0.5:8.0] Wall thickness between slot and central cutout (mm)
outer_margin_long  = 3.5;   // [2.5:0.5:6.0] Wall thickness outside strap slot on wings (mm)
end_margin_long    = 6.0;   // [3.0:0.5:10.0] Wall thickness on short sides (top/bottom) (mm)

/* [Vertical Geometry & Curvature] */
thickness          = 2.5;   // [1.5:0.1:4.0] Material thickness (mm)
wing_angle         = 15.0;  // [0.0:1.0:45.0] Downward bend angle of wings in degrees
edge_radius        = 0.75;  // [0.0:0.05:1.2] 3D edge roundover radius (mm) - 0 for sharp edges

/* [Corner Radii (in 2D plane)] */
corner_radius_out  = 6.0;   // [2.0:0.5:10.0] Outer corner fillet radius (mm)
corner_radius_in   = 5.5;   // [2.0:0.5:6.0] Central opening corner fillet radius (mm)

/* [Render Mode] */
render_mode        = "bent"; // ["bent":Ergonomic Bent Wings, "flat":Flat Supportless Print, "both":Side-by-Side Comparison]


// ==============================================================================
// Computed Dimensions
// ==============================================================================
// For short sides:
wing_length_short  = inner_margin_short + slot_width_short + outer_margin_short; // ~13.5 mm
total_width_short  = max(cutout_width + 2 * side_margin_short, slot_length_short + 2 * 3.5); // ~27.0 mm
total_length_short = cutout_height + 2 * wing_length_short; // ~57.0 mm

// For long sides:
wing_width_long    = outer_margin_long + slot_width_long + inner_margin_long; // ~13.0 mm
total_height_long  = cutout_height + 2 * end_margin_long; // ~42.0 mm
total_width_long   = cutout_width + 2 * wing_width_long; // ~38.5 mm


// ==============================================================================
// 2D Profiles & Primitives
// ==============================================================================
module rounded_box_2d(w, h, r, delta=0) {
    w_eff = w + 2*delta;
    h_eff = h + 2*delta;
    r_eff = max(0.1, r + delta);
    hull() {
        translate([-w_eff/2 + r_eff, -h_eff/2 + r_eff]) circle(r=r_eff);
        translate([ w_eff/2 - r_eff, -h_eff/2 + r_eff]) circle(r=r_eff);
        translate([-w_eff/2 + r_eff,  h_eff/2 - r_eff]) circle(r=r_eff);
        translate([ w_eff/2 - r_eff,  h_eff/2 - r_eff]) circle(r=r_eff);
    }
}

// Slot pill oriented along X (length along X, thickness along Y)
module slot_pill_x_2d(len, thick, delta=0) {
    t_eff = max(0.1, thick + 2*delta);
    l_eff = max(t_eff, len + 2*delta);
    hull() {
        translate([-(l_eff - t_eff)/2, 0]) circle(d=t_eff);
        translate([ (l_eff - t_eff)/2, 0]) circle(d=t_eff);
    }
}

// Slot pill oriented along Y (thickness along X, length along Y)
module slot_pill_y_2d(thick, len, delta=0) {
    t_eff = max(0.1, thick + 2*delta);
    l_eff = max(t_eff, len + 2*delta);
    hull() {
        translate([0, -(l_eff - t_eff)/2]) circle(d=t_eff);
        translate([0,  (l_eff - t_eff)/2]) circle(d=t_eff);
    }
}


// ==============================================================================
// 3D Beveled Cutters & Tools
// ==============================================================================
module beveled_cutout_tool(w, h, r, t, b) {
    if (b <= 0.01) {
        linear_extrude(height=t*4, center=true)
            rounded_box_2d(w, h, r, delta=0);
    } else {
        hull() {
            linear_extrude(height = max(0.1, t - 2*b), center=true)
                rounded_box_2d(w, h, r, delta=0);
            translate([0, 0, (t + b)/2])
                linear_extrude(height = b, center=true)
                    rounded_box_2d(w, h, r, delta=b);
            translate([0, 0, -(t + b)/2])
                linear_extrude(height = b, center=true)
                    rounded_box_2d(w, h, r, delta=b);
        }
    }
}

module beveled_slot_tool_x(len, thick, t, b) {
    if (b <= 0.01) {
        linear_extrude(height=t*4, center=true)
            slot_pill_x_2d(len, thick, delta=0);
    } else {
        hull() {
            linear_extrude(height = max(0.1, t - 2*b), center=true)
                slot_pill_x_2d(len, thick, delta=0);
            translate([0, 0, (t + b)/2])
                linear_extrude(height = b, center=true)
                    slot_pill_x_2d(len, thick, delta=b);
            translate([0, 0, -(t + b)/2])
                linear_extrude(height = b, center=true)
                    slot_pill_x_2d(len, thick, delta=b);
        }
    }
}

module beveled_slot_tool_y(thick, len, t, b) {
    if (b <= 0.01) {
        linear_extrude(height=t*4, center=true)
            slot_pill_y_2d(thick, len, delta=0);
    } else {
        hull() {
            linear_extrude(height = max(0.1, t - 2*b), center=true)
                slot_pill_y_2d(thick, len, delta=0);
            translate([0, 0, (t + b)/2])
                linear_extrude(height = b, center=true)
                    slot_pill_y_2d(thick, len, delta=b);
            translate([0, 0, -(t + b)/2])
                linear_extrude(height = b, center=true)
                    slot_pill_y_2d(thick, len, delta=b);
        }
    }
}


// ==============================================================================
// MODEL IMPLEMENTATION: HOLES ON SHORT SIDES (Top & Bottom)
// ==============================================================================
module solid_center_short() {
    b = edge_radius;
    t = thickness;
    w = total_width_short;
    h = cutout_height + 0.1;
    if (b <= 0.01) {
        cube([w, h, t], center=true);
    } else {
        hull() {
            cube([w, h, max(0.1, t - 2*b)], center=true);
            translate([0, 0, (t - b)/2])
                cube([w - 2*b, h, b], center=true);
            translate([0, 0, -(t - b)/2])
                cube([w - 2*b, h, b], center=true);
        }
    }
}

module solid_wing_short() {
    b = edge_radius;
    t = thickness;
    w = total_width_short;
    l = wing_length_short;
    module wing_2d(delta=0) {
        w_eff = w + 2*delta;
        r_eff = max(0.1, corner_radius_out + delta);
        hull() {
            translate([-w_eff/2, 0]) square([w_eff, 0.2]);
            translate([-w/2 + corner_radius_out, l - corner_radius_out])
                circle(r=r_eff);
            translate([ w/2 - corner_radius_out, l - corner_radius_out])
                circle(r=r_eff);
        }
    }
    
    if (b <= 0.01) {
        linear_extrude(height=t, center=true)
            wing_2d(0);
    } else {
        hull() {
            linear_extrude(height = max(0.1, t - 2*b), center=true)
                wing_2d(0);
            translate([0, 0, (t - b)/2])
                linear_extrude(height = b, center=true)
                    wing_2d(-b);
            translate([0, 0, -(t - b)/2])
                linear_extrude(height = b, center=true)
                    wing_2d(-b);
        }
    }
}

module strap_holder_short_bent() {
    b = edge_radius;
    t = thickness;
    w = total_width_short;
    difference() {
        union() {
            solid_center_short();
            
            // Top wing (at +cutout_height/2)
            translate([0, cutout_height/2, 0])
            rotate([-wing_angle, 0, 0])
                solid_wing_short();
                
            // Bottom wing (at -cutout_height/2)
            translate([0, -cutout_height/2, 0])
            rotate([wing_angle, 0, 0])
            mirror([0, 1, 0])
                solid_wing_short();
                
            // Seamless hinge cylinders at bend lines
            for (sy = [-1, 1]) {
                translate([0, sy * cutout_height/2, 0])
                rotate([0, 90, 0])
                if (b > 0.01) {
                    hull() {
                        cylinder(d=t, h=w - 2*b, center=true);
                        cylinder(d=t - 2*b, h=w, center=true);
                    }
                } else {
                    cylinder(d=t, h=w, center=true);
                }
            }
        }
        
        // Central cutout (snug fit for remote)
        beveled_cutout_tool(cutout_width, cutout_height, corner_radius_in, t, b);
        
        // Top strap slot (perpendicular to top wing)
        translate([0, cutout_height/2, 0])
        rotate([-wing_angle, 0, 0])
        translate([0, inner_margin_short + slot_width_short/2, 0])
            beveled_slot_tool_x(slot_length_short, slot_width_short, t, b);
            
        // Bottom strap slot (perpendicular to bottom wing)
        translate([0, -cutout_height/2, 0])
        rotate([wing_angle, 0, 0])
        translate([0, -inner_margin_short - slot_width_short/2, 0])
            beveled_slot_tool_x(slot_length_short, slot_width_short, t, b);
    }
}

module strap_holder_short_flat() {
    b = edge_radius;
    t = thickness;
    w = total_width_short;
    l = total_length_short;
    difference() {
        if (b <= 0.01) {
            linear_extrude(height=t, center=true)
                rounded_box_2d(w, l, corner_radius_out, delta=0);
        } else {
            hull() {
                linear_extrude(height = max(0.1, t - 2*b), center=true)
                    rounded_box_2d(w, l, corner_radius_out, delta=0);
                translate([0, 0, (t - b)/2])
                    linear_extrude(height = b, center=true)
                        rounded_box_2d(w, l, corner_radius_out, delta=-b);
                translate([0, 0, -(t - b)/2])
                    linear_extrude(height = b, center=true)
                        rounded_box_2d(w, l, corner_radius_out, delta=-b);
            }
        }
        
        // Central cutout
        beveled_cutout_tool(cutout_width, cutout_height, corner_radius_in, t, b);
        
        // Top strap slot
        translate([0, cutout_height/2 + inner_margin_short + slot_width_short/2, 0])
            beveled_slot_tool_x(slot_length_short, slot_width_short, t, b);
            
        // Bottom strap slot
        translate([0, -cutout_height/2 - inner_margin_short - slot_width_short/2, 0])
            beveled_slot_tool_x(slot_length_short, slot_width_short, t, b);
    }
}


// ==============================================================================
// MODEL IMPLEMENTATION: HOLES ON LONG SIDES (Left & Right)
// ==============================================================================
module solid_center_long() {
    b = edge_radius;
    t = thickness;
    w = cutout_width + 0.1;
    h = total_height_long;
    if (b <= 0.01) {
        cube([w, h, t], center=true);
    } else {
        hull() {
            cube([w, h, max(0.1, t - 2*b)], center=true);
            translate([0, 0, (t - b)/2])
                cube([w, h - 2*b, b], center=true);
            translate([0, 0, -(t - b)/2])
                cube([w, h - 2*b, b], center=true);
        }
    }
}

module solid_wing_long() {
    b = edge_radius;
    t = thickness;
    w = wing_width_long;
    h = total_height_long;
    module wing_2d(delta=0) {
        h_eff = h + 2*delta;
        r_eff = max(0.1, corner_radius_out + delta);
        hull() {
            translate([0, -h_eff/2]) square([0.2, h_eff]);
            translate([w - corner_radius_out, -h/2 + corner_radius_out]) 
                circle(r=r_eff);
            translate([w - corner_radius_out,  h/2 - corner_radius_out]) 
                circle(r=r_eff);
        }
    }
    
    if (b <= 0.01) {
        linear_extrude(height=t, center=true)
            wing_2d(0);
    } else {
        hull() {
            linear_extrude(height = max(0.1, t - 2*b), center=true)
                wing_2d(0);
            translate([0, 0, (t - b)/2])
                linear_extrude(height = b, center=true)
                    wing_2d(-b);
            translate([0, 0, -(t - b)/2])
                linear_extrude(height = b, center=true)
                    wing_2d(-b);
        }
    }
}

module strap_holder_long_bent() {
    b = edge_radius;
    t = thickness;
    h = total_height_long;
    difference() {
        union() {
            solid_center_long();
            
            // Right wing
            translate([cutout_width/2, 0, 0])
            rotate([0, wing_angle, 0])
                solid_wing_long();
                
            // Left wing
            translate([-cutout_width/2, 0, 0])
            rotate([0, -wing_angle, 0])
            mirror([1, 0, 0])
                solid_wing_long();
                
            // Seamless hinge cylinders at bend lines
            for (sx = [-1, 1]) {
                translate([sx * cutout_width/2, 0, 0])
                rotate([90, 0, 0])
                if (b > 0.01) {
                    hull() {
                        cylinder(d=t, h=h - 2*b, center=true);
                        cylinder(d=t - 2*b, h=h, center=true);
                    }
                } else {
                    cylinder(d=t, h=h, center=true);
                }
            }
        }
        
        // Central cutout
        beveled_cutout_tool(cutout_width, cutout_height, corner_radius_in, t, b);
        
        // Right strap slot
        translate([cutout_width/2, 0, 0])
        rotate([0, wing_angle, 0])
        translate([inner_margin_long + slot_width_long/2, 0, 0])
            beveled_slot_tool_y(slot_width_long, slot_length_long, t, b);
            
        // Left strap slot
        translate([-cutout_width/2, 0, 0])
        rotate([0, -wing_angle, 0])
        translate([-inner_margin_long - slot_width_long/2, 0, 0])
            beveled_slot_tool_y(slot_width_long, slot_length_long, t, b);
    }
}

module strap_holder_long_flat() {
    b = edge_radius;
    t = thickness;
    w = total_width_long;
    h = total_height_long;
    difference() {
        if (b <= 0.01) {
            linear_extrude(height=t, center=true)
                rounded_box_2d(w, h, corner_radius_out, delta=0);
        } else {
            hull() {
                linear_extrude(height = max(0.1, t - 2*b), center=true)
                    rounded_box_2d(w, h, corner_radius_out, delta=0);
                translate([0, 0, (t - b)/2])
                    linear_extrude(height = b, center=true)
                        rounded_box_2d(w, h, corner_radius_out, delta=-b);
                translate([0, 0, -(t - b)/2])
                    linear_extrude(height = b, center=true)
                        rounded_box_2d(w, h, corner_radius_out, delta=-b);
            }
        }
        
        // Central cutout
        beveled_cutout_tool(cutout_width, cutout_height, corner_radius_in, t, b);
        
        // Left strap slot
        translate([-cutout_width/2 - inner_margin_long - slot_width_long/2, 0, 0])
            beveled_slot_tool_y(slot_width_long, slot_length_long, t, b);
            
        // Right strap slot
        translate([ cutout_width/2 + inner_margin_long + slot_width_long/2, 0, 0])
            beveled_slot_tool_y(slot_width_long, slot_length_long, t, b);
    }
}


// ==============================================================================
// Output Selection
// ==============================================================================
if (slot_position == "short_sides") {
    if (render_mode == "bent") {
        strap_holder_short_bent();
    } else if (render_mode == "flat") {
        strap_holder_short_flat();
    } else if (render_mode == "both") {
        translate([-total_width_short * 0.75, 0, 0])
            strap_holder_short_flat();
        translate([ total_width_short * 0.75, 0, 0])
            strap_holder_short_bent();
    }
} else {
    if (render_mode == "bent") {
        strap_holder_long_bent();
    } else if (render_mode == "flat") {
        strap_holder_long_flat();
    } else if (render_mode == "both") {
        translate([-total_width_long * 0.65, 0, 0])
            strap_holder_long_flat();
        translate([ total_width_long * 0.65, 0, 0])
            strap_holder_long_bent();
    }
}
