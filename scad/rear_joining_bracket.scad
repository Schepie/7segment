// Rear Joining Bracket for Modular 7-Segment Display
// Option 1: Flush Rear Bridge Splice
//
// Mounts across the rear seam between two adjacent panels (Panel-to-Panel or Panel-to-Colon).
// Centers on the two corner M3 screws across the seam (pitch = 12.0 mm).
// Designed with an asymmetric profile (edge_margin = 5.0 mm) so it stays 1.0 mm INSIDE
// the housing perimeter and NEVER sticks out above or below the clock!

$fn = 32;

// --- Parameters ---
thickness = 3.0;        // Bracket thickness (mm)
bracket_w = 28.0;       // Total width across seam (14mm on each panel)
edge_margin = 5.0;      // Distance from screw center to outer rim (housing edge is at 6.0mm -> 1.0mm inset!)
inward_len = 12.0;      // Extension inward towards display center for rigidity
hole_pitch = 12.0;      // Center-to-center distance between adjacent corner screws (6mm + 6mm)
fillet_r = 2.5;         // Corner radius (mm)
countersunk = true;     // Set to true for flush countersunk screws, false for flat holes

module rear_joining_bracket(thickness = thickness, countersunk = countersunk) {
    difference() {
        // Asymmetric rounded bracket body
        linear_extrude(height = thickness) {
            hull() {
                translate([-bracket_w/2 + fillet_r, -inward_len + fillet_r]) circle(r = fillet_r);
                translate([bracket_w/2 - fillet_r, -inward_len + fillet_r])  circle(r = fillet_r);
                translate([bracket_w/2 - fillet_r, edge_margin - fillet_r]) circle(r = fillet_r);
                translate([-bracket_w/2 + fillet_r, edge_margin - fillet_r]) circle(r = fillet_r);
            }
        }
        
        // 2x M3 Screw Holes (at Y = 0, spaced 12.0mm apart)
        for (x = [-hole_pitch/2, hole_pitch/2]) {
            translate([x, 0, -0.1]) {
                cylinder(h = thickness + 0.2, r = 1.7); // 3.4mm clearance for M3
                if (countersunk) {
                    // Standard 90-degree M3 countersink head
                    translate([0, 0, thickness - 1.8])
                        cylinder(h = 2.0, r1 = 1.7, r2 = 3.3);
                }
            }
        }
        
        // Subtle debossed alignment notch on the outside face to indicate seam centerline
        translate([0, (edge_margin - inward_len)/2, thickness - 0.4])
            cube([0.8, edge_margin + inward_len + 1, 0.5], center = true);
    }
}

// Render bracket for 3D printing
color("#0284c7") // Sky blue accent
    rear_joining_bracket();
