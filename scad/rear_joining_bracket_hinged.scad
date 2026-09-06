// ==============================================================================
// Hinged Rear Joining Bracket with 3D-Printable Snap Pin (Palletje)
// For Modular 7-Segment Display / Bambu Lab / FDM 3D Printing
// ==============================================================================
//
// Mounts across the rear seam between two adjacent 7-segment digit or colon panels.
// Matches the exact M3 corner screw positions of the original rigid rear_joining_bracket
// (center-to-center hole pitch = 12.0 mm, spanning X = -6.0 mm and X = +6.0 mm).
//
// Retention Mechanism (Hoe blijft het palletje zitten?):
// - Includes a dedicated 3D-printable snap pin with a retaining head flange on one end
//   and a split-compression barb on the other end.
// - Pushing the pin in compresses the split tip through the 3.2 mm knuckle bore;
//   once through, it snaps open and locks permanently over the far edge.
// - 100% tool-free, no screws, nuts, or glue required!
//
// Clearance & Access Guaranteed:
// - Knuckle outer diameter is compact (4.8 mm, radius 2.4 mm).
// - Knuckle transition ramps are strictly constrained to |X| <= 2.4 mm.
// - Screw holes and countersinks at X = +/-6.0 mm sit on a completely flat,
//   unobstructed 3.0 mm plate with >0.6 mm clearance to the hinge barrel.
// - Screwdriver and screw heads have 100% full vertical clearance.
// ==============================================================================

/* [Configuration & Display] */
// What part to generate
part = 1; // [1:"set - Complete print set: Left + Right + Snap Pin on bed", 2:"assembled - Assembled preview with pin", 3:"left - Left leaf only", 4:"right - Right leaf only", 5:"pin - Snap pin only (vertical)", 6:"pin_flat - Snap pin only (horizontal flat)"]

// Folding angle in degrees (assembled preview mode: 0 = flat, 90 = right angle, 180 = folded back)
fold_angle = 0; // [0:5:180]

// Show simulated hinge pin in assembled preview
show_pin = true;

/* [Mechanical Dimensions] */
// Base plate thickness (matches rigid bracket)
thickness = 3.0;

// Total width across seam (14 mm on each panel)
bracket_w = 28.0;

// Center-to-center distance between panel corner screws
hole_pitch = 12.0;

// Extension inward towards display center
inward_len = 12.0;

// Margin towards outer panel rim (stays 1.0mm inside housing edge)
edge_margin = 5.0;

// Outer corner radius
fillet_r = 2.5;

// Use countersunk holes for M3 flat-head screws
countersunk = true;

/* [Hinge Joint Parameters] */
// Diameter of the hinge pin bore
pin_d = 3.2;

// Outer diameter of the knuckle barrel (4.8 mm leaves >0.6 mm gap to M3 countersink)
knuckle_d = 4.8;

// Clearance gap between interlocking knuckles
clearance = 0.30;

// Seam gap between left and right leaf flat plates
seam_gap = 0.25;

/* [Snap Pin Parameters] */
pin_shaft_d = 2.95; // Smooth fit inside 3.2mm bore
pin_head_d  = 5.2;  // Flange diameter resting against knuckle end
pin_head_h  = 1.4;  // Flange thickness
pin_barb_d  = 3.45; // Expands to lock over 3.2mm bore
pin_barb_len= 1.2;  // Barb ramp length
pin_slot_w  = 0.7;  // Flexible compression slot width
pin_slot_len= 5.0;  // Compression slot depth

/* [Print Resolution] */
$fn = 60;

// ==============================================================================
// INTERNAL GEOMETRY CALCULATIONS
// ==============================================================================
y_min = -inward_len;
y_max = edge_margin;
total_len = y_max - y_min; // 17.0 mm

// Knuckle partition along Y (Left outer, Right center, Left outer)
k1_len = 5.2; // Bottom knuckle (Left leaf)
k2_len = 5.4; // Center knuckle (Right leaf)
k3_len = total_len - k1_len - k2_len - 2 * clearance; // Top knuckle (Left leaf) = 5.8 mm

k1_y0 = y_min;
k1_y1 = k1_y0 + k1_len;

k2_y0 = k1_y1 + clearance;
k2_y1 = k2_y0 + k2_len;

k3_y0 = k2_y1 + clearance;
k3_y1 = y_max;

// Center of hinge pin: cylinder bottom is tangent to the backplate mounting face at Z = 0
hinge_z = knuckle_d / 2; // 2.4 mm

// Lateral reach of knuckle ramp in X: strictly constrained to knuckle radius so screw zone is 100% flat
knuckle_tangent_x = knuckle_d / 2; // 2.4 mm

// ==============================================================================
// MODULES
// ==============================================================================

// Base flat plate for one leaf
module leaf_plate_base(side = 1) { // side: -1 for left, +1 for right
    linear_extrude(height = thickness) {
        hull() {
            if (side > 0) {
                // Right leaf (X: +seam_gap to +bracket_w/2)
                translate([seam_gap, y_min]) square([0.1, total_len]);
                translate([bracket_w/2 - fillet_r, y_min + fillet_r]) circle(r = fillet_r);
                translate([bracket_w/2 - fillet_r, y_max - fillet_r]) circle(r = fillet_r);
            } else {
                // Left leaf (X: -bracket_w/2 to -seam_gap)
                translate([-seam_gap - 0.1, y_min]) square([0.1, total_len]);
                translate([-bracket_w/2 + fillet_r, y_min + fillet_r]) circle(r = fillet_r);
                translate([-bracket_w/2 + fillet_r, y_max - fillet_r]) circle(r = fillet_r);
            }
        }
    }
}

// Cylindrical knuckle barrel segment
module knuckle_barrel(y_start, y_end) {
    translate([0, y_start, hinge_z])
        rotate([-90, 0, 0])
            cylinder(h = y_end - y_start, d = knuckle_d);
}

// Tangent transition ramp that connects knuckle to plate WITHOUT encroaching on screw hole
module knuckle_ramp_left(y_start, y_end) {
    hull() {
        knuckle_barrel(y_start, y_end);
        translate([-knuckle_tangent_x, y_start, 0])
            cube([knuckle_tangent_x, y_end - y_start, thickness]);
    }
}

module knuckle_ramp_right(y_start, y_end) {
    hull() {
        knuckle_barrel(y_start, y_end);
        translate([0, y_start, 0])
            cube([knuckle_tangent_x, y_end - y_start, thickness]);
    }
}

// M3 Countersunk mounting hole (DIN 7991 90-degree flush head)
module m3_screw_hole(countersunk = true) {
    cylinder(h = thickness + 0.4, d = 3.4); // 3.4mm clearance for M3
    if (countersunk) {
        translate([0, 0, thickness - 1.7])
            cylinder(h = 1.9, r1 = 1.7, r2 = 3.1);
    }
}

// Left Leaf Component (attaches to left panel at X = -6.0 mm)
module left_leaf(countersunk = countersunk) {
    difference() {
        union() {
            // Flat base plate (3.0 mm thick)
            leaf_plate_base(side = -1);
            
            // Knuckle 1 (bottom segment)
            knuckle_ramp_left(k1_y0, k1_y1);
            
            // Knuckle 3 (top segment)
            knuckle_ramp_left(k3_y0, k3_y1);
        }
        
        // Hinge pin bore
        translate([0, y_min - 1, hinge_z])
            rotate([-90, 0, 0])
                cylinder(h = total_len + 2, d = pin_d);
                
        // M3 Mounting screw hole at X = -hole_pitch/2, Y = 0 (completely unobstructed)
        translate([-hole_pitch/2, 0, -0.2])
            m3_screw_hole(countersunk = countersunk);
    }
}

// Right Leaf Component (attaches to right panel at X = +6.0 mm)
module right_leaf(countersunk = countersunk) {
    difference() {
        union() {
            // Flat base plate (3.0 mm thick)
            leaf_plate_base(side = 1);
            
            // Knuckle 2 (center segment)
            knuckle_ramp_right(k2_y0, k2_y1);
        }
        
        // Hinge pin bore
        translate([0, y_min - 1, hinge_z])
            rotate([-90, 0, 0])
                cylinder(h = total_len + 2, d = pin_d);
                
        // M3 Mounting screw hole at X = +hole_pitch/2, Y = 0 (completely unobstructed)
        translate([hole_pitch/2, 0, -0.2])
            m3_screw_hole(countersunk = countersunk);
    }
}

// Dedicated 3D-Printable Snap Pin (Palletje met borgweerhaakjes)
module snap_pin() {
    difference() {
        union() {
            // Retaining head flange (stops pin from sliding through)
            cylinder(h = pin_head_h, d = pin_head_d);
            
            // Main pivot shaft spanning through the knuckle barrel
            translate([0, 0, pin_head_h])
                cylinder(h = total_len, d = pin_shaft_d);
                
            // Snap barb locking head (past the knuckle exit)
            translate([0, 0, pin_head_h + total_len]) {
                // Expanding ramp (compresses easily during insertion)
                cylinder(h = pin_barb_len, d1 = pin_shaft_d, d2 = pin_barb_d);
                // Retaining shoulder step + lead-in tip
                translate([0, 0, pin_barb_len])
                    cylinder(h = 0.8, d1 = pin_barb_d, d2 = pin_shaft_d - 0.6);
            }
        }
        
        // Compression slit through the barb tip
        translate([-pin_slot_w/2, -pin_head_d, pin_head_h + total_len + pin_barb_len + 0.8 - pin_slot_len])
            cube([pin_slot_w, pin_head_d * 2, pin_slot_len + 1]);
    }
}

// Snap Pin laying horizontal for maximum strength along layer lines
module snap_pin_flat() {
    // Laying horizontal on bed with small flat contact face
    translate([0, 0, pin_head_d/2])
        rotate([0, 90, 0])
            snap_pin();
}

// Full Assembled Bracket (with rotation & snap pin inserted)
module rear_joining_bracket_hinged(angle = fold_angle, countersunk = countersunk, pin = show_pin) {
    // Fixed Left Leaf
    color("#0284c7")
        left_leaf(countersunk = countersunk);
        
    // Rotating Right Leaf
    translate([0, 0, hinge_z])
        rotate([0, angle, 0])
            translate([0, 0, -hinge_z])
                color("#38bdf8")
                    right_leaf(countersunk = countersunk);
                    
    // Inserted Snap Pin
    if (pin) {
        translate([0, y_min - pin_head_h, hinge_z])
            rotate([-90, 0, 0])
                color("#fbbf24") // Gold/Amber snap pin
                    snap_pin();
    }
}

// Complete 1-Click Print Set (Left Leaf + Right Leaf + Snap Pin flat on bed)
module rear_joining_bracket_hinged_set(spacing = 4.0, countersunk = countersunk) {
    // Left leaf
    translate([-spacing/2, 0, 0])
        left_leaf(countersunk = countersunk);
        
    // Right leaf
    translate([spacing/2, 0, 0])
        right_leaf(countersunk = countersunk);
        
    // Snap Pin (standing vertical with head on build plate, prints cleanly in 2 minutes)
    translate([0, y_max + 7.0, 0])
        color("#fbbf24")
            snap_pin();
}

// ==============================================================================
// TOP-LEVEL RENDER SWITCH
// ==============================================================================
if (part == "set" || part == "pair" || part == 1) {
    // Complete set ready to print: Left + Right + Snap Pin
    color("#0284c7")
        rear_joining_bracket_hinged_set(spacing = 3.5, countersunk = countersunk);
} else if (part == "assembled" || part == 2) {
    // Assembled preview with fold angle and snap pin inserted
    rear_joining_bracket_hinged(angle = fold_angle, countersunk = countersunk, pin = show_pin);
} else if (part == "left" || part == 3) {
    // Individual Left Leaf
    color("#0284c7")
        left_leaf(countersunk = countersunk);
} else if (part == "right" || part == 4) {
    // Individual Right Leaf
    color("#38bdf8")
        right_leaf(countersunk = countersunk);
} else if (part == "pin" || part == 5) {
    // Snap Pin only (vertical)
    color("#fbbf24")
        snap_pin();
} else if (part == "pin_flat" || part == 6) {
    // Snap Pin only (horizontal)
    color("#fbbf24")
        snap_pin_flat();
}
