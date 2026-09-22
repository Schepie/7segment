// ==============================================================================
// VESA 50x50 Wireless Power Transfer (WPT) Add-on Plate (70 x 110 mm)
// For Modular 7-Segment Padel Scoreboard & Digital Clock
// Designed for Bambu Lab / Prusa / FDM 3D Printing (100% Support-Free)
// ==============================================================================
//
// Purpose:
// Mounts directly to the 50x50 mm VESA mounting pattern on the backplate of
// any 7-segment panel (e.g. Panel 3) using 4x M3 DIN 7991 countersunk screws.
// Provides a full 70 x 110 mm flat surface so MagSafe / Qi magnetic battery
// packs (e.g. Apple, Anker 622, Baseus) rest completely flush without tilting!
//
// Accommodates:
// - Outer Ferromagnetic Ring: Ø57 mm OD, Ø46 mm ID, 1.0 mm thickness
// - Rectangular Alignment Magnet (Tail Magnet): 6-7 mm wide, 10-14 mm long, 1.0 mm thick
// - Rectangular Induction Coil: 33 mm x 42 mm, ~1.2 - 1.5 mm thickness
// - Ultra-thin 0.8 mm solid rear contact skin (4 layers @ 0.20mm) for maximum
//   inductive coupling efficiency (< 1 mm air gap).
// - 4x M3 countersunk mounting holes (VESA 50x50 mm pitch).
// - Wire egress routing: central pass-through hole OR full-length bottom channel.
// - 100% Support-Free FDM 3D Printing (prints rear-face flat on build plate).
// ==============================================================================

/* [Part Selection] */
part = 1; // [1:"vesa_wpt_plate - Main 70x110 VESA Wireless Power Plate", 2:"vesa_wpt_cover - Front Clamping Retainer Lid", 3:"assembled_preview - 3D Assembled Preview with Hardware", 4:"cutaway_view - Cutaway Cross-Section Preview", 5:"vesa_wpt_inlay - Printable Accent Inlay (for Multi-Color / AMS / MMU)", 6:"multicolor_preview - Dual-Color Finished Exterior Preview"]

/* [Multi-Color Inlay Options] */
inlay_style       = 1;    // [0:"Debossed Engraving (single filament)", 1:"Flush Multi-Color Inlay (Bambu AMS / Dual-Color)"]
inlay_depth       = 0.40; // Depth of multi-color inlay (0.40 mm = 2 layers @ 0.20mm for full opacity)
inlay_ring_w      = 2.0;  // Width of the accent alignment ring line (mm)
inlay_color       = "#38bdf8"; // Visual preview color for accent graphics (Sky Blue / White / Lime)
body_color        = "#1e293b"; // Visual preview color for main plate body (Dark Slate / Charcoal)

/* [Plate Physical Sizing] */
plate_w           = 70.0; // Width of the rectangular plate (mm)
plate_h           = 110.0;// Height of the rectangular plate (mm)
plate_corner_r    = 6.0;  // Corner radius of the plate (mm)
plate_total_h     = 5.2;  // Total height / thickness of the plate (mm)
edge_chamfer      = 1.0;  // 45° chamfer on outer perimeter edges

/* [Vertical Positioning] */
// Ring & VESA 50x50 center is placed at (0, 0).
// Plate top edge is at Y = +38mm (giving 9.4mm margin above the Ø57mm ring).
// Plate bottom edge is at Y = -72mm (giving 30mm of solid flat surface below the tail magnet).
plate_y_top       = 38.0; 
plate_y_bot       = plate_y_top - plate_h; // -72.0 mm

/* [WPT Ring Dimensions] */
ring_od           = 57.2; // Ferromagnetic ring outer diameter (nominal 57.0mm + 0.2mm clearance)
ring_id           = 45.8; // Ferromagnetic ring inner diameter (nominal 46.0mm - 0.2mm clearance)
ring_depth        = 1.1;  // Stepped shelf depth for 1.0mm metal ring

/* [Rectangular Alignment Magnet (Tail Magnet)] */
enable_tail_magnet = true; // Foresee space for rectangular alignment magnet below ring
tail_w            = 8.0;  // Width of alignment magnet pocket (fits 5.5 - 7.0mm magnets)
tail_l            = 15.0; // Length of alignment magnet pocket (fits 8 - 14mm magnets)
tail_y_start      = -27.5;// Top of tail pocket (overlaps ring shelf)
tail_depth        = 1.1;  // Depth for 1.0mm magnet
tail_corner_r     = 1.5;  // Corner fillet radius

/* [Rectangular Induction Coil Dimensions] */
coil_w            = 34.0; // Coil pocket width (nominal 33.0mm + 1.0mm tolerance)
coil_l            = 43.0; // Coil pocket length (nominal 42.0mm + 1.0mm tolerance)
coil_corner_r     = 5.0;  // Corner radius for rectangular coil pocket
coil_depth        = 1.5;  // Depth for coil + ferrite shield
skin_thick        = 0.8;  // Solid rear contact skin thickness (mm)

/* [VESA 50x50 Mount Parameters] */
vesa_pitch        = 50.0; // Center-to-center hole spacing (50.0 mm)
m3_hole_d         = 3.4;  // Clearance diameter for M3 screws
m3_cs_d           = 6.5;  // Countersink cone diameter for M3 DIN 7991 (flush rear heads)
m3_cs_depth       = 1.8;  // Countersink cone depth (mm)

/* [Wire Routing] */
enable_center_hole = false;// Completely closed: 0.8mm skin is 100% solid, sealed, and seamless
enable_wire_channel= false;// Keep outer perimeter 100% solid and sealed (wires do NOT exit the box)
wire_slot_w        = 4.5;  // Internal wire slot width
wire_slot_d        = 2.8;  // Internal wire slot depth

/* [Bottom Label Text] */
enable_bottom_text = true; // Add text to the bottom flat area
label_text         = "WIRELESS POWER"; // Text to display
label_font_size    = 4.5;  // Font size (mm)
label_pos_y        = -57.0;// Y position on the bottom flat section

/* [Visual Alignment Guide] */
show_target_guide  = true; // 0.2mm subtle debossed MagSafe-style guide on exterior rear face

/* [Resolution] */
$fn = 60;

// ==============================================================================
// 2D Profile Helpers
// ==============================================================================
module rounded_rect_2d(w, y_bot, y_top, r) {
    hull() {
        for (x = [-w/2 + r, w/2 - r]) {
            for (y = [y_bot + r, y_top - r]) {
                translate([x, y]) circle(r = r, $fn = 40);
            }
        }
    }
}

module bottom_label_2d() {
    translate([0, label_pos_y])
        mirror([1, 0, 0])
            text(label_text, size = label_font_size, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
}

// ==============================================================================
// Main 70x110 VESA Wireless Power Plate
// ==============================================================================
module vesa_wpt_plate() {
    difference() {
        // --- 1. Outer Solid 70x110 mm Body with Chamfered Rear Edge ---
        hull() {
            // Base layer at Z = 0 (inset by edge_chamfer for 45° chamfer)
            translate([0, 0, 0])
                linear_extrude(height = 0.01)
                    rounded_rect_2d(plate_w - edge_chamfer * 2,
                                    plate_y_bot + edge_chamfer,
                                    plate_y_top - edge_chamfer,
                                    max(1.0, plate_corner_r - edge_chamfer));
            // Full-size body starting at Z = edge_chamfer up to Z = plate_total_h
            translate([0, 0, edge_chamfer])
                linear_extrude(height = plate_total_h - edge_chamfer)
                    rounded_rect_2d(plate_w, plate_y_bot, plate_y_top, plate_corner_r);
        }

        // --- 2. Main Circular WPT Pocket (Ø57.2 mm) ---
        // Clean, flat-bottomed cavity holding both the Ø57mm ring and the coil (100% smooth, zero internal ridges)
        translate([0, 0, skin_thick]) {
            cylinder(h = plate_total_h - skin_thick + 0.1, r = ring_od / 2, $fn = 120);
        }

        // --- 3. Rectangular Alignment Magnet Pocket (Tail Magnet) ---
        if (enable_tail_magnet) {
            translate([0, tail_y_start - tail_l / 2, skin_thick]) {
                linear_extrude(plate_total_h - skin_thick + 0.1) {
                    offset(r = tail_corner_r, $fn = 24)
                        square([tail_w - tail_corner_r * 2, tail_l - tail_corner_r * 2], center = true);
                }
            }
        }

        // --- 4. 4x VESA 50x50 M3 Countersunk Screw Holes ---
        for (x = [-vesa_pitch/2, vesa_pitch/2]) {
            for (y = [-vesa_pitch/2, vesa_pitch/2]) {
                translate([x, y, -0.1]) {
                    // M3 clearance pass-through hole (3.4mm)
                    cylinder(h = plate_total_h + 0.2, r = m3_hole_d / 2, $fn = 24);
                    // Flush DIN 7991 countersink cone on the rear contact face (Z = 0)
                    cylinder(h = m3_cs_depth, r1 = m3_cs_d / 2, r2 = m3_hole_d / 2, $fn = 24);
                }
            }
        }

        // --- 7. Exterior Target Alignment Guide / Multi-Color Inlay Cavity ---
        if (show_target_guide) {
            if (inlay_style == 1) {
                // Multi-Color Flush Inlay Pocket (Z = -0.01 to inlay_depth)
                translate([0, 0, -0.01])
                    linear_extrude(height = inlay_depth + 0.01) {
                        difference() {
                            circle(r = (ring_od + ring_id) / 4 + inlay_ring_w / 2, $fn = 80);
                            circle(r = (ring_od + ring_id) / 4 - inlay_ring_w / 2, $fn = 80);
                        }
                        if (enable_tail_magnet) {
                            translate([0, tail_y_start - tail_l / 2]) {
                                offset(r = 0.8, $fn = 20)
                                    square([5.5 - 1.6, 10.0 - 1.6], center = true);
                            }
                        }
                        // Bottom Accent Text
                        if (enable_bottom_text) {
                            bottom_label_2d();
                        }
                    }
            } else {
                // Classic 0.2mm Debossed Engraving
                translate([0, 0, -0.05]) {
                    difference() {
                        cylinder(h = 0.25, r = (ring_od + ring_id) / 4 + 0.4, $fn = 80);
                        translate([0, 0, -0.05])
                            cylinder(h = 0.35, r = (ring_od + ring_id) / 4 - 0.4, $fn = 80);
                    }
                    if (enable_tail_magnet) {
                        translate([0, tail_y_start - tail_l / 2, 0]) {
                            difference() {
                                linear_extrude(0.25)
                                    offset(r = 0.8, $fn = 16)
                                        square([5.5 - 1.6, 10.0 - 1.6], center = true);
                                translate([0, 0, -0.05])
                                    linear_extrude(0.35)
                                        offset(r = 0.4, $fn = 16)
                                            square([5.5 - 2.4, 10.0 - 2.4], center = true);
                            }
                        }
                    }
                    if (enable_bottom_text) {
                        linear_extrude(0.25)
                            bottom_label_2d();
                    }
                }
            }
        }
    }
}

// ==============================================================================
// Multi-Color Accent Inlay Module (Part 5)
// Sits on build plate at Z = 0 to Z = inlay_depth (0.40mm = 2 layers @ 0.20mm)
// ==============================================================================
module vesa_wpt_inlay() {
    linear_extrude(height = inlay_depth) {
        // Concentric Accent Ring
        difference() {
            circle(r = (ring_od + ring_id) / 4 + inlay_ring_w / 2, $fn = 80);
            circle(r = (ring_od + ring_id) / 4 - inlay_ring_w / 2, $fn = 80);
        }
        // Rectangular Alignment Tail Bar
        if (enable_tail_magnet) {
            translate([0, tail_y_start - tail_l / 2]) {
                offset(r = 0.8, $fn = 20)
                    square([5.5 - 1.6, 10.0 - 1.6], center = true);
            }
        }
        // Bottom Accent Text
        if (enable_bottom_text) {
            bottom_label_2d();
        }
    }
}

// ==============================================================================
// Front Clamping Retainer Lid (Optional)
// Clamps down over the coil before bolting against the scoreboard
// ==============================================================================
module vesa_wpt_cover() {
    cover_t = 1.2;
    difference() {
        union() {
            // Main disc covering the circular pocket
            cylinder(h = cover_t, r = ring_od / 2 - 0.2, $fn = 90);
            // Tail tab
            if (enable_tail_magnet) {
                translate([0, tail_y_start - tail_l / 2, 0]) {
                    linear_extrude(cover_t) {
                        offset(r = tail_corner_r - 0.2, $fn = 20)
                            square([tail_w - 0.4 - (tail_corner_r - 0.2) * 2,
                                    tail_l - 0.4 - (tail_corner_r - 0.2) * 2], center = true);
                    }
                }
            }
        }
        // Center finger pry hole
        cylinder(h = cover_t + 0.2, r = 5.0, center = true, $fn = 24);
    }
}

// ==============================================================================
// Hardware 3D Visual Models
// ==============================================================================
module hardware_models_preview() {
    // Outer Ferromagnetic Ring (Silver)
    color("Silver")
        translate([0, 0, skin_thick])
            difference() {
                cylinder(h = 1.0, r = 57.0 / 2, $fn = 80);
                translate([0, 0, -0.05])
                    cylinder(h = 1.1, r = 46.0 / 2, $fn = 70);
            }

    // Rectangular Alignment Tail Magnet (Silver)
    if (enable_tail_magnet) {
        color("Silver")
            translate([0, tail_y_start - tail_l / 2, skin_thick])
                linear_extrude(1.0)
                    offset(r = 1.0, $fn = 16)
                        square([6.0 - 2.0, 11.0 - 2.0], center = true);
    }

    // Rectangular Copper Induction Coil (DarkGoldenrod)
    color("DarkGoldenrod")
        translate([0, 0, skin_thick + 0.05])
            linear_extrude(1.2)
                offset(r = 4.0, $fn = 32)
                    square([33.0 - 8.0, 42.0 - 8.0], center = true);

    // Dark Ferrite Shielding Sheet
    color("#222222")
        translate([0, 0, skin_thick + 1.25])
            linear_extrude(0.3)
                offset(r = 4.0, $fn = 32)
                    square([33.0 - 8.0, 42.0 - 8.0], center = true);

    // 4x M3 Flush Countersunk Screws (Black Steel)
    for (x = [-vesa_pitch/2, vesa_pitch/2]) {
        for (y = [-vesa_pitch/2, vesa_pitch/2]) {
            color("#111827")
                translate([x, y, 0]) {
                    // Countersink head
                    cylinder(h = m3_cs_depth, r1 = m3_cs_d / 2, r2 = m3_hole_d / 2, $fn = 24);
                    // Screw shaft extending into panel
                    translate([0, 0, -6.0])
                        cylinder(h = 16.0, r = 1.5, $fn = 20);
                }
        }
    }

    // Power Bank Ghost Silhouette (Translucent Cyan)
    // Demonstrates how a 66 x 105 mm MagSafe battery pack sits flush on the flat surface
    %color([0.2, 0.7, 0.9, 0.25])
        translate([0, plate_y_top - 105.0 / 2 - 2.0, -12.0])
            linear_extrude(12.0)
                offset(r = 8.0, $fn = 32)
                    square([66.0 - 16.0, 105.0 - 16.0], center = true);
}

// ==============================================================================
// Main Render Controller
// ==============================================================================
if (part == 1) {
    // Printable 70x110 Plate (flat on build plate at Z = 0)
    vesa_wpt_plate();
} else if (part == 2) {
    // Printable Retainer Lid (flat on build plate at Z = 0)
    vesa_wpt_cover();
} else if (part == 3) {
    // 3D Assembled Preview with Translucent Plate & Hardware
    color("#334155", 0.75) vesa_wpt_plate();
    hardware_models_preview();
} else if (part == 4) {
    // Cutaway Cross-Section (X = 0 plane)
    difference() {
        union() {
            color("#334155", 0.9) vesa_wpt_plate();
            hardware_models_preview();
        }
        translate([0, plate_y_bot - 10, -5])
            cube([plate_w + 10, plate_h + 20, plate_total_h + 20]);
    }
} else if (part == 5) {
    // Printable Accent Inlay (for Multi-Color / AMS / MMU printing)
    vesa_wpt_inlay();
} else if (part == 6) {
    // Dual-Color Finished Exterior Preview (as printed on smooth PEI)
    color(body_color) vesa_wpt_plate();
    color(inlay_color) vesa_wpt_inlay();
}

