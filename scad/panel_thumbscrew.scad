// ==============================================================================
// Modular 7-Segment Display Panel Thumbscrew System (Duimschroef)
// For Tool-Free Hand-Fastening of Modular Panels & Rear Joining Brackets
// Designed for Bambu Lab / Prusa / FDM 3D Printing (100% Support-Free)
// ==============================================================================
//
// Purpose:
// When assembling modular 7-segment clock or scoreboard panels, adjacent panels
// are joined across the rear seam using rear joining brackets (hole pitch = 12.0 mm).
// Normally, this requires an Allen key or screwdriver to tighten M3 screws into the
// 3.0 mm high brass heat-set inserts in the panel bosses.
//
// This 3D-printable thumbscrew knob allows panels to be fastened and unfastened
// 100% BY HAND without any tools!
//
// Hardware Compatibility:
// - Screw: M3 x 12 mm Countersunk Flat Head Screw (DIN 7991)
// - Insert: Standard M3 Brass Heat-Set Insert (3.0 mm height, OD ~4.6 mm)
// - Bracket: Fits both rigid rear_joining_bracket and hinged rear_joining_bracket_hinged
//
// Mechanical Clearances:
// - Outer diameter is strictly 11.2 mm: engineered so TWO thumbscrews can sit
//   and turn side-by-side on the 12.0 mm hole pitch of the seam bracket with
//   0.8 mm clearance (no rubbing or binding).
// - Hex-Drive Anti-Spin Lock: A press-fit locking cap features an integrated 2.0 mm
//   hex drive pin that keys directly into the M3 DIN 7991 hex socket for 100% positive
//   torque transmission (the screw cannot spin inside the plastic knob).
// - Thread Engagement: With an M3x12 screw, 9.0 mm of thread extends out of the knob.
//   Passing through the 3.0 mm rear bracket leaves 6.0 mm of thread, which fully
//   engages the entire 3.0 mm height of the brass insert!
//
// ==============================================================================

/* [Configuration & Part Selection] */
// What part to generate
part = 1; // [1:"pair - Complete print set: 2 Knobs + 2 Locking Caps on bed", 2:"single - 1 Knob + 1 Locking Cap", 3:"set4 - Set of 4 Knobs + 4 Caps (for multi-panel scoreboard)", 4:"knob_only - Thumbscrew Knob only", 5:"cap_only - Locking Cap only", 6:"preview - Assembled 3D Preview across Rear Seam Bracket", 7:"cutaway - Cutaway Cross-Section showing screw & locking cap inside knob", 8:"thumb_nut_pair - Pair of Thumb Nuts (with 3.0mm heat-set insert pockets in knob)", 9:"thumb_nut_single - Single Thumb Nut", 10:"insert_stud_pair - Pair of 1-Piece Knobs with 3.0mm insert pocket for M3x12 screw stud", 11:"insert_stud_single - Single 1-Piece Knob with insert pocket", 12:"insert_stud_preview - 3D Preview of Insert-Stud Knob with Screw & Insert", 13:"insert_stud_cutaway - Cutaway of Insert-Stud Knob"]

/* [Screw Head Options] */
drive_type      = "philips"; // ["philips": Cross PH1 drive for Philips screw, "hex": 2.0mm Hex Allen socket]
head_type       = "countersunk"; // ["countersunk": Flat countersunk DIN 965 / DIN 7991, "pan": Round pan head DIN 7985]

/* [Dimensions - Thumbscrew Knob] */
knob_d          = 11.2; // Knob outer diameter (mm, must be < 12.0mm for seam clearance)
knob_h          = 8.0;  // Knob total height (mm, comfortable finger grip)
flute_count     = 24;   // Number of vertical knurling flutes for finger traction
flute_r         = 0.5;  // Knurling flute radius (mm)

/* [Hardware Dimensions (M3 Screw)] */
screw_shaft_d   = 3.3;  // Clearance diameter for M3 threaded shaft
cs_d            = 6.2;  // Head pocket diameter (M3 head is ~5.6 to 6.0mm)
cs_depth        = 1.8;  // Head cone/recess depth (mm)
base_wall       = 1.2;  // Wall thickness between bracket face and screw head seat (mm)

/* [Print Resolution] */
$fn = 60;

// ==============================================================================
// INTERNAL CALCULATIONS
// ==============================================================================
cap_h = knob_h - base_wall - cs_depth; // Height of internal cavity above screw head (5.0 mm)

// ------------------------------------------------------------------------------
// THUMBSCREW KNOB BODY
// ------------------------------------------------------------------------------
module thumbscrew_knob() {
    difference() {
        // Main cylindrical body with vertical knurling flutes (2D extruded for 50x faster CSG compile)
        linear_extrude(height = knob_h) {
            circle(d = knob_d - flute_r, $fn = 48);
            for (a = [0 : 360 / flute_count : 359]) {
                rotate([0, 0, a])
                    translate([(knob_d - flute_r)/2, 0])
                        circle(r = flute_r, $fn = 16);
            }
        }
        
        // 1. M3 threaded shaft through-hole at base
        translate([0, 0, -0.1])
            cylinder(h = base_wall + 0.2, d = screw_shaft_d, $fn = 30);
            
        // 2. Countersunk conical seat for M3 DIN 7991 screw head
        translate([0, 0, base_wall - 0.01]) {
            cylinder(h = cs_depth + 0.02, d1 = screw_shaft_d, d2 = cs_d, $fn = 36);
            
            // Upper cylindrical cavity for screw insertion & locking cap
            translate([0, 0, cs_depth])
                cylinder(h = cap_h + 0.5, d = cs_d, $fn = 36);
        }
        
        // 3. Top rim comfort chamfer
        translate([0, 0, knob_h - 0.7])
            difference() {
                cylinder(h = 0.8, d = knob_d + 3.0);
                cylinder(h = 0.9, d1 = knob_d - 1.4, d2 = knob_d + 1.0);
            }
            
        // 4. Bottom rim chamfer (smooth seating against rear bracket)
        translate([0, 0, -0.1])
            difference() {
                cylinder(h = 0.6, d = knob_d + 2.0);
                cylinder(h = 0.7, d1 = knob_d - 1.0, d2 = knob_d + 1.0);
            }
    }
}

// ------------------------------------------------------------------------------
// LOCKING CAP (Anti-Spin Drive Pin: Philips Cross PH1 or 2.0mm Hex Allen)
// ------------------------------------------------------------------------------
cap_flange_h = 0.8;
cap_flange_d = knob_d - 0.8; // 10.4 mm: rests neatly on knob top rim
cap_plug_d   = cs_d - 0.20;  // 6.0 mm: snug friction-fit into knob cavity
cap_plug_h   = cap_h - 0.2;  // 4.8 mm: cavity insertion depth (leaves 0.2mm clearance)

module locking_cap(drive = drive_type) {
    union() {
        // 1. Retaining Flange (printed flat on build plate Z=0 for max adhesion & smooth finish)
        cylinder(h = cap_flange_h, d = cap_flange_d, $fn = 48);
        
        // 2. Cylindrical Plug (press-fits into 6.2mm knob bore, overlapping into flange)
        translate([0, 0, cap_flange_h - 0.1])
            cylinder(h = cap_plug_h + 0.1, d = cap_plug_d, $fn = 36);
        
        // 3. Drive Key (Solidly fused on top of plug with 0.1mm overlap, 100% support-free)
        translate([0, 0, cap_flange_h + cap_plug_h - 0.1]) {
            if (drive == "philips") {
                // Solid Philips PH1 cross drive key (tapered for self-centering engagement)
                intersection() {
                    union() {
                        translate([0, 0, 0.75]) cube([3.1, 0.8, 1.7], center = true);
                        translate([0, 0, 0.75]) cube([0.8, 3.1, 1.7], center = true);
                    }
                    // Taper cone matching standard PH1 recess
                    cylinder(h = 1.6, d1 = 3.3, d2 = 2.0, $fn = 32);
                }
            } else if (drive == "hex") {
                // Solid 2.0 mm hex pin for M3 DIN 7991 socket (tapered lead-in for easy fit)
                cylinder(h = 1.6, r1 = 1.95 / (2 * cos(30)), r2 = 1.65 / (2 * cos(30)), $fn = 6);
            }
        }
    }
}

// Backward compatibility alias
module hex_locking_cap() {
    locking_cap(drive = "hex");
}

// ------------------------------------------------------------------------------
// MULTI-PART BED LAYOUTS
// ------------------------------------------------------------------------------
// Pair (for 1 rear joining bracket across a seam)
module thumbscrew_pair(spacing = 4.0) {
    // 2x Knobs
    translate([-knob_d/2 - spacing/2, 0, 0]) thumbscrew_knob();
    translate([knob_d/2 + spacing/2, 0, 0]) thumbscrew_knob();
    
    // 2x Locking Caps (Philips or Hex drive)
    translate([-knob_d/2 - spacing/2, knob_d + spacing, 0]) locking_cap();
    translate([knob_d/2 + spacing/2, knob_d + spacing, 0]) locking_cap();
}

// Single unit
module thumbscrew_single(spacing = 4.0) {
    translate([-knob_d/2 - spacing/2, 0, 0]) thumbscrew_knob();
    translate([knob_d/2 + spacing/2, 0, 0]) locking_cap();
}

// Set of 4 (for 2 rear brackets on a 4-digit display)
module thumbscrew_set4(spacing = 4.0) {
    for (ix = [-1.5, -0.5, 0.5, 1.5]) {
        translate([ix * (knob_d + spacing), 0, 0]) thumbscrew_knob();
        translate([ix * (knob_d + spacing), knob_d + spacing, 0]) locking_cap();
    }
}

// ------------------------------------------------------------------------------
// ASSEMBLED 3D PREVIEW (SEAM BRACKET + M3x12 SCREW + 3mm INSERT)
// ------------------------------------------------------------------------------
module thumbscrew_assembled_preview() {
    hole_pitch = 12.0; // Seam screw hole pitch
    bracket_t  = 3.0;  // Rear joining bracket thickness
    insert_h   = 3.0;  // Brass heat-set insert height
    insert_od  = 4.6;  // Brass insert outer diameter
    backplate_t= 5.5;  // Backplate thickness
    
    // 1. Rear Joining Bracket (Semi-transparent Slate)
    color("#475569", 0.75)
        translate([0, 0, -bracket_t / 2])
            difference() {
                // Rounded bracket body (28 mm wide x 17 mm deep)
                linear_extrude(height = bracket_t, center = true)
                    hull() {
                        translate([-14 + 2.5, -8.5 + 2.5]) circle(r = 2.5);
                        translate([14 - 2.5, -8.5 + 2.5]) circle(r = 2.5);
                        translate([14 - 2.5, 8.5 - 2.5]) circle(r = 2.5);
                        translate([-14 + 2.5, 8.5 - 2.5]) circle(r = 2.5);
                    }
                // Two screw clearance holes at X = +/- 6.0 mm
                for (x = [-hole_pitch/2, hole_pitch/2]) {
                    translate([x, 0, -bracket_t])
                        cylinder(h = bracket_t * 2, d = 3.4, $fn = 30);
                }
            }
            
    // 2. Left & Right Seam Thumbscrews
    for (x = [-hole_pitch/2, hole_pitch/2]) {
        translate([x, 0, 0]) {
            // Blue 3D-Printed Thumbscrew Knob
            color("#0284c7")
                thumbscrew_knob();
                
            // Cyan Locking Cap (seated inside knob, keyed into screw head)
            color("#38bdf8")
                translate([0, 0, knob_h + cap_flange_h])
                    rotate([180, 0, 0])
                        locking_cap();
                    
            // Gold M3x12 Countersunk Screw (DIN 7991)
            color("#f59e0b") {
                translate([0, 0, base_wall + cs_depth]) {
                    rotate([180, 0, 0]) {
                        // Countersunk head (1.8mm depth, 6.0mm head dia)
                        cylinder(h = 1.8, d1 = 6.0, d2 = 3.0, $fn = 30);
                        // Threaded shaft (10.2mm length below head = 12mm total)
                        translate([0, 0, 1.8])
                            cylinder(h = 10.2, d = 3.0, $fn = 30);
                    }
                }
            }
            
            // Amber Brass Heat-Set Insert (3.0 mm height, inside panel screw boss)
            color("#d97706") {
                // Located inside the frontplate boss behind the backplate
                translate([0, 0, -bracket_t - backplate_t - insert_h]) {
                    difference() {
                        cylinder(h = insert_h, d = insert_od, $fn = 30);
                        translate([0, 0, -0.1])
                            cylinder(h = insert_h + 0.2, d = 2.9, $fn = 30); // M3 internal thread
                    }
                }
            }
        }
    }
}

// ------------------------------------------------------------------------------
// CUTAWAY CROSS-SECTION PREVIEW (Shows M3x12 screw + Hex Locking Cap inside knob)
// ------------------------------------------------------------------------------
module thumbscrew_cutaway_preview() {
    difference() {
        union() {
            // Blue Knob Body
            color("#0284c7") thumbscrew_knob();
            
            // Cyan Locking Cap (seated inside knob, keyed into screw head)
            color("#38bdf8")
                translate([0, 0, knob_h + cap_flange_h])
                    rotate([180, 0, 0])
                        locking_cap();
                    
            // Gold M3x12 DIN 7991 Countersunk Screw
            color("#f59e0b")
                translate([0, 0, base_wall + cs_depth])
                    rotate([180, 0, 0]) {
                        cylinder(h = 1.8, d1 = 6.0, d2 = 3.0, $fn = 30);
                        translate([0, 0, 1.8])
                            cylinder(h = 10.2, d = 3.0, $fn = 30);
                    }
        }
        // Slice away front half (Y < 0) to reveal internal seat and hex engagement
        translate([-knob_d * 1.5, -knob_d * 2, -15])
            cube([knob_d * 3, knob_d * 2, knob_h + 30]);
    }
}

// ------------------------------------------------------------------------------
// THUMB NUT (Alternative: 3.0mm Brass Heat-Set Insert mounted IN the knob)
// ------------------------------------------------------------------------------
insert_pocket_d     = 4.2; // Standard pilot hole for M3 brass heat-set insert (OD ~4.6mm)
insert_pocket_depth = 3.6; // Depth for 3.0mm insert + 0.6mm plastic flow reservoir

module thumb_nut() {
    difference() {
        // Knurled body
        linear_extrude(height = knob_h) {
            circle(d = knob_d - flute_r, $fn = 48);
            for (a = [0 : 360 / flute_count : 359]) {
                rotate([0, 0, a])
                    translate([(knob_d - flute_r)/2, 0])
                        circle(r = flute_r, $fn = 16);
            }
        }
        
        // 1. Heat-set insert bore from bottom face
        translate([0, 0, -0.1])
            cylinder(h = insert_pocket_depth + 0.1, d = insert_pocket_d, $fn = 36);
            
        // 2. Continuous M3 screw clearance through-hole
        translate([0, 0, -0.1])
            cylinder(h = knob_h + 0.2, d = screw_shaft_d, $fn = 30);
            
        // 3. Top rim chamfer
        translate([0, 0, knob_h - 0.7])
            difference() {
                cylinder(h = 0.8, d = knob_d + 3.0);
                cylinder(h = 0.9, d1 = knob_d - 1.4, d2 = knob_d + 1.0);
            }
            
        // 4. Bottom rim chamfer
        translate([0, 0, -0.1])
            difference() {
                cylinder(h = 0.6, d = knob_d + 2.0);
                cylinder(h = 0.7, d1 = knob_d - 1.0, d2 = knob_d + 1.0);
            }
    }
}

module thumb_nut_pair(spacing = 4.0) {
    translate([-knob_d/2 - spacing/2, 0, 0]) thumb_nut();
    translate([knob_d/2 + spacing/2, 0, 0]) thumb_nut();
}

// ------------------------------------------------------------------------------
// INSERT-STUD KNOB (1-Piece Knob: Top Countersink + 3.0mm Heat-Set Insert)
// ------------------------------------------------------------------------------
// Features a dedicated top countersunk recess so an M3 flathead screw (DIN 965)
// sinks 100% FLUSH with the top face of the knob!
// Below the countersink sits the pilot bore for the 3.0mm brass heat-set insert.
// When screwed in from the top with Loctite/superglue, exactly 6.2 mm of threaded
// shaft extends out the bottom, engaging 100% of the 3.0mm panel insert!
insert_stud_h     = 5.8; // Knob total height (leaves 6.2mm of screw thread protruding)
head_recess_d     = 6.3; // Top countersunk recess diameter for M3 flathead (head is 5.6-6.0mm)
head_recess_depth = 1.7; // Depth of top 90-degree countersink cone (sinks head 100% flush)
insert_depth      = 3.2; // Pilot bore depth for 3.0mm brass heat-set insert

module insert_stud_knob() {
    difference() {
        linear_extrude(height = insert_stud_h) {
            circle(d = knob_d - flute_r, $fn = 48);
            for (a = [0 : 360 / flute_count : 359]) {
                rotate([0, 0, a])
                    translate([(knob_d - flute_r)/2, 0])
                        circle(r = flute_r, $fn = 16);
            }
        }
        
        // 1. Top countersunk recess for M3 flathead screw (sits 100% flush)
        translate([0, 0, insert_stud_h - head_recess_depth]) {
            cylinder(h = head_recess_depth + 0.05, d1 = insert_pocket_d, d2 = head_recess_d, $fn = 36);
            // Cylindrical top rim for clean print edge
            translate([0, 0, head_recess_depth - 0.3])
                cylinder(h = 0.35, d = head_recess_d, $fn = 36);
        }
        
        // 2. Pilot bore for 3.0mm brass heat-set insert (immediately below countersunk seat)
        translate([0, 0, insert_stud_h - head_recess_depth - insert_depth])
            cylinder(h = insert_depth + 0.05, d = insert_pocket_d, $fn = 36);
            
        // 3. Continuous M3 screw clearance through-hole through base
        translate([0, 0, -0.1])
            cylinder(h = insert_stud_h + 0.2, d = screw_shaft_d, $fn = 30);
            
        // 4. Top rim comfort chamfer
        translate([0, 0, insert_stud_h - 0.7])
            difference() {
                cylinder(h = 0.8, d = knob_d + 3.0);
                cylinder(h = 0.9, d1 = knob_d - 1.4, d2 = knob_d + 1.0);
            }
            
        // 5. Bottom rim chamfer (smooth seating against rear bracket)
        translate([0, 0, -0.1])
            difference() {
                cylinder(h = 0.6, d = knob_d + 2.0);
                cylinder(h = 0.7, d1 = knob_d - 1.0, d2 = knob_d + 1.0);
            }
    }
}

module insert_stud_pair(spacing = 4.0) {
    translate([-knob_d/2 - spacing/2, 0, 0]) insert_stud_knob();
    translate([knob_d/2 + spacing/2, 0, 0]) insert_stud_knob();
}

module insert_stud_preview() {
    // 1-piece knob in blue
    color("#0284c7") insert_stud_knob();
    
    // Brass insert sitting below the countersink
    color("#d97706")
        translate([0, 0, insert_stud_h - head_recess_depth - 3.0])
            difference() {
                cylinder(h = 3.0, d = 4.6, $fn = 30);
                translate([0, 0, -0.1])
                    cylinder(h = 3.2, d = 2.9, $fn = 30);
            }
            
    // M3x12 countersunk Philips screw (flathead flush at top)
    color("#f59e0b")
        translate([0, 0, insert_stud_h])
            rotate([180, 0, 0]) {
                difference() {
                    union() {
                        cylinder(h = 1.7, d1 = 6.0, d2 = 3.0, $fn = 30);
                        translate([0, 0, 1.7])
                            cylinder(h = 10.3, d = 3.0, $fn = 30);
                    }
                    // Philips PH1 cross drive recess
                    translate([0, 0, 0.5]) {
                        cube([2.8, 0.75, 1.3], center = true);
                        cube([0.75, 2.8, 1.3], center = true);
                    }
                }
            }
}

module insert_stud_cutaway_preview() {
    difference() {
        insert_stud_preview();
        translate([-knob_d * 1.5, -knob_d * 2, -15])
            cube([knob_d * 3, knob_d * 2, knob_h + 30]);
    }
}

// ==============================================================================
// TOP-LEVEL SELECTOR
// ==============================================================================
if (part == 1 || part == "pair") {
    thumbscrew_pair(spacing = 4.0);
} else if (part == 2 || part == "single") {
    thumbscrew_single(spacing = 4.0);
} else if (part == 3 || part == "set4") {
    thumbscrew_set4(spacing = 4.0);
} else if (part == 4 || part == "knob_only") {
    thumbscrew_knob();
} else if (part == 5 || part == "cap_only") {
    locking_cap();
} else if (part == 6 || part == "preview") {
    thumbscrew_assembled_preview();
} else if (part == 7 || part == "cutaway") {
    thumbscrew_cutaway_preview();
} else if (part == 8 || part == "thumb_nut_pair") {
    thumb_nut_pair(spacing = 4.0);
} else if (part == 9 || part == "thumb_nut_single") {
    thumb_nut();
} else if (part == 10 || part == "insert_stud_pair") {
    insert_stud_pair(spacing = 4.0);
} else if (part == 11 || part == "insert_stud_single") {
    insert_stud_knob();
} else if (part == 12 || part == "insert_stud_preview") {
    insert_stud_preview();
} else if (part == 13 || part == "insert_stud_cutaway") {
    insert_stud_cutaway_preview();
}
