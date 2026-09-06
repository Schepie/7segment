// ==============================================================================
// Rear Corner Leveling Foot (Hoekstuk voor Eerste en Laatste Paneel)
// For Modular 7-Segment Display / Clock / Scoreboard
// ==============================================================================
//
// Purpose:
// When multiple modular panels are joined together, the rear joining brackets
// (both rigid and hinged versions) are 3.0 mm thick and sit on the rear seams.
// When the assembled display is laid flat on a table, the middle seams rest on the
// brackets, but the outer corners of the first and last panel would float in the air.
//
// This corner foot mounts to the outer corner M3 screw hole of the first and last
// panels. It has the exact same 3.0 mm thickness so the entire display rests
// 100% level, flat, and wobble-free on any table or surface!
//
// Universal 4-Corner Symmetry:
// - Outer edges are inset by 1.0 mm (edge_margin = 5.0 mm from screw center,
//   matching the 6.0 mm housing edge of the panel).
// - Inward extension is 12.0 mm along both X and Y, matching the 17.0 mm depth
//   of the rear joining brackets.
// - Symmetrical across the corner diagonal: a single 3D-printed part fits ANY of
//   the 4 outer corners (Top-Left, Bottom-Left, Top-Right, Bottom-Right) simply
//   by rotating it in 90-degree steps!
// - Countersunk M3 screw hole allows the screw head to sit completely flush.
// ==============================================================================

/* [Configuration] */
// What to generate
part = 1; // [1:"single - 1 Corner foot", 2:"pair - 2 Corner feet on bed", 3:"set4 - Set of 4 Corner feet on bed (for all 4 corners)"]

// Foot style
style = "solid"; // ["solid": Flat bottom for maximum surface contact, "bumper_recess": Bottom recess for 8mm rubber bumpon / silicone pad]

/* [Mechanical Dimensions] */
thickness   = 3.0;  // Matches rigid and hinged rear joining brackets (3.0 mm)
edge_margin = 5.0;  // Distance from screw center to outer edge (stays 1.0mm inside 6.0mm housing rim)
inward_len  = 12.0; // Distance from screw center inward towards display center
fillet_r    = 2.5;  // Outer corner radius (matches rear joining bracket)

// M3 Countersunk screw hole (DIN 7991)
screw_d     = 3.4;  // Clearance diameter for M3
cs_d        = 6.5;  // Countersink outer diameter (M3 DIN 7991 head is 6.0mm)
cs_depth    = 1.8;  // Countersink cone depth

// Optional anti-slip bumper recess on bottom face
bumper_d    = 8.5;  // Diameter for standard 8mm rubber foot
bumper_depth= 0.8;  // Recess depth into bottom face

/* [Resolution] */
$fn = 48;

// ==============================================================================
// GEOMETRY
// ==============================================================================
// Screw center is at (0, 0)
// Outer corner is towards (-edge_margin, -edge_margin)
// Inward edges extend to (+inward_len, +inward_len)
// Total size = (edge_margin + inward_len) x (edge_margin + inward_len) = 17.0 x 17.0 mm

total_size = edge_margin + inward_len; // 17.0 mm
x_min = -edge_margin;
x_max = inward_len;
y_min = -edge_margin;
y_max = inward_len;

module rear_corner_foot(style = style) {
    difference() {
        // Base plate body with rounded corners
        linear_extrude(height = thickness) {
            hull() {
                translate([x_min + fillet_r, y_min + fillet_r]) circle(r = fillet_r);
                translate([x_max - fillet_r, y_min + fillet_r]) circle(r = fillet_r);
                translate([x_max - fillet_r, y_max - fillet_r]) circle(r = fillet_r);
                translate([x_min + fillet_r, y_max - fillet_r]) circle(r = fillet_r);
            }
        }
        
        // M3 Countersunk Screw Hole (countersink on top face Z = thickness)
        translate([0, 0, -0.2]) {
            cylinder(h = thickness + 0.4, d = screw_d);
            translate([0, 0, thickness - cs_depth + 0.2])
                cylinder(h = cs_depth + 0.1, d1 = screw_d, d2 = cs_d);
        }
        
        // Optional rubber bumper recess on bottom face (Z = 0)
        if (style == "bumper_recess") {
            // Offset slightly toward center of foot pad
            translate([(x_min + x_max)/2 + 1.0, (y_min + y_max)/2 + 1.0, -0.1])
                cylinder(h = bumper_depth + 0.1, d = bumper_d);
        }
        
        // Subtle decorative corner indicator notch on the outer corner
        // to visually show which corner aligns with the outside corner of the display
        translate([x_min, y_min, thickness - 0.4])
            rotate([0, 0, 45])
                cube([2.0, 0.6, 1.0], center = true);
    }
}

// Multi-part Bed Layouts
module rear_corner_foot_pair(spacing = 4.0) {
    translate([-total_size/2 - spacing/2, 0, 0])
        rear_corner_foot();
    translate([total_size/2 + spacing/2, 0, 0])
        rear_corner_foot();
}

module rear_corner_foot_set4(spacing = 4.0) {
    for (ix = [-1, 1]) {
        for (iy = [-1, 1]) {
            translate([ix * (total_size/2 + spacing/2), iy * (total_size/2 + spacing/2), 0])
                rear_corner_foot();
        }
    }
}

// Assembled Demonstration Preview on Panel Outer Corner
module corner_foot_assembly_preview() {
    corner_span = 40.0;
    
    // Panel Housing Outer Corner (charcoal)
    color("#1e293b", 0.6) {
        difference() {
            translate([-corner_span, -corner_span, -13.0])
                cube([corner_span, corner_span, 13.0]);
            translate([-corner_span - 0.1, -corner_span - 0.1, -13.0 + 2.0])
                cube([corner_span - 2.0 + 0.1, corner_span - 2.0 + 0.1, 12.0]);
        }
    }
    
    // Corner screw post inside housing
    color("#334155")
        translate([-6.0, -6.0, -11.0])
            difference() {
                cylinder(h = 11.0, r = 4.0);
                cylinder(h = 11.1, r = 2.1); // M3 heat-set insert hole
            }
            
    // Backplate corner section (semi-transparent slate)
    color("#475569", 0.7)
        translate([-corner_span + 2.2, -corner_span + 2.2, -2.0])
            difference() {
                cube([corner_span - 2.2, corner_span - 2.2, 2.0]);
                translate([-6.0 - (-corner_span + 2.2), -6.0 - (-corner_span + 2.2), -0.1])
                    cylinder(h = 2.2, d = 3.4);
            }
            
    // Mounted Rear Corner Leveling Foot (at screw center X = -6.0, Y = -6.0)
    translate([-6.0, -6.0, 0])
        rotate([0, 0, 180])
            color("#0284c7")
                rear_corner_foot(style = style);
                
    // Flush M3 Countersunk Screw (gold)
    color("#f59e0b")
        translate([-6.0, -6.0, thickness])
            rotate([180, 0, 0])
                union() {
                    cylinder(h = 1.8, d1 = 6.0, d2 = 3.0);
                    translate([0, 0, 1.8])
                        cylinder(h = 10.0, d = 3.0);
                }
}

// Top-Level Selector
if (part == 1 || part == "single") {
    color("#0284c7")
        rear_corner_foot(style = style);
} else if (part == 2 || part == "pair") {
    color("#0284c7")
        rear_corner_foot_pair(spacing = 4.0);
} else if (part == 3 || part == "set4" || part == "set") {
    color("#0284c7")
        rear_corner_foot_set4(spacing = 4.0);
} else if (part == 4 || part == "assembly" || part == "preview") {
    corner_foot_assembly_preview();
}

