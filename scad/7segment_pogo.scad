// Modular 7-Segment Display with 4-Pin Magnetic Pogo Pin Connectors (AMS Multi-Color Design)
// Derived from 7segment_v1.scad, updated with flush-mount 4-pin magnetic pogo connectors
// with mounting ears (23.2 mm / 0.913 in) for tool-free, cable-free inter-panel chaining.
//
// Designed for Bambu Lab AMS / multi-material 3D printing.

// --- Key Parameters ---
panel_id              = 1;     // [1:4]
part_sel              = 0;     // [0:"all - Full Assembly", 1:"backplate_only - Backplate Only (for STL export)", 2:"frontplate_black - Black Frontplate", 3:"frontplate_white - White Diffusers", 4:"wpt_lid_only - WPT Retainer Lid"]
render_part           = "all"; // ["all": Full Assembly, "backplate_only": Backplate Only (for 3D Printing STL), "frontplate_black": Black Frontplate Only, "frontplate_white": White Diffuser Only, "wpt_lid_only": WPT Retainer Lid Only]

// --- Visibility, Assembly & Inspection Modes ---
/* [Inspection & Quality Control] */
inspection_mode       = "exploded"; // ["assembled": Fully Assembled View, "exploded": Exploded Layer View, "collision_check": Interference Check (Red Collisions), "clearance_check": Clearance Gap Check (Magenta), "cutaway_x": Cutaway Cross-Section (X-Axis), "cutaway_y": Cutaway Cross-Section (Y-Axis), "slice_z": 2D Seam Slice Profile (Z-Plane)]
clearance_gap         = 0.2;  // [0.05:0.05:1.0] Minimum clearance gap to verify in mm (violations highlighted in Magenta)
cutaway_depth         = 0.0;  // [-100:1:100] Offset along cut axis for cutaway view (mm)

/* [Layer Visibility Toggles] */
show_frontplate_black = true;  // Set to true to view black frontplate housing
show_frontplate_white = true;  // Set to true to view white diffuser frontplate
show_backplate        = true;  // Set to true to view backplate
show_pogo_hardware    = true;  // Set to true to preview 3D pogo connectors sitting in mounting pockets
show_wpt_hardware     = true;  // Set to true to preview 3D metal ring & wireless coil (Panel 3)
exploded_view         = true;  // Legacy toggle (used when inspection_mode is exploded)
explode_distance      = 55.0;  // Distance between exploded layers in mm

/* [Transparency / Opacity Settings] */
alpha_frontplate_black = 1.0;  // [0.0:0.05:1.0]
alpha_frontplate_white = 1.0;  // [0.0:0.05:1.0]
alpha_backplate        = 1.0;  // [0.0:0.05:1.0]
alpha_pogo_hardware    = 1.0;  // [0.0:0.05:1.0]
alpha_wpt_hardware     = 1.0;  // [0.0:0.05:1.0]

use <assembly_inspector.scad>
use <rear_joining_bracket_hinged.scad>
use <rear_corner_foot.scad>

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
connector_corner_relief_h = 2.0;          // Cutout depth from bottom of frontplate segment corners (mm) for LED connector clearance

// --- 4-Pin Magnetic Pogo Pin Connector Parameters ---
// Outside-Mount Parameters:
// - Full length across ears: 23.5 mm (+0.4mm clearance = 23.9 mm span)
// - Center-to-center hole pitch: 20.0 mm
// - Central body length: 17.5 mm (+0.5mm clearance = 18.0 mm)
// - Body thickness (Z-height): 4.0 mm (+0.4mm clearance = 4.4 mm)
// - Boss depth from outside: 3.0 mm (ensures connector front face sits flush with outer surface)
// - Mounting hole diameter: 1.8 mm
pogo_ear_span       = 23.9; // Total outer span across mounting ears (23.5mm nominal + 0.4mm clearance)
pogo_ear_pitch      = 20.0; // Center-to-center spacing between ear screw holes (20.0mm exact)
pogo_hole_d         = 1.8;  // Pilot hole diameter for M2 screws (1.8mm exact)
pogo_hole_depth     = 7.0;  // Deep thread depth into reinforced internal boss
pogo_body_w         = 18.0; // Central body width (17.5mm nominal + 0.5mm clearance)
pogo_body_h         = 4.4;  // Central body height (4.0mm nominal + 0.4mm clearance)
pogo_body_r         = 2.2;  // Corner radius for rounded stadium profile (4.4mm / 2)
pogo_boss_depth     = 3.0;  // Boss seating face is exactly 3.0mm deep from outside wall surface
pogo_boss_r         = 3.0;  // Outer radius of internal screw bosses (dia 6.0 mm)
pogo_pass_depth     = 10.0; // Inward wiring clearance for solder pins and 4-wire harness
pogo_z              = 6.0;  // Centered along Z in the 12mm tunnel depth

// --- Backplate Connector Tower & Stepped Lap-Joint Parameters ---
pogo_tower_w        = 32.0; // Total width of connector tower along Y (centered at Y = 0)
pogo_tower_h        = 10.5; // Top height of connector tower along Z (above Z = 0)
lap_step_w          = 1.0;  // Width of stepped lap-joint overlap along Y and Z
lap_step_d          = 1.0;  // Depth of stepped lap-joint shelf into wall thickness
tower_clearance     = 0.2;  // Clearance per side for smooth slide-on fit of frontplate over tower

tunnel_depth = 12.4;    // Depth of the light tunnel (calculated from total_depth - diffuser_thick)
diffuser_thick = 0.6;   // Thickness of the white top diffuser layer (0.6mm high brightness, 0.8mm balanced)
total_depth = 13.0;     // Total frontplate housing depth (13.0 mm)
enable_lightguide_snap_locks = true; // Modular snap-fit replaceable segments
segment_clearance = 0.15; // 0.15mm perimeter clearance for smooth slide-in fit without binding
white_wall = 1.2;       // Thickness of the white inner reflector walls
front_wall = 2.0;       // Black divider wall thickness between segment diffusers

backplate_floor = 1.5;  // Solid base floor under connector pockets
backplate_thick = connector_thick + backplate_floor; // 5.5 mm to 6.0 mm total backplate thickness
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

// --- Wireless Power Transfer (Qi / MagSafe) Receiver Parameters (Panel 3) ---
/* [Wireless Power Transfer (Panel 3)] */
enable_wireless_power      = true;  // Enable WPT ring and coil pocket on Panel 3
wpt_pos_y                  = 46.0;  // Y center position (46.0mm = Upper digit loop, 0.0mm = Center)
wpt_ring_od                = 57.2;  // Ring outer diameter with clearance (nominal 57.0mm + 0.2mm)
wpt_ring_id                = 45.8;  // Ring inner diameter with clearance (nominal 46.0mm - 0.2mm)
wpt_ring_depth             = 1.1;   // Stepped groove depth for 1.0mm metal ring
wpt_coil_w                 = 34.0;  // Rectangular coil pocket width (nominal 33.0mm + 1.0mm)
wpt_coil_l                 = 43.0;  // Rectangular coil pocket length (nominal 42.0mm + 1.0mm)
wpt_coil_corner_r          = 5.0;   // Corner radius for coil pocket
wpt_coil_depth             = 1.5;   // Depth for coil + ferrite sheet
wpt_floor_thick            = 0.8;   // Solid exterior rear skin thickness (mm)
wpt_show_alignment_guide   = true;  // 0.2mm subtle debossed target ring on outside rear face

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

// --- Shapes & Helpers ---

// Pointy-end polygon for classic 7-segment display aesthetic (centered at origin, flush from Z = 0 to h)
module segment_shape(l, w, h) {
    linear_extrude(height = h)
    polygon([
        [-l/2 + w/2, -w/2],
        [l/2 - w/2, -w/2],
        [l/2, 0],
        [l/2 - w/2, w/2],
        [-l/2 + w/2, w/2],
        [-l/2, 0]
    ]);
}

// Layout helper for placing all 7 segments (A, B, C, D, E, F, G) on 94 mm pitch
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

// -------------------------------------------------------------
// Backplate Connector Tower & Cable Support Modules
// -------------------------------------------------------------

// USB-C Cutout profile (14.1mm width horizontal along Y, 6.0mm height vertical along Z with 2.0mm flat vertical ends)
module usb_c_profile_2d(width = 14.1, height = 6.0, flat_vert = 2.0) {
    r = (height - flat_vert) / 2; // 2.0 mm corner radius
    dy = width / 2 - r;           // 5.05 mm along Y (horizontal)
    dz = flat_vert / 2;           // 1.0 mm along X (vertical in 3D)
    hull() {
        translate([-dz, -dy]) circle(r = r, $fn = 24);
        translate([ dz, -dy]) circle(r = r, $fn = 24);
        translate([-dz,  dy]) circle(r = r, $fn = 24);
        translate([ dz,  dy]) circle(r = r, $fn = 24);
    }
}

// Rounded Stadium cutout module (pill shape with semi-circular ends along X)
module rounded_stadium_slot(depth, length_y, height_z, center = true) {
    r = height_z / 2;
    linear_extrude(height = depth, center = center) {
        hull() {
            translate([0, -(length_y/2 - r)]) circle(r = r, $fn = 24);
            translate([0,  (length_y/2 - r)]) circle(r = r, $fn = 24);
        }
    }
}

// Monolithic Connector Tower integrated on the Backplate (Left or Right wall)
module backplate_connector_tower(is_left = false, is_usb = false) {
    side = is_left ? -1 : 1;
    wall_x = side * digit_width / 2; // Outside face of 2mm wall
    inner_x = side * (digit_width / 2 - 2.0); // Inside face of 2mm wall
    boss_face_x = wall_x - side * pogo_boss_depth; // Seating plane: -3.0mm from outside
    boss_len = 6.0; // Inward boss extension
    
    difference() {
        union() {
            // 1. Outer Wall Section (from wall_x to outer shelf step)
            // Height: -backplate_thick to pogo_tower_h (10.5mm)
            // Y-width: pogo_tower_w (32.0mm)
            translate([wall_x - side * (2.0 - lap_step_d)/2, 0, (pogo_tower_h - backplate_thick)/2])
                cube([2.0 - lap_step_d, pogo_tower_w, pogo_tower_h + backplate_thick], center = true);
                
            // 2. Inner Stepped Tongue / Backing Flange (Lap Joint Overlap)
            // Height: -backplate_thick to (pogo_tower_h + lap_step_w) (11.5mm)
            // Y-width: pogo_tower_w + 2 * lap_step_w (34.0mm)
            translate([inner_x + side * lap_step_d/2, 0, (pogo_tower_h + lap_step_w - backplate_thick)/2])
                cube([lap_step_d, pogo_tower_w + lap_step_w * 2, pogo_tower_h + lap_step_w + backplate_thick], center = true);
                
            // 3. Reinforced Solid Screw Bosses & Downward Web Anchors
            if (!is_usb) {
                for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
                    hull() {
                        translate([inner_x + side * 0.1, y, pogo_z])
                            cube([0.2, pogo_boss_r * 2, pogo_body_h + 2.0], center = true);
                        translate([boss_face_x - side * boss_len, y, pogo_z])
                            rotate([0, 90, 0])
                                cylinder(h = 0.5, r = pogo_boss_r, center = true, $fn = 24);
                    }
                    // Solid downward anchor web to backplate floor
                    translate([(inner_x + (boss_face_x - side * boss_len))/2, y, (pogo_z - backplate_thick)/2])
                        cube([abs(inner_x - (boss_face_x - side * boss_len)), pogo_boss_r * 2, pogo_z + backplate_thick], center = true);
                }
            } else {
                // Solid anchor block around USB-C port
                translate([(inner_x + wall_x - side * 4.0)/2, 0, (pogo_z - backplate_thick)/2])
                    cube([abs(inner_x - (wall_x - side * 4.0)), 20.0, pogo_z + backplate_thick], center = true);
            }
            
            // 4. Solid Monolithic Base Floor Footing
            // Fills the floor from Z = -backplate_thick to Z = 0 under the tower and fuses it directly into the backplate
            translate([(wall_x + (inner_x - side * 4.0))/2, 0, -backplate_thick/2])
                cube([abs(wall_x - (inner_x - side * 4.0)), pogo_tower_w, backplate_thick], center = true);
        }
        
        // --- SUBTRACTIONS (Cut from Tower) ---
        if (is_usb) {
            // Horizontal USB-C Port Cutout (14.1 x 6.0 mm, 2.0mm corner radius)
            translate([wall_x, 0, pogo_z])
                rotate([0, 90, 0])
                    linear_extrude(height = 20.0, center = true)
                        usb_c_profile_2d(width = 14.1, height = 6.0, flat_vert = 2.0);
                        
            // Interior Wire Exit Relief Pocket (toward ESP32)
            translate([inner_x - side * 2.0, 0, pogo_z])
                cube([6.0, 16.0, 8.0], center = true);
        } else {
            // 1. Full Outside-Mount Stadium Pocket (23.9 x 4.4 mm, 3.0mm deep from outside)
            translate([wall_x - side * (pogo_boss_depth / 2 - 0.05), 0, pogo_z])
                rotate([0, 90, 0])
                    rounded_stadium_slot(depth = pogo_boss_depth + 0.1, length_y = pogo_ear_span, height_z = pogo_body_h, center = true);
                
            // 2. Central Body Through-Opening (18.0 x 4.4 mm) passing through into inside cavity
            translate([wall_x - side * (3.0 + 3.0), 0, pogo_z])
                rotate([0, 90, 0])
                    rounded_stadium_slot(depth = 8.0, length_y = pogo_body_w, height_z = pogo_body_h, center = true);
                
            // 3. 2x Screw Pilot Holes (1.8mm dia, 7mm deep) drilled into bosses from boss_face_x
            for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
                translate([boss_face_x + side * 0.5, y, pogo_z])
                    rotate([0, -side * 90, 0])
                        cylinder(h = pogo_hole_depth + 1.0, r = pogo_hole_d / 2, $fn = 20);
            }
            
            // 4. Sense Resistor Pocket (5.0 x 3.5 x 2.5 mm cavity)
            translate([inner_x - side * 4.0, side * 8.0, 2.0])
                cube([5.0, 3.5, 3.0], center = true);
                
            // 5. Downward Wire Drop Chute (leads wires directly to sub-floor channel, safely inside inner wall)
            translate([inner_x - side * 3.5, 0, pogo_z / 2])
                cube([5.0, 12.0, pogo_z + 0.1], center = true);
        }
    }
}

// U-Shaped Retaining Collar added to the inside face of the frontplate wall (above Z = 0)
// Forms an internal U-border and backing flange that traps and supports the backplate tower on 3 sides
// NOTE: Sits strictly above Z = 0 so the backplate floor (Z <= 0) can seat completely flush into the frontplate skirt
module frontplate_tower_u_collar(is_left = false) {
    side = is_left ? -1 : 1;
    inner_x = side * (digit_width / 2 - 2.0); // Inside face of 2mm wall
    collar_thick = 2.0;                        // Inward extension into frontplate cavity
    collar_w = pogo_tower_w + lap_step_w * 2 + 5.0; // 39.0 mm total collar width along Y
    collar_h = total_depth;                    // Height above Z = 0 (13.0 mm)
    
    // Starts at Z = 0 and extends upward to total_depth
    translate([inner_x - side * collar_thick / 2, 0, collar_h / 2])
        cube([collar_thick, collar_w, collar_h], center = true);
}

// Stepped U-Notch & Retention Channel cutout subtracted from the frontplate side skirt & U-collar
module frontplate_tower_stepped_notch(is_left = false) {
    side = is_left ? -1 : 1;
    wall_x = side * digit_width / 2; // Outside face
    inner_x = side * (digit_width / 2 - 2.0); // Inside face
    
    // 1. Outer notch cutout (32.4mm wide along Y, 10.7mm high along Z)
    // Cuts outer 1mm of wall from Z = -backplate_thick to pogo_tower_h
    translate([wall_x - side * (2.0 - lap_step_d)/2 + side * 0.25, 0, (pogo_tower_h + tower_clearance - backplate_thick - 1.0)/2])
        cube([2.0 - lap_step_d + 0.6, pogo_tower_w + tower_clearance * 2, pogo_tower_h + tower_clearance + backplate_thick + 1.0], center = true);
        
    // 2. Inner stepped U-channel rebate cutout (34.4mm wide along Y, 11.7mm high along Z)
    // Cuts inner 1mm of wall from Z = -backplate_thick to pogo_tower_h + lap_step_w
    translate([inner_x + side * lap_step_d/2, 0, (pogo_tower_h + lap_step_w + tower_clearance - backplate_thick - 1.0)/2])
        cube([lap_step_d + 0.1, pogo_tower_w + lap_step_w * 2 + tower_clearance * 2, pogo_tower_h + lap_step_w + tower_clearance + backplate_thick + 1.0], center = true);

    // 3. Central boss & wiring clearance pocket through the inner collar (above Z = 0)
    // Leaves top retaining roof (Z = 11.7 to 13.0mm) and left/right retention rails (Y < -17.2, Y > +17.2mm)
    translate([inner_x - side * 1.5, 0, (pogo_tower_h + tower_clearance)/2])
        cube([3.5, 29.0, pogo_tower_h + tower_clearance + 0.1], center = true);

    // 4. Lead-in Chamfer on collar bottom edge at Z = 0 for smooth vertical mating
    translate([inner_x - side * 1.0, 0, 0.4])
        rotate([0, side * 45, 0])
            cube([1.2, pogo_tower_w + lap_step_w * 2 + 1.0, 1.2], center = true);
}

// Backplate Cable Retention Clips (fused directly to backplate floor at Z = 0)
module backplate_wire_clip(along_x = false) {
    clip_len = 6.0;    // Length along wire path (6.0mm)
    clip_w = 4.0;      // Width across clip (4.0mm)
    clip_h = 3.8;      // Height above backplate floor (3.8mm)
    wire_slot_w = 2.4; // Wire slot width
    
    rotate([0, 0, along_x ? 90 : 0]) {
        difference() {
            translate([0, 0, clip_h/2])
                cube([clip_w, clip_len, clip_h], center = true);
            // Wire retention U-channel with lead-in chamfer
            translate([0, 0, clip_h/2 + 0.5])
                cube([wire_slot_w, clip_len + 0.2, clip_h], center = true);
        }
    }
}

module backplate_perimeter_cable_holders() {
    // 1. Left inner wall run (X = -61.5mm, centered in 11mm perimeter channel): Upper and Lower runs
    for (y = [-70.0, -40.0, 40.0, 70.0]) {
        translate([-61.5, y, 0])
            backplate_wire_clip(along_x = false);
    }
    
    // 2. Right inner wall run (X = +61.5mm, centered in 11mm perimeter channel): Upper and Lower runs
    for (y = [-70.0, -40.0, 40.0, 70.0]) {
        translate([61.5, y, 0])
            backplate_wire_clip(along_x = false);
    }
    
    // 3. Top short side wall run (Y = +107.5mm, centered in 11mm perimeter channel above Seg A)
    for (x = [-45.0, -20.0, 20.0, 45.0]) {
        translate([x, 107.5, 0])
            backplate_wire_clip(along_x = true);
    }
    
    // 4. Bottom short side wall run (Y = -107.5mm, centered in 11mm perimeter channel below Seg D)
    for (x = [-45.0, -20.0, 20.0, 45.0]) {
        translate([x, -107.5, 0])
            backplate_wire_clip(along_x = true);
    }
}

// ==============================================================================
// Wireless Power Transfer (WPT) Receiver Pocket Modules (Panel 3)
// Accommodates:
// - Outer Ferromagnetic Ring: 57 mm OD, 46 mm ID, 1.0 mm thick
// - Rectangular Induction Coil: 33 mm x 42 mm, ~1.2 - 1.5 mm thick
// - Continuous 0.8 mm solid exterior rear skin for sealed, support-free print
// ==============================================================================
module wpt_interior_pocket(pos_y = wpt_pos_y) {
    pocket_bottom_z = -backplate_thick + wpt_floor_thick; // e.g. -5.5 + 0.8 = -4.7 mm
    pocket_h        = backplate_thick - wpt_floor_thick + 0.5; // reaches cleanly through Z = 0
    
    translate([0, pos_y, 0]) {
        // 1. Outer Ferromagnetic Ring Shelf (57.2mm OD, 45.8mm ID, 1.1mm deep)
        translate([0, 0, pocket_bottom_z]) {
            difference() {
                cylinder(h = wpt_ring_depth, r = wpt_ring_od / 2, $fn = 90);
                translate([0, 0, -0.1])
                    cylinder(h = wpt_ring_depth + 0.2, r = wpt_ring_id / 2, $fn = 80);
            }
        }
        
        // 2. Central Access Bore (matching ring ID 45.8mm, full height to Z = 0)
        translate([0, 0, pocket_bottom_z]) {
            cylinder(h = pocket_h, r = wpt_ring_id / 2, $fn = 80);
        }
        
        // 3. Rectangular Coil Cavity (34.0 x 43.0 mm, with 5mm corner fillets)
        translate([0, 0, pocket_bottom_z]) {
            linear_extrude(pocket_h) {
                offset(r = wpt_coil_corner_r, $fn = 32)
                    square([wpt_coil_w - wpt_coil_corner_r * 2, wpt_coil_l - wpt_coil_corner_r * 2], center = true);
            }
        }
        
        // 4. Wire Egress Trough: routes 2 coil leads southward toward center wire highway
        translate([0, -wpt_coil_l / 2 - 4.0, pocket_bottom_z + pocket_h / 2]) {
            cube([6.0, 10.0, pocket_h + 0.1], center = true);
        }
    }
}

// Subtle 0.2mm debossed target alignment guide on the outside rear face
module wpt_alignment_guide(pos_y = wpt_pos_y) {
    if (wpt_show_alignment_guide) {
        translate([0, pos_y, -backplate_thick - 0.05]) {
            // Concentric alignment circle (0.2mm deep into 0.8mm skin, leaves 0.6mm solid floor)
            difference() {
                cylinder(h = 0.25, r = (wpt_ring_od + wpt_ring_id) / 4 + 0.4, $fn = 80);
                translate([0, 0, -0.05])
                    cylinder(h = 0.35, r = (wpt_ring_od + wpt_ring_id) / 4 - 0.4, $fn = 80);
            }
            // Small center dot
            cylinder(h = 0.25, r = 1.2, $fn = 20);
        }
    }
}

// Optional standalone clip-in lid/retainer that can be 3D printed separately
module wpt_coil_retainer_lid() {
    lid_thick = 1.0;
    difference() {
        union() {
            // Main round lid body fitting ring ID
            cylinder(h = lid_thick, r = (wpt_ring_id / 2) - 0.2, $fn = 80);
            // Wing tabs fitting into rectangular coil pocket corners
            linear_extrude(lid_thick) {
                offset(r = wpt_coil_corner_r - 0.2, $fn = 32)
                    square([wpt_coil_w - 0.4 - (wpt_coil_corner_r - 0.2) * 2, 
                            wpt_coil_l - 0.4 - (wpt_coil_corner_r - 0.2) * 2], center = true);
            }
        }
        // Center finger pry hole & ventilation slot
        cylinder(h = lid_thick + 0.2, r = 5.0, center = true, $fn = 30);
        // Wire egress cutout
        translate([0, -wpt_coil_l / 2 + 2.0, 0])
            cube([6.5, 6.0, lid_thick + 0.2], center = true);
    }
}

// 3D hardware visual preview of metal ring and copper induction coil
module wpt_hardware_preview(pos_y = wpt_pos_y, alpha = 1.0) {
    pocket_bottom_z = -backplate_thick + wpt_floor_thick;
    translate([0, pos_y, 0]) {
        // Outer Ferromagnetic Ring
        color("Silver", alpha)
            translate([0, 0, pocket_bottom_z])
                difference() {
                    cylinder(h = 1.0, r = 57.0/2, $fn = 80);
                    translate([0, 0, -0.05])
                        cylinder(h = 1.1, r = 46.0/2, $fn = 70);
                }
        // Rectangular Copper Induction Coil
        color("DarkGoldenrod", alpha)
            translate([0, 0, pocket_bottom_z + 0.1])
                linear_extrude(1.2)
                    offset(r = 4.0, $fn = 32)
                        square([33.0 - 8.0, 42.0 - 8.0], center = true);
        // Dark Ferrite backing sheet
        color("#222222", alpha)
            translate([0, 0, pocket_bottom_z + 1.3])
                linear_extrude(0.3)
                    offset(r = 4.0, $fn = 32)
                        square([33.0 - 8.0, 42.0 - 8.0], center = true);
    }
}

// Visual 3D model of the 4-pin magnetic connector with mounting ears
module pogo_connector_model(is_male = true, alpha = 1.0) {
    color("#1e293b", alpha) { // Dark gray / black molded body
        // Central body
        cube([4.8, 14.6, 7.8], center=true);
        // Left & right mounting ears
        for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
            difference() {
                translate([0, y, 0])
                    hull() {
                        cube([2.0, 4.6, 7.6], center=true);
                        translate([0, (y > 0 ? 1 : -1) * 0.5, 0]) rotate([0, 90, 0]) cylinder(h=2.0, r=3.8, center=true, $fn=20);
                    }
                // Screw through-hole in ear
                translate([0, y, 0])
                    rotate([0, 90, 0])
                        cylinder(h=3.0, r=1.1, center=true, $fn=16);
            }
        }
    }
    // Silver alignment magnets on both sides of pins
    color("#cbd5e1", alpha) {
        for (my = [-5.2, 5.2]) {
            translate([1.5, my, 0]) rotate([0, 90, 0]) cylinder(h=2.0, r=1.5, center=true, $fn=20);
        }
    }
    // Gold contact pins
    color("#f59e0b", alpha) {
        for (i = [-1.5, -0.5, 0.5, 1.5]) {
            py = i * 2.54;
            if (is_male) {
                // Spring-loaded pogo pins protruding 1.2mm
                translate([2.8, py, 0]) rotate([0, 90, 0]) cylinder(h=1.6, r=0.5, center=true, $fn=12);
            } else {
                // Flat target contact pads
                translate([2.4, py, 0]) rotate([0, 90, 0]) cylinder(h=0.4, r=0.8, center=true, $fn=12);
            }
            // Solder pins extending inward
            translate([-3.4, py, 0]) rotate([0, 90, 0]) cylinder(h=2.5, r=0.4, center=true, $fn=12);
        }
    }
}

// --- Modular Lightguide Snap-Fit Support Modules ---

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
                        // Pocket detent cutout extending cleanly into the channel void to avoid coplanar faces
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

// Cutout for the miter corners of a single segment (from Z = 0 to cut_h)
// Stops precisely at (l/2 - w/2) where the angled lines meet the straight/vertical channel walls
module single_segment_corner_cutout(l, w, cut_h = connector_corner_relief_h) {
    if (cut_h > 0) {
        base_x = l/2 - w/2;
        base_y = (w + 4)/2 + 0.05;
        tip_x = base_x + base_y; // exact 45-degree angle matching segment miter
        
        translate([0, 0, -0.1])
        linear_extrude(height = cut_h + 0.1) {
            // Positive end (+X)
            polygon([
                [base_x, -base_y],
                [tip_x, 0],
                [base_x, base_y]
            ]);
            // Negative end (-X)
            polygon([
                [-base_x, -base_y],
                [-tip_x, 0],
                [-base_x, base_y]
            ]);
        }
    }
}

// Relief cutouts applied strictly to the miter corners of each of the 7 segments
module all_segments_corner_cutouts(cut_h = connector_corner_relief_h) {
    layout_horiz(false, false) single_segment_corner_cutout(total_seg_l_x, total_seg_w, cut_h);
    layout_horiz(true, false) single_segment_corner_cutout(total_seg_l_x, total_seg_w, cut_h);
    layout_horiz(false, true) single_segment_corner_cutout(total_seg_l_x, total_seg_w, cut_h);
    layout_vert(true) single_segment_corner_cutout(total_seg_l_y_top, total_seg_w, cut_h);
    layout_vert(false) single_segment_corner_cutout(total_seg_l_y_bot, total_seg_w, cut_h);
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
                
            // 3. Corner screw posts for backplate (flush with Z = 0 interface)
            for (x = [digit_width/2 - 6, -digit_width/2 + 6]) {
                for (y = [(pitch_y_top - pitch_y_bot)/2 + digit_height/2 - 6, (pitch_y_top - pitch_y_bot)/2 - digit_height/2 + 6]) {
                    translate([x, y, 0]) cylinder(h=total_depth, r=4, $fn=20);
                }
            }
            
            // 4. Center VESA 50x50 mm screw posts (flush with Z = 0 interface)
            for (x = [-25, 25]) {
                for (y = [-25, 25]) {
                    translate([x, y, 0]) cylinder(h=total_depth, r=4.5, $fn=24);
                }
            }
            
            // 5. U-shape retention collars / borders around connector towers
            frontplate_tower_u_collar(is_left = true);
            if (panel_id < 4) {
                frontplate_tower_u_collar(is_left = false);
            }
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

        // Corner screw holes for backplate to mount (M3 heat-set inserts, 4.2mm diameter)
        for (x = [digit_width/2 - 6, -digit_width/2 + 6]) {
            for (y = [(pitch_y_top - pitch_y_bot)/2 + digit_height/2 - 6, (pitch_y_top - pitch_y_bot)/2 - digit_height/2 + 6]) {
                translate([x, y, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
            }
        }
        
        // Center VESA 50x50 mm screw holes (M3 heat-set inserts, 4.2mm diameter)
        for (x = [-25, 25]) {
            for (y = [-25, 25]) {
                translate([x, y, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
            }
        }
        
        // Left Wall: Stepped U-Notch mating over the backplate connector tower (USB on P1, Pogo on P2/3/4)
        frontplate_tower_stepped_notch(is_left = true);
        
        // Right Wall: Stepped U-Notch mating over the backplate connector tower (Panels 1, 2, 3; Panel 4 is solid)
        if (panel_id < 4) {
            frontplate_tower_stepped_notch(is_left = false);
        }
        
        // Cut 2mm from the bottom of segment corners, stopping where walls become straight/vertical
        all_segments_corner_cutouts(cut_h = connector_corner_relief_h);
    }
}

module frontplate_white() {
    if (enable_lightguide_snap_locks) {
        modular_7segment_assembled(diffuser_thick);
    } else {
        // Unified 2-color multi-material diffuser cup
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
                
            // Solid reinforcing pads under VESA mount holes (running full depth through plate to Z = 0)
            for (x = [-25, 25]) {
                for (y = [-25, 25]) {
                    translate([x, y, -backplate_thick]) cylinder(h = backplate_thick, r = 5.0, $fn = 30);
                }
            }
            
            // ESP32 Mini snap-fit locking cradle & RTC Mount (only on panel 1)
            if (panel_id == 1) {
                translate([0, -50, 0])
                    esp32_cradle();
                    
                // MH-Real-Time-Clock-2 (DS1302) Module Mount with 4 screw bosses (at Y = +50)
                translate([0, 50, 0])
                    rtc_ds1302_mount();
            }
            
            // Left Connector Tower (USB-C on Panel 1, Female Pogo on Panels 2, 3, 4)
            if (panel_id == 1) {
                backplate_connector_tower(is_left = true, is_usb = true);
            } else if (panel_id > 1) {
                backplate_connector_tower(is_left = true, is_usb = false);
            }
            
            // Right Connector Tower (Male Pogo on Panels 1, 2, 3; Panel 4 is solid end)
            if (panel_id < 4) {
                backplate_connector_tower(is_left = false, is_usb = false);
            }
            
            // Integrated Backplate Cable Retention Clips
            backplate_perimeter_cable_holders();

            // WPT wire guide clip on Panel 3
            if (panel_id == 3 && enable_wireless_power) {
                translate([0, wpt_pos_y - 28.0, 0])
                    backplate_wire_clip(along_x = false);
            }
        }
            
        // Recesses for all 7 LED strip channels (2mm deep from Z = 0, enlarged 10% to 13.2mm width)
        // 1. Top Horizontal (Seg A): Y = +94
        translate([0, pitch_y_top, -strip_recess_depth/2])
            cube([pitch_x, strip_channel_width, strip_recess_depth + 0.1], center=true);

        // 2. Middle Horizontal (Seg G): Y = 0
        translate([0, 0, -strip_recess_depth/2])
            cube([pitch_x, strip_channel_width, strip_recess_depth + 0.1], center=true);

        // 3. Bottom Horizontal (Seg D): Y = -94
        translate([0, -pitch_y_bot, -strip_recess_depth/2])
            cube([pitch_x, strip_channel_width, strip_recess_depth + 0.1], center=true);

        // 4. Top-Left Vertical (Seg F): X = -47
        translate([-pitch_x/2, pitch_y_top/2, -strip_recess_depth/2])
            cube([strip_channel_width, pitch_y_top, strip_recess_depth + 0.1], center=true);

        // 5. Top-Right Vertical (Seg B): X = +47
        translate([pitch_x/2, pitch_y_top/2, -strip_recess_depth/2])
            cube([strip_channel_width, pitch_y_top, strip_recess_depth + 0.1], center=true);

        // 6. Bottom-Left Vertical (Seg E): X = -47
        translate([-pitch_x/2, -pitch_y_bot/2, -strip_recess_depth/2])
            cube([strip_channel_width, pitch_y_bot, strip_recess_depth + 0.1], center=true);

        // 7. Bottom-Right Vertical (Seg C): X = +47
        translate([pitch_x/2, -pitch_y_bot/2, -strip_recess_depth/2])
            cube([strip_channel_width, pitch_y_bot, strip_recess_depth + 0.1], center=true);
            
        // Direct Sub-Floor Wire Pass-Through Channels (Connectors to LED Strips, stays inside inner wall)
        // 1. Direct Left Connector to Mid-Left Junction Trough (stops at X = -67.0mm, leaving 2.4mm solid outer wall)
        translate([-56.0, 0, -strip_recess_depth/2 + 0.05])
            cube([22.0, 10.0, strip_recess_depth + 0.1], center = true);

        // 2. Direct Right Connector to Mid-Right Junction Trough (stops at X = +67.0mm, leaving 2.4mm solid outer wall)
        translate([56.0, 0, -strip_recess_depth/2 + 0.05])
            cube([22.0, 10.0, strip_recess_depth + 0.1], center = true);

        // 3. Perimeter Sub-Floor Wire Highways (routing DI/DO and BI/BO along left and right flanks)
        // Left Highway (X = -58.0mm, spanning Y = -92 to +92)
        translate([-58.0, 0, -strip_recess_depth/2 + 0.05])
            cube([6.0, pitch_y_top + pitch_y_bot + 20.0, strip_recess_depth + 0.1], center = true);

        // Right Highway (X = +58.0mm, spanning Y = -92 to +92)
        translate([58.0, 0, -strip_recess_depth/2 + 0.05])
            cube([6.0, pitch_y_top + pitch_y_bot + 20.0, strip_recess_depth + 0.1], center = true);
            
        // Cable routing channels (panel 1 only):
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
                
                // Top left & right (enlarged horizontally to 35.5 mm to create 50 mm horizontal strip channel)
                translate([-pitch_x/2, pitch_y_top, 0]) translate([-13.5, 13.5 - corner_pocket_h, 0]) cube([corner_pocket_w, corner_pocket_h, connector_thick + 0.1]);
                translate([pitch_x/2, pitch_y_top, 0]) translate([13.5 - corner_pocket_w, 13.5 - corner_pocket_h, 0]) cube([corner_pocket_w, corner_pocket_h, connector_thick + 0.1]);
                
                // Bottom left & right (enlarged horizontally to 35.5 mm to create 50 mm horizontal strip channel)
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
            
        // 1. Corner mounting screw holes (M3 clearance, 3.2mm) with countersink for flush heads
        for (x = [digit_width/2 - 6, -digit_width/2 + 6]) {
            for (y = [(pitch_y_top - pitch_y_bot)/2 + digit_height/2 - 6, (pitch_y_top - pitch_y_bot)/2 - digit_height/2 + 6]) {
                translate([x, y, -backplate_thick - 0.1]) {
                    cylinder(h=backplate_thick + 0.2, r=1.6, $fn=20);       // Main shaft
                    cylinder(h=1.6, r1=3.2, r2=1.6, $fn=20);                // 90-degree countersink cone
                }
            }
        }
        
        // 2. Center VESA 50x50 mm mounting holes (M3 clearance, 3.2mm) with punch-out thin cover
        // Features a 0.4mm punchable membrane so the backplate is 100% solid by default, but easily punched when needed
        for (x = [-25, 25]) {
            for (y = [-25, 25]) {
                // Internal clearance borehole & countersink starting behind 0.4mm thin skin
                translate([x, y, -backplate_thick + 0.4]) {
                    cylinder(h = backplate_thick - 0.4 + 0.1, r = 1.6, $fn = 20);       // Main shaft clearance
                    cylinder(h = 1.6, r1 = 3.2, r2 = 1.6, $fn = 20);                    // Flush countersink cone
                }
                
                // Debossed visual target guide ring on outside face (0.2mm deep, leaves 0.2mm knockout perforation)
                translate([x, y, -backplate_thick - 0.05])
                    difference() {
                        cylinder(h = 0.25, r = 2.5, $fn = 24);
                        translate([0, 0, -0.05]) cylinder(h = 0.35, r = 2.1, $fn = 24);
                    }
            }
        }

        // Orientation indicator debossed into the top of the backplate
        translate([0, 95, -backplate_thick - 0.1])
            linear_extrude(1.0)
                mirror([1, 0, 0])
                    text("↑ TOP", size=6, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    
        // Panel ID debossed into the center of the VESA mount
        translate([0, 0, -backplate_thick - 0.1])
            linear_extrude(1.0)
                mirror([1, 0, 0])
                    text(str(panel_id), size=15, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    
        // Pogo-edition model label & copyright debossed into outside face
        translate([0, -100, -backplate_thick - 0.1])
            linear_extrude(1.0)
                mirror([1, 0, 0])
                    text("© GSC • POGO EDITION", size=3.8, font="Liberation Sans:style=Bold", halign="center", valign="center");

        // Wireless Power Transfer (WPT) Receiver Pocket (Panel 3 only)
        if (panel_id == 3 && enable_wireless_power) {
            wpt_interior_pocket(wpt_pos_y);
            wpt_alignment_guide(wpt_pos_y);
        }
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

module pogo_connectors_preview(panel_id = panel_id, alpha = alpha_pogo_hardware, exp_x = 0) {
    if (panel_id < 4) {
        // Right-facing pogo connector (male pogo pins facing outward toward next panel)
        translate([digit_width/2 - pogo_boss_depth + 1.0 + exp_x, 0, pogo_z])
            pogo_connector_model(is_male = true, alpha = alpha);
    }
    if (panel_id > 1) {
        // Left-facing pogo connector (female flat pads facing outward toward previous panel)
        translate([-digit_width/2 + pogo_boss_depth - 1.0 - exp_x, 0, pogo_z])
            rotate([0, 180, 0])
                pogo_connector_model(is_male = false, alpha = alpha);
    }
}

// --- Render Assembly & Inspection Logic ---
module render_7segment_assembly() {
    if (part_sel == 1 || render_part == "backplate_only") {
        backplate(panel_id = panel_id);
    } else if (part_sel == 2 || render_part == "frontplate_black") {
        frontplate_black(panel_id = panel_id);
    } else if (part_sel == 3 || render_part == "frontplate_white") {
        frontplate_white();
    } else if (part_sel == 4 || render_part == "wpt_lid_only") {
        wpt_coil_retainer_lid();
    } else if (inspection_mode == "collision_check") {
        // 1. Interference between Black Housing and Backplate
        show_collision() {
            frontplate_black(panel_id = panel_id);
            backplate(panel_id = panel_id);
        }
        // 2. Interference between Black Housing and White Diffusers
        show_collision() {
            frontplate_black(panel_id = panel_id);
            frontplate_white();
        }
    } else if (inspection_mode == "clearance_check") {
        // Check minimum gap between Backplate and Black Frontplate
        check_clearance(gap = clearance_gap) {
            backplate(panel_id = panel_id);
            frontplate_black(panel_id = panel_id);
        }
    } else if (inspection_mode == "cutaway_x") {
        cutaway(axis = "x", cut_depth = cutaway_depth) {
            if (show_frontplate_black) color("DimGray", alpha_frontplate_black) frontplate_black(panel_id = panel_id);
            if (show_frontplate_white) color("White", alpha_frontplate_white) frontplate_white();
            if (show_backplate) color("SlateGray", alpha_backplate) backplate(panel_id = panel_id);
            if (show_pogo_hardware) pogo_connectors_preview(panel_id, alpha = alpha_pogo_hardware);
            if (panel_id == 3 && enable_wireless_power && show_wpt_hardware) wpt_hardware_preview(wpt_pos_y, alpha = alpha_wpt_hardware);
        }
    } else if (inspection_mode == "cutaway_y") {
        cutaway(axis = "y", cut_depth = cutaway_depth) {
            if (show_frontplate_black) color("DimGray", alpha_frontplate_black) frontplate_black(panel_id = panel_id);
            if (show_frontplate_white) color("White", alpha_frontplate_white) frontplate_white();
            if (show_backplate) color("SlateGray", alpha_backplate) backplate(panel_id = panel_id);
            if (show_pogo_hardware) pogo_connectors_preview(panel_id, alpha = alpha_pogo_hardware);
            if (panel_id == 3 && enable_wireless_power && show_wpt_hardware) wpt_hardware_preview(wpt_pos_y, alpha = alpha_wpt_hardware);
        }
    } else if (inspection_mode == "slice_z") {
        slice_2d(cut_z = pogo_z) {
            frontplate_black(panel_id = panel_id);
            backplate(panel_id = panel_id);
        }
    } else {
        // Assembled or Exploded View
        is_exp = (inspection_mode == "exploded") || (exploded_view && inspection_mode != "assembled");
        exp_white_z = is_exp ? explode_distance * 1.0 : 0;
        exp_black_z = 0;
        exp_back_z  = is_exp ? -explode_distance * 1.0 : 0;
        exp_pogo_x  = is_exp ? explode_distance * 0.8 : 0;

        if (show_frontplate_black) 
            translate([0, 0, exp_black_z]) 
                color("DimGray", alpha_frontplate_black) 
                    frontplate_black(panel_id = panel_id);

        if (show_frontplate_white) 
            translate([0, 0, exp_white_z]) 
                color("White", alpha_frontplate_white) 
                    frontplate_white();

        if (show_backplate) 
            translate([0, 0, exp_back_z]) 
                color("SlateGray", alpha_backplate) 
                    backplate(panel_id = panel_id);

        if (panel_id == 3 && enable_wireless_power && show_wpt_hardware) {
            translate([0, 0, exp_back_z])
                wpt_hardware_preview(wpt_pos_y, alpha = alpha_wpt_hardware);
        }

        if (show_pogo_hardware) {
            pogo_connectors_preview(panel_id, alpha = alpha_pogo_hardware, exp_x = exp_pogo_x);
        }
    }
}

render_7segment_assembly();
