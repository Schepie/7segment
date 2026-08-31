// Modular 7-Segment Display (Backplate & Frontplate Design for AMS)
// Configured for 93 mm parallel strip pitch, 105 mm total segment length with connector,
// 68 mm LED strip length, and 4.5 mm thick 90° corner connectors.

// --- Key Parameters ---
panel_id = 1;           // Set to 1 (Primary panel with ESP32-C3 snap cradle), 2, 3, or 4

// --- Visibility Toggles (By default front plates are hidden) ---
show_frontplate_black = false; // Set to true to view black frontplate housing
show_frontplate_white = false; // Set to true to view white diffuser frontplate
show_backplate = true;         // Set to true to view backplate

pitch_x = 92;           // Distance between the middle of the vertical LED strips = 92mm
pitch_y_top = 92;       // Distance from middle horizontal cavity to top horizontal cavity = 92mm
pitch_y_bot = 92;       // Distance from middle horizontal cavity to bottom horizontal cavity = 92mm
seg_length_x = 104;     // Total horizontal segment span (104mm)
seg_length_y_top = 104; // Total top vertical span (104mm)
seg_length_y_bot = 117; // Total bottom vertical span (117mm)
strip_length_x = 50;      // 50 mm active strip length for the 3 horizontal legs (A, G, D)
strip_length_y_top = 50;  // 50 mm active strip length for top vertical legs (F, B)
strip_length_y_bot = 50;  // 50 mm active strip length for bottom vertical legs (E, C)
strip_width = 12;        // Width of LED strip (12 mm)
connector_thick = 4.0;   // Thickness / depth of the 90° corner connector (4.0 mm, 2mm below strip recess)
connector_len = 27;      // (104 - 50) / 2 = 27mm connector allowance on horizontal legs
connector_width = 25;

// Cavity enlargement margins (Corner & Mid cavities sized so all 7 LED strip channels are exactly 50.0 mm)
strip_channel_width = strip_width * 1.10; // 13.2 mm (widened by 10%, +0.6mm on each side)
corner_pocket_w = 34.5;                   // 34.5mm width (horizontal channel = exactly 50.0 mm)
corner_pocket_h = 31.6;                   // Grown vertically by 1.9mm (from 29.7mm) to grow both ends equally
corner_pocket_size = 31.6;                // Corner pocket vertical size
mid_pocket_w = 34.0;                      // 34.0mm width (horizontal channel = exactly 50.0 mm)
mid_pocket_l = 47.8;                      // Grown vertically by 1.9mm on each end (from 44.0mm) to grow both ends equally

// Inter-panel connector pass-through (Sized for standard 4-pin LED strip connectors & JST-SM)
inter_wire_w = 16.0;   // 16.0mm width clears 4-pin JST-SM (14.2mm) & 10/12mm snap clips (15.2mm)
inter_wire_h = 8.5;    // 8.5mm height clears 4-pin JST-SM locking latch (7.4mm) & snap clips (5.5mm)
inter_flange_w = 18.5; // Outer male flange width (1.25mm wall thickness)
inter_flange_h = 11.0; // Outer male flange height (1.25mm wall thickness)
inter_flange_z = 6.0;  // Centered along Z in the 12mm tunnel depth

tunnel_depth = 12.4;    // Depth of the light tunnel (total_depth - diffuser_thick)
diffuser_thick = 0.6;   // Thickness of the white top diffuser layer (0.6mm or 0.8mm)
total_depth = 13.0;     // Total frontplate housing depth (13.0 mm)
enable_lightguide_snap_locks = true; // Modular snap-fit replaceable segments
segment_clearance = 0.15; // 0.15mm perimeter clearance for smooth slide-in fit without binding
white_wall = 1.2;       // Thickness of the white inner reflector walls
front_wall = 2.0;       // Black divider wall thickness between segment diffusers

backplate_floor = 1.5;  // Solid base floor under connector pockets
backplate_thick = connector_thick + backplate_floor; // 6.0 mm total backplate thickness
strip_recess_depth = 2.0; // Depth of LED strip recess

margin_x = 15;          // Extra bezel space on left and right sides
margin_y = 15;          // Extra bezel space on top and bottom sides

// ESP32 Board & Snap Cradle Parameters (19.0 x 23.4 mm inner cradle)
esp_inner_w = 19.0;     // Inner cradle width (19.0 mm)
esp_inner_l = 23.4;     // Inner cradle length (23.4 mm)
esp_wall = 1.8;         // Cradle wall thickness
esp_outer_w = esp_inner_w + esp_wall * 2; // 22.6mm
esp_outer_l = esp_inner_l + esp_wall * 2; // 27.0mm
esp_h = 3.5;            // Retaining wall height above backplate
pcb_thick = 1.6;        // Standard PCB thickness
snap_lip = 0.7;         // Retention overhang depth

// --- Calculated Dimensions ---
diffuser_w = strip_width + 2;      // inner diffuser width
total_seg_w = diffuser_w + white_wall * 2; // outer white cup width

// Ensure a solid black wall of thickness 'front_wall' between the mitered segments
total_seg_l_x = pitch_x - front_wall * 1.4142;
total_seg_l_y_top = pitch_y_top - front_wall * 1.4142;
total_seg_l_y_bot = pitch_y_bot - front_wall * 1.4142;
diffuser_l_x = total_seg_l_x - white_wall * 2;
diffuser_l_y_top = total_seg_l_y_top - white_wall * 2;
diffuser_l_y_bot = total_seg_l_y_bot - white_wall * 2;

digit_width = pitch_x + total_seg_w + margin_x * 2;
digit_height = pitch_y_top + pitch_y_bot + total_seg_w + margin_y * 2;

// --- Shapes ---

// Pointy-end polygon for classic 7-segment display aesthetic (centered at origin)
module segment_shape(l, w, h) {
    translate([0, 0, -0.1])
    linear_extrude(height = h + 0.2)
    polygon([
        [-l/2 + w/2, -w/2],
        [l/2 - w/2, -w/2],
        [l/2, 0],
        [l/2 - w/2, w/2],
        [-l/2 + w/2, w/2],
        [-l/2, 0]
    ]);
}

// Layout helper for placing all 7 segments (A, B, C, D, E, F, G) on 93 mm pitch
module layout_horiz(is_top=false, is_bot=false) {
    if (is_top) {
        translate([0, pitch_y_top, 0]) children();
    } else if (is_bot) {
        translate([0, -pitch_y_bot, 0]) children();
    } else {
        translate([0, 0, 0]) children();
    }
}

module layout_vert(is_top=false) {
    if (is_top) {
        translate([-pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) children();
        translate([pitch_x/2, pitch_y_top/2, 0]) rotate([0, 0, 90]) children();
    } else {
        translate([-pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) children();
        translate([pitch_x/2, -pitch_y_bot/2, 0]) rotate([0, 0, 90]) children();
    }
}

// LED strip & connector channels on backplate
module led_strip_channel(seg_len, strip_len) {
    translate([-strip_len/2, -strip_width/2, -strip_recess_depth])
        cube([strip_len, strip_width, strip_recess_depth + 0.1]);
        
    
    translate([-seg_len/2 - 0.1, -connector_width/2, -connector_thick])
        cube([connector_len + 0.2, connector_width, connector_thick + 0.1]);
        
    translate([seg_len/2 - connector_len - 0.1, -connector_width/2, -connector_thick])
        cube([connector_len + 0.2, connector_width, connector_thick + 0.1]);
}

// Inward snap lug on flexible cantilever arm (8mm wide along Y)
module esp32_snap_lug() {
    rotate([90, 0, 0])
        linear_extrude(height = 8, center = true)
            polygon([
                [0, pcb_thick],                 // bottom flat retention shoulder resting over PCB
                [snap_lip, pcb_thick],          // sharp 90-degree locking overhang
                [snap_lip, pcb_thick + 0.6],    // vertical retaining land
                [0, esp_h]                      // 45-degree push-in lead-in ramp
            ]);
}

// ESP32 Snap-Fit Locking Cradle (with mechanical cantilever snap clips)
module esp32_cradle() {
    union() {
        // 1. Main outer housing box with PCB pocket and wire/USB openings cut out
        difference() {
            // Main outer housing block (sunk 1mm into plate for perfect manifold union)
            translate([0, 0, (esp_h - 1) / 2])
                cube([esp_outer_w, esp_outer_l, esp_h + 1], center=true);
                
            // Main PCB pocket (cuts from Z=0 upwards)
            translate([0, 0, esp_h/2 + 0.5])
                cube([esp_inner_w, esp_inner_l, esp_h + 1.1], center=true);
                
            // Flexible relief slits on both sides of the snap arms (width 1.0mm, depth down to Z=0.2)
            for (sx = [-1, 1]) {
                for (sy = [-4.5, 4.5]) {
                    translate([sx * (esp_inner_w/2 + esp_wall/2), sy, esp_h/2 + 0.2])
                        cube([esp_wall + 0.4, 1.0, esp_h + 0.5], center=true);
                }
            }
            
            // Recess in floor for bottom components/solder joints (0.8mm deep)
            translate([0, 0, -0.3])
                cube([esp_inner_w - 2.5, esp_inner_l - 2.5, 0.81], center=true);
                
            // North cable exit opening (to middle LED strip)
            translate([0, esp_outer_l/2, esp_h/2 + 0.5])
                cube([10, esp_wall * 2 + 0.2, esp_h + 1.2], center=true);
                
            // South USB port opening
            translate([0, -esp_outer_l/2, esp_h/2 + 0.5])
                cube([10, esp_wall * 2 + 0.2, esp_h + 1.2], center=true);
        }
        
        // 2. Inward snap lugs on the flexible cantilever arms (8mm wide along Y)
        // Left snap lug (at X = -esp_inner_w/2)
        translate([-esp_inner_w/2, 0, 0]) esp32_snap_lug();
        
        // Right snap lug (at X = +esp_inner_w/2)
        translate([esp_inner_w/2, 0, 0]) mirror([1, 0, 0]) esp32_snap_lug();
    }
}

// MH-Real-Time-Clock-2 (DS1302) Module Parameters & Standoff Mount
rtc_hole_pitch_x = 38.0;  // Mounting hole pitch along X (38.0 mm)
rtc_hole_pitch_y = 17.5;  // Mounting hole pitch along Y (17.5 mm)
rtc_boss_r       = 3.2;   // Standoff boss outer radius (dia 6.4 mm)
rtc_hole_r       = 1.25;  // Pilot hole radius for M2.5/M3 screws (dia 2.5 mm)
rtc_standoff_h   = 3.5;   // Standoff height above backplate (clearance for underside solder pins)

// MH-Real-Time-Clock (DS1302) Mount with 4 M3 Screw Bosses
module rtc_ds1302_mount() {
    union() {
        for (dx = [-rtc_hole_pitch_x/2, rtc_hole_pitch_x/2]) {
            for (dy = [-rtc_hole_pitch_y/2, rtc_hole_pitch_y/2]) {
                translate([dx, dy, 0]) {
                    difference() {
                        // Standoff cylinder pillar sunk 1mm into plate for perfect manifold union
                        translate([0, 0, (rtc_standoff_h - 1)/2])
                            cylinder(h = rtc_standoff_h + 1, r = rtc_boss_r, center = true, $fn = 24);
                        // Screw pilot hole
                        translate([0, 0, rtc_standoff_h/2 + 0.1])
                            cylinder(h = rtc_standoff_h + 1.2, r = rtc_hole_r, center = true, $fn = 20);
                    }
                }
            }
        }
    }
}

// Helper: debossed rectangular score line for clean punch-out breakaway membranes
module breakaway_score_rect(w, h, groove_w = 0.4, depth = 0.2) {
    difference() {
        cube([depth + 0.1, w + groove_w * 2, h + groove_w * 2], center=true);
        cube([depth + 0.3, w, h], center=true);
    }
}

// Robust Snap-In Cable Clip fused directly to the inner perimeter wall and ceiling
module perimeter_wall_clip(x_pos, y_pos, along_x = false, side_sign = -1) {
    clip_len = 8.0;      // Length along the wall (8.0mm)
    clip_reach = 5.5;    // Projection from wall into the housing (5.5mm)
    wire_w = 3.6;        // Wire cavity width for high-current wires
    wire_h = 4.2;        // Wire cavity height (4.2mm)
    lip_w = 1.1;         // Retention overhang lip (1.1mm)
    
    translate([x_pos, y_pos, 0]) {
        rotate([0, 0, along_x ? (side_sign > 0 ? 90 : -90) : (side_sign > 0 ? 180 : 0)]) {
            // Local frame: Wall is at X = 0, clip extends in +X direction
            difference() {
                // 1. Solid clip body firmly rooted into perimeter wall and front ceiling
                translate([clip_reach/2 - 0.5, 0, (total_depth - 1.0)/2 + 1.0])
                    cube([clip_reach + 1.0, clip_len, total_depth - 1.0], center=true);
                    
                // 2. Wire pocket holding wires snugly against the wall (centered at Z = inter_flange_z)
                translate([wire_w/2 + 0.3, 0, inter_flange_z])
                    cube([wire_w + 0.6, clip_len + 0.2, wire_h], center=true);
                    
                // 3. Rear insertion slot (Z = 0 up to pocket) with snap retention lip
                translate([wire_w/2 - lip_w/2, 0, inter_flange_z/2])
                    cube([wire_w - lip_w + 0.2, clip_len + 0.2, inter_flange_z + 0.1], center=true);
                    
                // 4. 45-degree lead-in chamfer for smooth wire press-in
                translate([wire_w - 0.2, 0, 1.2])
                    rotate([0, 45, 0])
                        cube([2.0, clip_len + 0.4, 2.0], center=true);
            }
        }
    }
}

module frontplate_perimeter_cable_holders() {
    // 1. Left inner wall (X = -67.2mm, pointing inward +X): Upper and Lower runs
    for (y = [-70.0, -40.0, 40.0, 70.0]) {
        perimeter_wall_clip(-67.2, y, along_x = false, side_sign = -1);
    }
    
    // 2. Right inner wall (X = +67.2mm, pointing inward -X): Upper and Lower runs
    for (y = [-70.0, -40.0, 40.0, 70.0]) {
        perimeter_wall_clip(67.2, y, along_x = false, side_sign = 1);
    }
    
    // 3. Top short side wall (Y = +104.0mm, pointing inward -Y)
    for (x = [-45.0, -20.0, 20.0, 45.0]) {
        perimeter_wall_clip(x, 104.0, along_x = true, side_sign = 1);
    }
    
    // 4. Bottom short side wall (Y = -104.0mm, pointing inward +Y)
    for (x = [-45.0, -20.0, 20.0, 45.0]) {
        perimeter_wall_clip(x, -104.0, along_x = true, side_sign = -1);
    }
}

// Shared connector clearance notches cut into underside of front plates (bottom 3.1mm at Z=0..3.1)
module connector_clearance_notches(h = 6.2) {
    translate([0, 0, -h/2]) {
        // Middle left & right (matching enlarged 34.0 x 47.8 mm transition cavities)
        translate([-pitch_x/2, 0, 0]) translate([-13, -mid_pocket_l/2, 0]) cube([mid_pocket_w, mid_pocket_l, h]);
        translate([pitch_x/2, 0, 0]) translate([13 - mid_pocket_w, -mid_pocket_l/2, 0]) cube([mid_pocket_w, mid_pocket_l, h]);
        
        // Top left & right (matching enlarged 34.5 x 31.6 mm corner pockets)
        translate([-pitch_x/2, pitch_y_top, 0]) translate([-13.5, 13.5 - corner_pocket_h, 0]) cube([corner_pocket_w, corner_pocket_h, h]);
        translate([pitch_x/2, pitch_y_top, 0]) translate([13.5 - corner_pocket_w, 13.5 - corner_pocket_h, 0]) cube([corner_pocket_w, corner_pocket_h, h]);
        
        // Bottom left & right (matching enlarged 34.5 x 31.6 mm corner pockets)
        translate([-pitch_x/2, -pitch_y_bot, 0]) translate([-13.5, -13.5, 0]) cube([corner_pocket_w, corner_pocket_h, h]);
        translate([pitch_x/2, -pitch_y_bot, 0]) translate([13.5 - corner_pocket_w, -13.5, 0]) cube([corner_pocket_w, corner_pocket_h, h]);
    }
}

// Symmetrical snap tabs along the upper and lower straight walls of each segment
module single_segment_snap_teeth(l = total_seg_l_x, w = total_seg_w, is_subtraction = false) {
    if (enable_lightguide_snap_locks) {
        tooth_w = 3.5;         // Width along segment length
        tooth_h = 2.2;         // Height along Z
        tooth_reach = is_subtraction ? 0.65 : 0.45; // Outward latching reach
        z_pos = 3.0;           // Positioned in lower third above LED plane
        
        // 2 snap teeth along upper wall (+Y) and 2 along lower wall (-Y)
        for (side = [-1, 1]) {
            for (x_pos = [-22.0, 22.0]) {
                translate([x_pos, side * (w/2 - (is_subtraction ? 0 : segment_clearance)), z_pos]) {
                    if (is_subtraction) {
                        // Pocket detent cutout extending cleanly into the channel void
                        translate([0, side * (tooth_reach - 0.5), 0])
                            cube([tooth_w + 0.5, 1.0 + tooth_reach * 2, tooth_h + 0.4], center=true);
                    } else {
                        // Outward latching tooth with 45° lead-in chamfers
                        rotate([side > 0 ? 0 : 180, 0, 0])
                            rotate([0, 90, 0])
                                linear_extrude(tooth_w, center=true)
                                    polygon([
                                        [-tooth_h/2, -0.4],
                                        [-tooth_h/4, tooth_reach],
                                        [tooth_h/4, tooth_reach],
                                        [tooth_h/2, -0.4]
                                    ]);
                    }
                }
            }
        }
    }
}

// Vertical flex relief slits flanking each snap tooth
module single_segment_flex_slits(w = total_seg_w) {
    if (enable_lightguide_snap_locks) {
        slit_w = 0.8;
        slit_l = 3.5;
        slit_h = 5.5;
        
        for (side = [-1, 1]) {
            for (x_center = [-22.0, 22.0]) {
                for (dx = [-2.5, 2.5]) {
                    translate([x_center + dx, side * (w/2 - segment_clearance), slit_h/2 - 0.1])
                        cube([slit_w, slit_l, slit_h + 0.2], center=true);
                }
            }
        }
    }
}

// Single standalone replaceable segment module
module single_segment_lightguide(d_thick = diffuser_thick, l = total_seg_l_x, w = total_seg_w) {
    t_depth = total_depth - d_thick;
    eff_w = w - segment_clearance * 2;
    eff_l = l - segment_clearance * 2;
    inner_w = diffuser_w;
    inner_l = l - white_wall * 2;
    
    difference() {
        union() {
            // Outer white reflector walls + top solid diffuser face
            segment_shape(eff_l, eff_w, total_depth);
            
            // Outward snap-lock teeth on long sides
            single_segment_snap_teeth(l, w, is_subtraction = false);
        }
        
        // Hollow light tunnel cavity from bottom up to (total_depth - d_thick)
        translate([0, 0, -0.1])
            segment_shape(inner_l, inner_w, t_depth + 0.1);
            
        // Compliance flex slits allowing snap tabs to deflect during insertion
        single_segment_flex_slits(w);
    }
}

// Modular 7-segment assembly (all 7 separate segments positioned in digit layout)
module modular_7segment_assembled(d_thick = diffuser_thick) {
    layout_horiz(true, false) single_segment_lightguide(d_thick, total_seg_l_x, total_seg_w);
    layout_horiz(false, false) single_segment_lightguide(d_thick, total_seg_l_x, total_seg_w);
    layout_horiz(false, true) single_segment_lightguide(d_thick, total_seg_l_x, total_seg_w);
    layout_vert(true) single_segment_lightguide(d_thick, total_seg_l_y_top, total_seg_w);
    layout_vert(false) single_segment_lightguide(d_thick, total_seg_l_y_bot, total_seg_w);
}

// Helper to subtract snap-lock detent pockets from black housing
module all_segments_snap_subtractions() {
    layout_horiz(true, false) single_segment_snap_teeth(total_seg_l_x, total_seg_w, is_subtraction = true);
    layout_horiz(false, false) single_segment_snap_teeth(total_seg_l_x, total_seg_w, is_subtraction = true);
    layout_horiz(false, true) single_segment_snap_teeth(total_seg_l_x, total_seg_w, is_subtraction = true);
    layout_vert(true) single_segment_snap_teeth(total_seg_l_y_top, total_seg_w, is_subtraction = true);
    layout_vert(false) single_segment_snap_teeth(total_seg_l_y_bot, total_seg_w, is_subtraction = true);
}

// --- Components ---

module frontplate_black(panel_id = panel_id) {
    difference() {
        union() {
            // 1. Main frame (hollowed out from the back, leaving 2mm walls and 2mm front face)
            // Outer skirt extends down over the backplate
            difference() {
                translate([-digit_width/2, (pitch_y_top - pitch_y_bot)/2 - digit_height/2, -backplate_thick]) 
                    cube([digit_width, digit_height, total_depth + backplate_thick]);
                translate([-digit_width/2 + 2, (pitch_y_top - pitch_y_bot)/2 - digit_height/2 + 2, -backplate_thick - 1]) 
                    cube([digit_width - 4, digit_height - 4, total_depth + backplate_thick - 1]);
            }
            
            // 2. Black walls around the segments (to prevent light bleed)
            layout_horiz(false, false) segment_shape(total_seg_l_x + 4, total_seg_w + 4, total_depth);
            layout_horiz(true, false) segment_shape(total_seg_l_x + 4, total_seg_w + 4, total_depth);
            layout_horiz(false, true) segment_shape(total_seg_l_x + 4, total_seg_w + 4, total_depth);
            layout_vert(true) segment_shape(total_seg_l_y_top + 4, total_seg_w + 4, total_depth);
            layout_vert(false) segment_shape(total_seg_l_y_bot + 4, total_seg_w + 4, total_depth);
                
            // 3. Corner screw posts for backplate
            translate([digit_width/2 - 6, (pitch_y_top - pitch_y_bot)/2 + digit_height/2 - 6, -0.1]) cylinder(h=total_depth + 0.1, r=4, $fn=20);
            translate([-digit_width/2 + 6, (pitch_y_top - pitch_y_bot)/2 + digit_height/2 - 6, -0.1]) cylinder(h=total_depth + 0.1, r=4, $fn=20);
            translate([digit_width/2 - 6, (pitch_y_top - pitch_y_bot)/2 - digit_height/2 + 6, -0.1]) cylinder(h=total_depth + 0.1, r=4, $fn=20);
            translate([-digit_width/2 + 6, (pitch_y_top - pitch_y_bot)/2 - digit_height/2 + 6, -0.1]) cylinder(h=total_depth + 0.1, r=4, $fn=20);
            
            // Inter-panel alignment protrusion (Right side, robust male flange sticking out 3mm)
            if (panel_id < 4) {
                translate([digit_width/2, 0, inter_flange_z]) 
                    cube([6, inter_flange_w, inter_flange_h], center=true);
            }
            
            // 4. Integrated Perimeter Cable Retention Holders (along left, bottom, and right inner walls)
            frontplate_perimeter_cable_holders();
        }
        
        // NOW cut out the actual white segment spaces
        layout_horiz(false, false) translate([0, 0, -1]) segment_shape(total_seg_l_x, total_seg_w, total_depth + 2);
        layout_horiz(true, false) translate([0, 0, -1]) segment_shape(total_seg_l_x, total_seg_w, total_depth + 2);
        layout_horiz(false, true) translate([0, 0, -1]) segment_shape(total_seg_l_x, total_seg_w, total_depth + 2);
        layout_vert(true) translate([0, 0, -1]) segment_shape(total_seg_l_y_top, total_seg_w, total_depth + 2);
        layout_vert(false) translate([0, 0, -1]) segment_shape(total_seg_l_y_bot, total_seg_w, total_depth + 2);
            
        // Snap-lock detent pockets in black housing channels
        if (enable_lightguide_snap_locks) {
            all_segments_snap_subtractions();
        }

        // Screw holes for backplate to mount (sized for standard M3 heat-set inserts, 4.2mm diameter)
        translate([digit_width/2 - 6, (pitch_y_top - pitch_y_bot)/2 + digit_height/2 - 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([-digit_width/2 + 6, (pitch_y_top - pitch_y_bot)/2 + digit_height/2 - 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([digit_width/2 - 6, (pitch_y_top - pitch_y_bot)/2 - digit_height/2 + 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([-digit_width/2 + 6, (pitch_y_top - pitch_y_bot)/2 - digit_height/2 + 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        
        if (panel_id == 1) {
            // USB-C Snap-In Connector Cutout (Left side: 14.1mm width x 7.2mm height)
            translate([-digit_width/2, 0, inter_flange_z]) 
                cube([10, 14.1, 7.2], center=true);
        }
        
        // Inter-panel wire pass-through hole (Right side)
        if (panel_id < 4) {
            translate([digit_width/2 + 2.6 - 7.5, 0, inter_flange_z]) 
                cube([15, inter_wire_w, inter_wire_h], center=true);
            translate([digit_width/2 + 3.0 - 0.1, 0, inter_flange_z])
                breakaway_score_rect(inter_wire_w, inter_wire_h, groove_w=0.4, depth=0.2);
        }
        
        // Inter-panel wire pass-through & alignment receiver (Left side)
        if (panel_id > 1) {
            translate([-digit_width/2 + 0.4 + 7.5, 0, inter_flange_z]) 
                cube([15, inter_flange_w + 0.5, inter_flange_h + 0.5], center=true);
            translate([-digit_width/2 + 0.1, 0, inter_flange_z])
                breakaway_score_rect(inter_flange_w + 0.5, inter_flange_h + 0.5, groove_w=0.4, depth=0.2);
        }

        // Connector clearance and wire routing notches
        connector_clearance_notches(6.2);
    }
}

module frontplate_white() {
    if (enable_lightguide_snap_locks) {
        modular_7segment_assembled(diffuser_thick);
    } else {
        difference() {
            union() {
                layout_horiz(false, false) segment_shape(total_seg_l_x, total_seg_w, total_depth);
                layout_horiz(true, false) segment_shape(total_seg_l_x, total_seg_w, total_depth);
                layout_horiz(false, true) segment_shape(total_seg_l_x, total_seg_w, total_depth);
                layout_vert(true) segment_shape(total_seg_l_y_top, total_seg_w, total_depth);
                layout_vert(false) segment_shape(total_seg_l_y_bot, total_seg_w, total_depth);
            }
            layout_horiz(false, false) translate([0, 0, -0.1]) segment_shape(diffuser_l_x, diffuser_w, tunnel_depth + 0.1);
            layout_horiz(true, false) translate([0, 0, -0.1]) segment_shape(diffuser_l_x, diffuser_w, tunnel_depth + 0.1);
            layout_horiz(false, true) translate([0, 0, -0.1]) segment_shape(diffuser_l_x, diffuser_w, tunnel_depth + 0.1);
            layout_vert(true) translate([0, 0, -0.1]) segment_shape(diffuser_l_y_top, diffuser_w, tunnel_depth + 0.1);
            layout_vert(false) translate([0, 0, -0.1]) segment_shape(diffuser_l_y_bot, diffuser_w, tunnel_depth + 0.1);
        }
    }
}

module backplate(panel_id = panel_id) {
    difference() {
        union() {
            // Main flat plate (shrunk by 2mm per side for walls + 0.2mm clearance)
            translate([-(digit_width - 4.4)/2, (pitch_y_top - pitch_y_bot)/2 - (digit_height - 4.4)/2, -backplate_thick])
                cube([digit_width - 4.4, digit_height - 4.4, backplate_thick]);
                
            // Solid reinforcing pillars under VESA mount screw bosses (running full depth through plate)
            for (x = [-25, 25]) {
                for (y = [-25, 25]) {
                    translate([x, y, -backplate_thick]) cylinder(h = backplate_thick + 4.0, r = 5.0, $fn = 30);
                }
            }
            
            // ESP32 Mini snap-fit locking cradle (only on panel 1)
            if (panel_id == 1) {
                translate([0, -50, 0])
                    esp32_cradle();
                    
                // MH-Real-Time-Clock-2 (DS1302) Module Mount with 4 screw bosses (at Y = +50)
                translate([0, 50, 0])
                    rtc_ds1302_mount();
            }
        }
            
        // Recesses for all 7 LED strip channels (2mm deep from Z = 0, enlarged 10% to 13.2mm width)
        // Channels run continuously into connector pockets so strips slide directly in
        // 1. Top Horizontal (Seg A): Y = +94, spanning between top corner pockets
        translate([0, pitch_y_top, -strip_recess_depth/2])
            cube([pitch_x, strip_channel_width, strip_recess_depth + 0.1], center=true);

        // 2. Middle Horizontal (Seg G): Y = 0, spanning between middle pockets
        translate([0, 0, -strip_recess_depth/2])
            cube([pitch_x, strip_channel_width, strip_recess_depth + 0.1], center=true);

        // 3. Bottom Horizontal (Seg D): Y = -94, spanning between bottom corner pockets
        translate([0, -pitch_y_bot, -strip_recess_depth/2])
            cube([pitch_x, strip_channel_width, strip_recess_depth + 0.1], center=true);

        // 4. Top-Left Vertical (Seg F): X = -47, running from middle pocket to top pocket
        translate([-pitch_x/2, pitch_y_top/2, -strip_recess_depth/2])
            cube([strip_channel_width, pitch_y_top, strip_recess_depth + 0.1], center=true);

        // 5. Top-Right Vertical (Seg B): X = +47, running from middle pocket to top pocket
        translate([pitch_x/2, pitch_y_top/2, -strip_recess_depth/2])
            cube([strip_channel_width, pitch_y_top, strip_recess_depth + 0.1], center=true);

        // 6. Bottom-Left Vertical (Seg E): X = -47, running from bottom pocket to middle pocket
        translate([-pitch_x/2, -pitch_y_bot/2, -strip_recess_depth/2])
            cube([strip_channel_width, pitch_y_bot, strip_recess_depth + 0.1], center=true);

        // 7. Bottom-Right Vertical (Seg C): X = +47, running from bottom pocket to middle pocket
        translate([pitch_x/2, -pitch_y_bot/2, -strip_recess_depth/2])
            cube([strip_channel_width, pitch_y_bot, strip_recess_depth + 0.1], center=true);
            
        // Cable routing channels (only on panel 1):
        if (panel_id == 1) {
            // 1. ESP32 to middle LED strip (South channel)
            translate([0, -18.5, 0.5])
                cube([10, 37, 5.2], center=true);
                
            // 2. RTC module to middle LED strip (North channel)
            translate([0, 18.5, 0.5])
                cube([10, 37, 5.2], center=true);
        }
            
        // Deep pockets for 90-degree connectors & solder joints (circular area under screw bosses filled)
        difference() {
            translate([0, 0, -connector_thick]) {
                // Middle left & right: full extended transition cavities (34.0 x 44.0 mm)
                translate([-pitch_x/2, 0, 0]) translate([-13, -mid_pocket_l/2, 0]) cube([mid_pocket_w, mid_pocket_l, connector_thick + 0.1]);
                translate([pitch_x/2, 0, 0]) translate([13 - mid_pocket_w, -mid_pocket_l/2, 0]) cube([mid_pocket_w, mid_pocket_l, connector_thick + 0.1]);
                
                // Top left & right (enlarged horizontally to create 50 mm horizontal strip channel)
                translate([-pitch_x/2, pitch_y_top, 0]) translate([-13.5, 13.5 - corner_pocket_h, 0]) cube([corner_pocket_w, corner_pocket_h, connector_thick + 0.1]);
                translate([pitch_x/2, pitch_y_top, 0]) translate([13.5 - corner_pocket_w, 13.5 - corner_pocket_h, 0]) cube([corner_pocket_w, corner_pocket_h, connector_thick + 0.1]);
                
                // Bottom left & right (enlarged horizontally to create 50 mm horizontal strip channel)
                translate([-pitch_x/2, -pitch_y_bot, 0]) translate([-13.5, -13.5, 0]) cube([corner_pocket_w, corner_pocket_h, connector_thick + 0.1]);
                translate([pitch_x/2, -pitch_y_bot, 0]) translate([13.5 - corner_pocket_w, -13.5, 0]) cube([corner_pocket_w, corner_pocket_h, connector_thick + 0.1]);
            }
            
            // Fill ONLY the circular area under each of the 4 screw bosses (radius = 5.0 mm)
            for (x = [-25, 25]) {
                for (y = [-25, 25]) {
                    translate([x, y, -connector_thick - 0.5])
                        cylinder(h = connector_thick + 1, r = 5.0, $fn = 30);
                }
            }
        }
            
         
        // Mounting screw holes (M3 clearance, 3.2mm) with countersink for flush heads
        for (x = [digit_width/2 - 6, -digit_width/2 + 6]) {
            for (y = [(pitch_y_top - pitch_y_bot)/2 + digit_height/2 - 6, (pitch_y_top - pitch_y_bot)/2 - digit_height/2 + 6]) {
                translate([x, y, -backplate_thick - 0.1]) {
                    cylinder(h=backplate_thick + 0.2, r=1.6, $fn=20);       // Main shaft
                    cylinder(h=1.6, r1=3.2, r2=1.6, $fn=20);                // 90-degree countersink cone
                }
            }
        }
        
        // VESA-like mounting pattern (50x50 mm) in the center of the backplate
        // Holes stop 0.4mm short of the outside surface to create a waterproof breakaway membrane
        for (x = [-25, 25]) {
            for (y = [-25, 25]) {
                // The main insert hole (leaves 0.4mm membrane at the bottom)
                translate([x, y, -backplate_thick + 0.4]) cylinder(h=backplate_thick + 6, r=2.1, $fn=20);
                
                // Debossed guide ring on the outside to show where to punch (0.2mm deep)
                // This also thins the plastic around the edge of the hole so the membrane breaks away cleanly!
                translate([x, y, -backplate_thick - 0.1])
                    difference() {
                        cylinder(h=0.3, r=2.5, $fn=20);
                        translate([0, 0, -0.1]) cylinder(h=0.5, r=2.1, $fn=20);
                    }
            }
        }
        // Orientation indicator debossed into the top of the backplate
        // Mirrored along X so it reads correctly when looking at the physical back
        translate([0, 95, -backplate_thick - 0.1])
            linear_extrude(1.0)
                mirror([1, 0, 0])
                    text("↑ TOP", size=6, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    
        // Panel ID debossed into the center of the VESA mount
        // Mirrored along X so it reads correctly when looking at the physical back
        translate([0, 0, -backplate_thick - 0.1])
            linear_extrude(1.0)
                mirror([1, 0, 0])
                    text(str(panel_id), size=15, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    
        // Copyright text debossed into the outside face of the backplate (Z = -backplate_thick)
        // Mirrored along X so it reads correctly when looking at the physical back of the device
        translate([0, -100, -backplate_thick - 0.1])
            linear_extrude(1.0)
                mirror([1, 0, 0])
                    text("© Designed by Geert Schepers", size=4.2, font="Liberation Sans:style=Bold", halign="center", valign="center");
    }
}

// --- Rear Joining Bracket (Option 1: Rear Bridge Splice) ---
// Mounts externally to the back of adjacent panels across the seam.
// Spans the two adjacent corner M3 screw positions (center-to-center = 12.0 mm).
// Fastens with M3x12 or M3x14 countersunk screws directly into the frontplate heat-set inserts.

module rear_joining_bracket(thickness = 3.0, countersunk = true) {
    bracket_w = 28.0;   // 14mm on each panel across the seam
    edge_margin = 5.0;  // 1.0mm inset from outer housing perimeter (stays inside)
    inward_len = 12.0;  // Extension inward towards display center for rigidity
    hole_pitch = 12.0;  // Exact distance between adjacent corner screws (6mm + 6mm)
    fillet_r = 2.5;     // Corner rounding for sleek finish
    
    difference() {
        // Asymmetric rounded bracket body
        linear_extrude(height = thickness) {
            hull() {
                translate([-bracket_w/2 + fillet_r, -inward_len + fillet_r]) circle(r = fillet_r, $fn = 30);
                translate([bracket_w/2 - fillet_r, -inward_len + fillet_r])  circle(r = fillet_r, $fn = 30);
                translate([bracket_w/2 - fillet_r, edge_margin - fillet_r]) circle(r = fillet_r, $fn = 30);
                translate([-bracket_w/2 + fillet_r, edge_margin - fillet_r]) circle(r = fillet_r, $fn = 30);
            }
        }
        
        // 2x M3 Screw Holes (at Y = 0, spaced 12.0mm apart)
        for (x = [-hole_pitch/2, hole_pitch/2]) {
            translate([x, 0, -0.1]) {
                cylinder(h = thickness + 0.2, r = 1.7, $fn = 24); // 3.4mm clearance for M3
                if (countersunk) {
                    // Standard 90-degree M3 countersink head (max diameter ~6.4mm)
                    translate([0, 0, thickness - 1.8])
                        cylinder(h = 2.0, r1 = 1.7, r2 = 3.3, $fn = 24);
                }
            }
        }
    }
}

// --- Render Assembly ---
// When loaded in Bambu Studio / OrcaSlicer, these components align automatically.

if (show_frontplate_black) color("DimGray") frontplate_black();
if (show_frontplate_white) translate([0, 0, 20]) color("White") frontplate_white();
if (show_backplate) color("SlateGray") backplate();
