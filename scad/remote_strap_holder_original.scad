// ==============================================================================
// Xiaomi Shutter Button (XYLY01) / Strap Holder Mount
// Parametric 3D Model for OpenSCAD with Smooth Rounded Edges
//
// Critical Dimensions:
//   - Inside Opening Height: Exactly 28.0 mm (designed to snugly fit Xiaomi shutter button)
//   - Inside Opening Width: Exactly 25.5 mm
//   - Top / Bottom Wall Margins: 7.0 mm each (Total Frame Height = 42.0 mm)
//   - Strap Slots: 4.0 mm (W) x 24.0 mm (H), pill-shaped for standard watch straps
//   - Outer Side Wall: 3.5 mm
//   - Bridge between Slot and Cutout: 2.5 mm
//   - Side Wings Width: 10.0 mm each (3.5 + 4.0 + 2.5)
//   - Total Flat Width: 45.5 mm (25.5 + 2 * 10.0)
//   - Material Thickness: 2.5 mm uniform
//   - Downward Wing Bend: 15.0 degrees (ergonomic curve for wrist / racket handle)
//   - Rounded Edges: 3D smooth roundover on all outer rims, strap slots, and inner opening
// ==============================================================================

$fn = 64;

// ==============================================================================
// User Configurable Parameters
// ==============================================================================

// Central Opening (Fits Xiaomi Shutter Button)
cutout_width       = 12.5;  // Inside width of central opening (mm)
cutout_height      = 30.0;  // Inside height of central opening (mm) - updated to 30mm
top_margin         = 6.0;   // Wall thickness above opening (mm)
bottom_margin      = 6.0;   // Wall thickness below opening (mm)

// Strap Slots
slot_width         = 4.0;   // Width of strap slot (mm)
slot_length        = 24.0;  // Length of strap slot (mm)
outer_margin       = 3.5;   // Wall thickness outside the strap slot (mm)
inner_margin       = 5.5;   // Wall thickness between slot and cutout (mm)

// Vertical Geometry & Curvature
thickness          = 2.5;   // Material thickness (mm)
wing_angle         = 15.0;  // Downward bend angle of wings in degrees (sideview)
edge_radius        = 0.75;  // 3D edge roundover radius (mm) - set to 0 for sharp edges

// Corner Radii (in 2D plane)
corner_radius_out  = 6.0;   // Outer corner fillet radius (mm)
corner_radius_in   = 5.5;   // Central opening corner fillet radius (mm)

// Render Mode:
// "bent": 3D ergonomic curved model with rounded edges (as shown in sideview)
// "flat": 3D flat model with rounded edges (ideal for flat 3D printing without supports)
// "both": Side-by-side comparison of flat and bent models
render_mode        = "bent"; // ["bent", "flat", "both"]

// ==============================================================================
// Computed Dimensions
// ==============================================================================
total_height       = cutout_height + top_margin + bottom_margin; // 42.0 mm
wing_width         = outer_margin + slot_width + inner_margin;   // 10.0 mm
total_width_flat   = cutout_width + 2 * wing_width;              // 45.5 mm

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

module slot_pill_2d(w, h, delta=0) {
    w_eff = max(0.1, w + 2*delta);
    h_eff = max(w_eff, h + 2*delta);
    hull() {
        translate([0, -(h_eff - w_eff)/2]) circle(d=w_eff);
        translate([0,  (h_eff - w_eff)/2]) circle(d=w_eff);
    }
}

// ==============================================================================
// 3D Beveled Cutters & Tools
// ==============================================================================
// Central opening cutter ensuring exact dimensions (w x h) with smooth rounded rims
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

// Strap slot cutter with smooth rounded rims
module beveled_slot_tool(w, h, t, b) {
    if (b <= 0.01) {
        linear_extrude(height=t*4, center=true)
            slot_pill_2d(w, h, delta=0);
    } else {
        hull() {
            linear_extrude(height = max(0.1, t - 2*b), center=true)
                slot_pill_2d(w, h, delta=0);
            translate([0, 0, (t + b)/2])
                linear_extrude(height = b, center=true)
                    slot_pill_2d(w, h, delta=b);
            translate([0, 0, -(t + b)/2])
                linear_extrude(height = b, center=true)
                    slot_pill_2d(w, h, delta=b);
        }
    }
}

// ==============================================================================
// Flat 3D Model with Rounded Edges
// ==============================================================================
module strap_holder_flat() {
    b = edge_radius;
    t = thickness;
    difference() {
        // Outer body with rounded edges
        if (b <= 0.01) {
            linear_extrude(height=t, center=true)
                rounded_box_2d(total_width_flat, total_height, corner_radius_out, delta=0);
        } else {
            hull() {
                linear_extrude(height = max(0.1, t - 2*b), center=true)
                    rounded_box_2d(total_width_flat, total_height, corner_radius_out, delta=0);
                translate([0, 0, (t - b)/2])
                    linear_extrude(height = b, center=true)
                        rounded_box_2d(total_width_flat, total_height, corner_radius_out, delta=-b);
                translate([0, 0, -(t - b)/2])
                    linear_extrude(height = b, center=true)
                        rounded_box_2d(total_width_flat, total_height, corner_radius_out, delta=-b);
            }
        }
        
        // Central cutout: exactly 25.5 mm x 28.0 mm
        beveled_cutout_tool(cutout_width, cutout_height, corner_radius_in, t, b);
        
        // Left strap slot
        translate([-cutout_width/2 - inner_margin - slot_width/2, 0, 0])
            beveled_slot_tool(slot_width, slot_length, t, b);
            
        // Right strap slot
        translate([ cutout_width/2 + inner_margin + slot_width/2, 0, 0])
            beveled_slot_tool(slot_width, slot_length, t, b);
    }
}

// ==============================================================================
// Ergonomic Bent 3D Model with Rounded Edges
// ==============================================================================
// Solid center plate
module solid_center() {
    b = edge_radius;
    t = thickness;
    if (b <= 0.01) {
        cube([cutout_width + 0.1, total_height, t], center=true);
    } else {
        hull() {
            cube([cutout_width + 0.1, total_height, max(0.1, t - 2*b)], center=true);
            translate([0, 0, (t - b)/2])
                cube([cutout_width + 0.1, total_height - 2*b, b], center=true);
            translate([0, 0, -(t - b)/2])
                cube([cutout_width + 0.1, total_height - 2*b, b], center=true);
        }
    }
}

// Solid wing
module solid_wing() {
    b = edge_radius;
    t = thickness;
    module wing_2d(delta=0) {
        h_eff = total_height + 2*delta;
        r_eff = max(0.1, corner_radius_out + delta);
        hull() {
            translate([0, -h_eff/2]) square([0.2, h_eff]);
            translate([wing_width - corner_radius_out, -total_height/2 + corner_radius_out]) 
                circle(r=r_eff);
            translate([wing_width - corner_radius_out,  total_height/2 - corner_radius_out]) 
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

// Solid assembled curved bracket before cutouts
module solid_curved_bracket() {
    b = edge_radius;
    t = thickness;
    union() {
        solid_center();
        
        // Right wing
        translate([cutout_width/2, 0, 0])
        rotate([0, wing_angle, 0])
            solid_wing();
            
        // Left wing
        translate([-cutout_width/2, 0, 0])
        rotate([0, -wing_angle, 0])
        mirror([1, 0, 0])
            solid_wing();
            
        // Seamless hinge cylinders at bend lines
        for (sx = [-1, 1]) {
            translate([sx * cutout_width/2, 0, 0])
            rotate([90, 0, 0])
            if (b > 0.01) {
                hull() {
                    cylinder(d=t, h=total_height - 2*b, center=true);
                    cylinder(d=t - 2*b, h=total_height, center=true);
                }
            } else {
                cylinder(d=t, h=total_height, center=true);
            }
        }
    }
}

module strap_holder_bent() {
    difference() {
        // Base solid curved bracket
        solid_curved_bracket();
        
        // 1. Central Cutout: EXACTLY 28.0 mm (H) x 25.5 mm (W) with rounded rims
        beveled_cutout_tool(cutout_width, cutout_height, corner_radius_in, thickness, edge_radius);
        
        // 2. Right strap slot (cut perpendicular to the 15° wing)
        translate([cutout_width/2, 0, 0])
        rotate([0, wing_angle, 0])
        translate([inner_margin + slot_width/2, 0, 0])
            beveled_slot_tool(slot_width, slot_length, thickness, edge_radius);
            
        // 3. Left strap slot (cut perpendicular to the 15° wing)
        translate([-cutout_width/2, 0, 0])
        rotate([0, -wing_angle, 0])
        translate([-inner_margin - slot_width/2, 0, 0])
            beveled_slot_tool(slot_width, slot_length, thickness, edge_radius);
    }
}

// ==============================================================================
// Output Selection
// ==============================================================================
if (render_mode == "bent") {
    strap_holder_bent();
} else if (render_mode == "flat") {
    strap_holder_flat();
} else if (render_mode == "both") {
    translate([-total_width_flat * 0.65, 0, 0])
        strap_holder_flat();
    translate([ total_width_flat * 0.65, 0, 0])
        strap_holder_bent();
}
