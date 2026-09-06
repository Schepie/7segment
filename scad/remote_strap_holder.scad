// ==============================================================================
// Xiaomi Shutter Button (XYLY01) / Padel Racket Remote Holder Mount
// Parametric 3D Model for OpenSCAD with Inward-Curled Elastic Band ("Rekker") Hooks
//
// Key Features:
//   - Fits Xiaomi / YI Bluetooth shutter button (XYLY01)
//   - Central Cutout: 12.5 mm (W) x 30.0 mm (H) with smooth beveled rims
//   - Inward-Curling Elastic Band Hooks: Specially shaped retention horns curl
//     inward over a 4.2 mm circular pocket to prevent rubber bands / O-rings from
//     slipping off during intense padel match play
//   - Ergonomic 15° downward wing angle to hug the padel racket handle curvature
//   - Smooth 3D edge roundovers (0.75 mm radius) on all perimeters, cutout rims, and hooks
//   - Fully 3D printable flat without supports ("flat" mode) or ready-curved ("bent" mode)
// ==============================================================================

$fn = 64;

// ==============================================================================
// User Configurable Parameters
// ==============================================================================

// Central Opening (Snug Fit for Xiaomi Shutter Button XYLY01)
cutout_width       = 12.5;  // Inside width of central opening (mm)
cutout_height      = 30.0;  // Inside height of central opening (mm) - updated to 30mm
top_margin         = 6.0;   // Wall thickness above opening (mm)
bottom_margin      = 6.0;   // Wall thickness below opening (mm)

// Strap Slots (geometry margins)
slot_width         = 4.0;   // Width of strap slot (mm)
slot_length        = 24.0;  // Length of strap slot (mm)
outer_margin       = 3.5;   // Wall thickness outside the strap slot (mm)
inner_margin       = 5.5;   // Wall thickness between slot and cutout (mm)

// Vertical Geometry & Curvature
thickness          = 2.5;   // [1.5:0.1:4.0] Material thickness (mm)
wing_angle         = 15.0;  // [0.0:1.0:45.0] Downward bend angle of wings in degrees (sideview)
edge_radius        = 0.75;  // [0.0:0.05:1.2] 3D edge roundover radius (mm) - set to 0 for sharp edges

// Corner Radii (in 2D plane)
corner_radius_out  = 6.0;   // [2.0:0.5:10.0] Outer corner fillet radius (mm)
corner_radius_in   = 5.5;   // [2.0:0.5:6.0] Central opening corner fillet radius (mm)

// Render Mode:
render_mode        = "bent"; // [bent:Ergonomic Bent Wings, flat:Flat Supportless Print, both:Side-by-Side Comparison]

// Preview Options (for OpenSCAD interactive GUI)
show_racket_handle = false; // Show simulated padel racket handle in preview
show_rubber_bands  = false; // Show simulated rubber bands in preview


// ==============================================================================
// Computed Dimensions
// ==============================================================================
total_height       = cutout_height + top_margin + bottom_margin; // 42.0 mm
wing_width         = inner_margin + slot_width + outer_margin;   // 13.0 mm
total_width_flat   = cutout_width + 2 * wing_width;              // 38.5 mm

// ==============================================================================
// 2D Profiles & Beveled Tool Helpers
// ==============================================================================

// 2D Central Cutout Profile
module cutout_2d(d=0) {
    w_eff = max(0.1, cutout_width + 2*d);
    h_eff = max(0.1, cutout_height + 2*d);
    r_eff = max(0.1, min(corner_radius_in + d, min(w_eff/2, h_eff/2)));
    offset(r=d)
    hull() {
        translate([-cutout_width/2 + corner_radius_in, -cutout_height/2 + corner_radius_in]) circle(r=corner_radius_in);
        translate([ cutout_width/2 - corner_radius_in, -cutout_height/2 + corner_radius_in]) circle(r=corner_radius_in);
        translate([-cutout_width/2 + corner_radius_in,  cutout_height/2 - corner_radius_in]) circle(r=corner_radius_in);
        translate([ cutout_width/2 - corner_radius_in,  cutout_height/2 - corner_radius_in]) circle(r=corner_radius_in);
    }
}

// 3D Beveled Tool for Cutout
module beveled_cutout_tool(t, b) {
    if (b <= 0.01) {
        linear_extrude(height=t*4, center=true) cutout_2d(0);
    } else {
        hull() {
            linear_extrude(height = max(0.1, t - 2*b), center=true) cutout_2d(0);
            translate([0, 0, (t + b)/2]) linear_extrude(height = b, center=true) cutout_2d(b);
            translate([0, 0, -(t + b)/2]) linear_extrude(height = b, center=true) cutout_2d(b);
        }
    }
}

// ==============================================================================
// Wing with Inward-Curled Elastic Band Hooks
// ==============================================================================
module curled_wing_3d() {
    b = edge_radius;
    t = thickness;
    
    // Convex solid wing body with rounded outer corners
    module solid_wing_2d(d=0) {
        h_eff = total_height + 2*d;
        r_eff = max(0.1, corner_radius_out + d);
        hull() {
            translate([0, -h_eff/2]) square([0.2, h_eff]);
            translate([wing_width - corner_radius_out, -total_height/2 + corner_radius_out]) 
                circle(r=r_eff);
            translate([wing_width - corner_radius_out,  total_height/2 - corner_radius_out]) 
                circle(r=r_eff);
        }
    }
    
    // Inward Curled Hook Cutters:
    // Leaves a secure inward-curling horn wrapping around a 4.2mm round catch pocket
    module top_notch_cutter_2d(d=0) {
        offset(r=d)
        translate([wing_width - 5.5, total_height/2]) {
            // Angled entry throat
            hull() {
                translate([-3.0, 2.0]) circle(d=3.0);
                translate([-1.5, -3.5]) circle(d=3.2);
            }
            // Round retention pocket
            translate([1.0, -4.5]) circle(d=4.2);
            // Throat to pocket transition
            hull() {
                translate([-1.5, -3.5]) circle(d=3.2);
                translate([1.0, -4.5]) circle(d=4.0);
            }
        }
    }
    
    module bottom_notch_cutter_2d(d=0) {
        offset(r=d)
        translate([wing_width - 5.5, -total_height/2])
        mirror([0, 1, 0]) {
            hull() {
                translate([-3.0, 2.0]) circle(d=3.0);
                translate([-1.5, -3.5]) circle(d=3.2);
            }
            translate([1.0, -4.5]) circle(d=4.2);
            hull() {
                translate([-1.5, -3.5]) circle(d=3.2);
                translate([1.0, -4.5]) circle(d=4.0);
            }
        }
    }
    
    module waist_cutter_2d(d=0) {
        offset(r=d)
        translate([wing_width + 4.0, 0])
            circle(r=8.0);
    }
    
    module beveled_solid() {
        if (b <= 0.01) {
            linear_extrude(height = t, center=true) solid_wing_2d(0);
        } else {
            hull() {
                linear_extrude(height = max(0.1, t - 2*b), center=true) solid_wing_2d(0);
                translate([0, 0, (t - b)/2]) linear_extrude(height = b, center=true) solid_wing_2d(-b);
                translate([0, 0, -(t - b)/2]) linear_extrude(height = b, center=true) solid_wing_2d(-b);
            }
        }
    }
    
    module beveled_cut(type) {
        if (b <= 0.01) {
            linear_extrude(height = t*4, center=true)
                if (type == "top") top_notch_cutter_2d(0);
                else if (type == "bot") bottom_notch_cutter_2d(0);
                else waist_cutter_2d(0);
        } else {
            hull() {
                linear_extrude(height = max(0.1, t - 2*b), center=true) 
                    if (type == "top") top_notch_cutter_2d(0);
                    else if (type == "bot") bottom_notch_cutter_2d(0);
                    else waist_cutter_2d(0);
                translate([0, 0, (t + b)/2]) linear_extrude(height = b, center=true) 
                    if (type == "top") top_notch_cutter_2d(b);
                    else if (type == "bot") bottom_notch_cutter_2d(b);
                    else waist_cutter_2d(b);
                translate([0, 0, -(t + b)/2]) linear_extrude(height = b, center=true) 
                    if (type == "top") top_notch_cutter_2d(b);
                    else if (type == "bot") bottom_notch_cutter_2d(b);
                    else waist_cutter_2d(b);
            }
        }
    }
    
    difference() {
        beveled_solid();
        beveled_cut("top");
        beveled_cut("bot");
        beveled_cut("waist");
    }
}

// Center Plate 3D
module center_plate_3d() {
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

// ==============================================================================
// Full 3D Assembled Bent Model
// ==============================================================================
module remote_holder_bent() {
    difference() {
        union() {
            center_plate_3d();
            
            // Right wing with curled hooks
            translate([cutout_width/2, 0, 0])
            rotate([0, wing_angle, 0])
                curled_wing_3d();
                
            // Left wing with curled hooks
            translate([-cutout_width/2, 0, 0])
            rotate([0, -wing_angle, 0])
            mirror([1, 0, 0])
                curled_wing_3d();
                
            // Smooth cylindrical blend along the bend hinges
            for (sx = [-1, 1]) {
                translate([sx * cutout_width/2, 0, 0])
                rotate([90, 0, 0])
                if (edge_radius <= 0.01) {
                    cylinder(d = thickness, h = total_height, center=true);
                } else {
                    hull() {
                        cylinder(d = thickness, h = total_height - 2*edge_radius, center=true);
                        cylinder(d = thickness - 2*edge_radius, h = total_height, center=true);
                    }
                }
            }
        }
        
        // Central opening: 12.5 mm x 30.0 mm with beveled rims
        beveled_cutout_tool(thickness, edge_radius);
    }
}

// ==============================================================================
// Full 3D Assembled Flat Model
// ==============================================================================
module remote_holder_flat() {
    difference() {
        union() {
            center_plate_3d();
            translate([cutout_width/2, 0, 0])
                curled_wing_3d();
            translate([-cutout_width/2, 0, 0])
            mirror([1, 0, 0])
                curled_wing_3d();
        }
        beveled_cutout_tool(thickness, edge_radius);
    }
}

// ==============================================================================
// Previews & Demonstrations
// ==============================================================================
module padel_handle_preview() {
    color([0.25, 0.25, 0.28, 0.65])
    translate([0, 0, -18])
    rotate([90, 0, 0])
    cylinder(d=31, h=90, center=true, $fn=8); // Octagonal handle d=31mm
}

module rubber_bands_preview() {
    color([0.95, 0.15, 0.15, 0.9]) { // Red silicone/rubber bands
        // Dynamic pocket coordinates based on wing_angle
        pocket_x = cutout_width/2 + (wing_width - 4.5) * cos(wing_angle);
        pocket_z = -(wing_width - 4.5) * sin(wing_angle);
        for (sy = [-16.5, 16.5]) {
            translate([0, sy, -18])
            rotate([90, 0, 0])
            difference() {
                cylinder(d=34.0, h=3.0, center=true);
                cylinder(d=28.5, h=4.0, center=true);
                translate([0, 20, 0]) cube([40, 40, 5], center=true);
            }
            for (sx = [-1, 1]) {
                translate([sx * pocket_x, sy, pocket_z - 7.5])
                    cube([2.8, 2.8, 15], center=true);
            }
        }
    }
}

// ==============================================================================
// Output Selection
// ==============================================================================
if (render_mode == "bent") {
    remote_holder_bent();
    if (show_racket_handle) padel_handle_preview();
    if (show_rubber_bands) rubber_bands_preview();
} else if (render_mode == "flat") {
    remote_holder_flat();
} else if (render_mode == "both") {
    translate([-total_width_flat * 0.7, 0, 0])
        remote_holder_flat();
    translate([ total_width_flat * 0.7, 0, 0]) {
        remote_holder_bent();
        if (show_racket_handle) padel_handle_preview();
        if (show_rubber_bands) rubber_bands_preview();
    }
}
