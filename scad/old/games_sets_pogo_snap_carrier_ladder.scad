// ==============================================================================
// Games & Sets Indicator Module with Snap Carrier Ladder (Pogo Pin Edition)
// File: "games_sets_pogo_snap_carrier_ladder.scad"
//
// Fits between digits on a Padel Scoreboard (e.g. between Team 1 and Team 2 digits).
//
// Features:
// 1. Unified Snap Carrier Ladder: All 22 diffuser dots (11 Team 1 + 11 Team 2)
//    are integrated into a single rigid structural ladder with cantilever snap-lock
//    tabs that click securely into matching detents in the black frontplate housing.
// 2. Monolithic Backplate Connector Towers with solid base floor footing.
// 3. Frontplate U-Shaped Retaining Collars (Z >= 0) and stepped lap-joint light traps.
// 4. Outside-mount 4-pin magnetic pogo connectors on left and right walls.
// ==============================================================================

/* [Display Configuration] */
spacer_width = 56.0;         // Width of the indicator module in mm
col_spacing  = 22.0;         // Center-to-center distance between Team 1 and Team 2 columns (+/- 11mm)
show_pogo_hardware = true;   // Preview 3D pogo connectors in mounting pockets

/* [Inspection & Quality Control] */
inspection_mode       = "assembled"; // ["assembled": Fully Assembled View, "exploded": Exploded Layer View, "carrier_only": White Snap Carrier Ladder Only, "frontplate_only": Black Frontplate Only, "backplate_only": Rear Backplate Only, "collision_check": Interference Check, "cutaway_x": Cutaway Cross-Section (X-Axis), "cutaway_y": Cutaway Cross-Section (Y-Axis)]
cutaway_depth         = 0.0;  // [-100:1:100] Offset along cut axis for cutaway view (mm)

/* [Visibility & Exploded View] */
show_frontplate_black = true; // Black structural housing & light-isolation wells
show_frontplate_white = true; // White Snap Carrier Ladder diffusers
show_backplate        = true; // Rear backplate with LED channels & screw holes
exploded_view         = false;// Set to true to view all layers exploded along Z
explode_distance      = 35.0; // Distance between exploded layers in mm

use <assembly_inspector.scad>

/* [Transparency / Opacity] */
alpha_frontplate_black = 1.0; // [0.0:0.05:1.0]
alpha_frontplate_white = 1.0; // [0.0:0.05:1.0]
alpha_backplate        = 1.0; // [0.0:0.05:1.0]
alpha_pogo_hardware    = 1.0; // [0.0:0.05:1.0]

/* [System Dimensions matching 7segment_pogo.scad] */
pitch_x = 92.0;               
pitch_y_top = 92.0;           
pitch_y_bot = 92.0;           
strip_width = 12.0;          
white_wall = 1.2;            
margin_y = 15.0;             

tunnel_depth = 12.4;         
diffuser_thick = 0.6;        
total_depth = 13.0;          // Total frontplate housing depth (13.0 mm)

backplate_floor = 1.5;       
connector_thick = 4.0;       
backplate_thick = connector_thick + backplate_floor; // 5.5 mm
strip_recess_depth = 2.0;    

diffuser_w = strip_width + 2.0;      
total_seg_w = diffuser_w + white_wall * 2.0; // 16.4 mm
digit_height = pitch_y_top + pitch_y_bot + total_seg_w + margin_y * 2.0; // 230.4 mm

/* [LED Strip Configuration - Standard 60 LEDs/m Strip] */
led_pitch = 1000.0 / 60.0;   // 16.667 mm pitch

set_dot_radius   = 4.5;      // Radius for Sets indicators (top 2 LEDs)
game_dot_radius  = 4.5;      // Radius for Games indicators (lower 9 LEDs)

led_y_base = - (11 * led_pitch) / 2; // -91.667 mm

game_y_positions = [ for (i = [0 : 8]) led_y_base + i * led_pitch ];   // 9 Game LEDs (-91.67 to +41.67mm)
blank_y_position = led_y_base + 9 * led_pitch;                         // +58.33 mm (Blank spacer gap)
set_y_positions  = [ for (i = [10 : 11]) led_y_base + i * led_pitch ]; // 2 Set LEDs (+75.00 & +91.67mm)

all_dot_y_positions = concat(game_y_positions, set_y_positions);       // All 11 active dot Y positions

/* [Snap-Lock Carrier Ladder Parameters] */
enable_snap_locks   = true;  // Enable cantilever snap tabs & detents
snap_tooth_reach    = 0.55;  // Outward locking overhang depth
snap_tooth_w        = 3.5;   // Width of snap tooth along Y
snap_tooth_h        = 2.2;   // Height of snap tooth along Z
snap_z_pos          = 3.5;   // Z height of snap lock engagement
ladder_spine_thick  = 1.4;   // Thickness of structural bridge rungs between columns
ladder_clearance    = 0.15;  // Perimeter clearance for smooth drop-in snap fit

/* [4-Pin Magnetic Pogo Pin Connector Parameters] */
pogo_ear_span       = 23.9;  
pogo_ear_pitch      = 20.0;  
pogo_hole_d         = 1.8;   
pogo_hole_depth     = 7.0;   
pogo_body_w         = 18.0;  
pogo_body_h         = 4.4;   
pogo_body_r         = 2.2;   
pogo_boss_depth     = 3.0;   
pogo_boss_r         = 3.0;   
pogo_pass_depth     = 10.0;  
pogo_z              = 6.0;   

// --- Backplate Connector Tower & Stepped Lap-Joint Parameters ---
pogo_tower_w        = 32.0; 
pogo_tower_h        = 10.5; 
lap_step_w          = 1.0;  
lap_step_d          = 1.0;  
tower_clearance     = 0.2;  

$fn = 32;

// -------------------------------------------------------------
// Helper Modules
// -------------------------------------------------------------

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
module games_sets_backplate_connector_tower(is_left = false) {
    side = is_left ? -1 : 1;
    wall_x = side * spacer_width / 2; // Outside face (0.0mm reference)
    inner_x = side * (spacer_width / 2 - 2.0); // Inside face of 2mm wall
    boss_face_x = wall_x - side * pogo_boss_depth; // Seating plane: -3.0mm from outside
    boss_len = 6.0; // Inward boss extension
    
    difference() {
        union() {
            // 1. Outer Wall Section (from wall_x to outer shelf step)
            translate([wall_x - side * (2.0 - lap_step_d)/2, 0, (pogo_tower_h - backplate_thick)/2])
                cube([2.0 - lap_step_d, pogo_tower_w, pogo_tower_h + backplate_thick], center = true);
                
            // 2. Inner Stepped Tongue / Backing Flange (Lap Joint Overlap)
            translate([inner_x + side * lap_step_d/2, 0, (pogo_tower_h + lap_step_w - backplate_thick)/2])
                cube([lap_step_d, pogo_tower_w + lap_step_w * 2, pogo_tower_h + lap_step_w + backplate_thick], center = true);
                
            // 3. Reinforced Solid Screw Bosses & Downward Web Anchors
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
            
            // 4. Solid Monolithic Base Floor Footing
            // Fills the floor from Z = -backplate_thick to Z = 0 under the tower and fuses it directly into the backplate
            translate([(wall_x + (inner_x - side * 4.0))/2, 0, -backplate_thick/2])
                cube([abs(wall_x - (inner_x - side * 4.0)), pogo_tower_w, backplate_thick], center = true);
        }
        
        // --- SUBTRACTIONS ---
        // 1. Full Outside-Mount Stadium Pocket (23.9 x 4.4 mm, 3.0mm deep from outside)
        translate([wall_x - side * (pogo_boss_depth / 2 - 0.05), 0, pogo_z])
            rotate([0, 90, 0])
                rounded_stadium_slot(depth = pogo_boss_depth + 0.1, length_y = pogo_ear_span, height_z = pogo_body_h, center = true);
            
        // 2. Central Body Through-Opening (18.0 x 4.4 mm) passing into interior
        translate([wall_x - side * (3.0 + 3.0), 0, pogo_z])
            rotate([0, 90, 0])
                rounded_stadium_slot(depth = 8.0, length_y = pogo_body_w, height_z = pogo_body_h, center = true);
            
        // 3. 2x Screw Pilot Holes drilled into bosses from boss_face_x
        for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
            translate([boss_face_x + side * 0.5, y, pogo_z])
                rotate([0, -side * 90, 0])
                    cylinder(h = pogo_hole_depth + 1.0, r = pogo_hole_d / 2, $fn = 20);
        }
        
        // 4. Sense Resistor Stash Pocket (5.0 x 3.5 x 2.5 mm cavity)
        translate([inner_x - side * 4.0, side * 8.0, 2.0])
            cube([5.0, 3.5, 3.0], center = true);
            
        // 5. Downward Wire Drop Chute (stays safely inside inner wall)
        translate([inner_x - side * 3.5, 0, pogo_z / 2])
            cube([5.0, 12.0, pogo_z + 0.1], center = true);
    }
}

// U-Shaped Retaining Collar added to the inside face of the frontplate wall (above Z = 0)
module games_sets_frontplate_tower_u_collar(is_left = false) {
    side = is_left ? -1 : 1;
    inner_x = side * (spacer_width / 2 - 2.0); // Inside face of 2mm wall
    collar_thick = 2.0;                         // Inward extension into frontplate cavity
    collar_w = pogo_tower_w + lap_step_w * 2 + 5.0; // 39.0 mm total collar width along Y
    collar_h = total_depth;                     // Height above Z = 0 (13.0 mm)
    
    translate([inner_x - side * collar_thick / 2, 0, collar_h / 2])
        cube([collar_thick, collar_w, collar_h], center = true);
}

// Stepped U-Notch & Retention Channel cutout subtracted from the frontplate side skirt & U-collar
module games_sets_frontplate_stepped_notch(is_left = false) {
    side = is_left ? -1 : 1;
    wall_x = side * spacer_width / 2; // Outside face
    inner_x = side * (spacer_width / 2 - 2.0); // Inside face
    
    // 1. Outer notch cutout (32.4mm wide along Y, 10.7mm high along Z)
    translate([wall_x - side * (2.0 - lap_step_d)/2 + side * 0.25, 0, (pogo_tower_h + tower_clearance - backplate_thick - 1.0)/2])
        cube([2.0 - lap_step_d + 0.6, pogo_tower_w + tower_clearance * 2, pogo_tower_h + tower_clearance + backplate_thick + 1.0], center = true);
        
    // 2. Inner stepped U-channel rebate cutout (34.4mm wide along Y, 11.7mm high along Z)
    translate([inner_x + side * lap_step_d/2, 0, (pogo_tower_h + lap_step_w + tower_clearance - backplate_thick - 1.0)/2])
        cube([lap_step_d + 0.1, pogo_tower_w + lap_step_w * 2 + tower_clearance * 2, pogo_tower_h + lap_step_w + tower_clearance + backplate_thick + 1.0], center = true);

    // 3. Central boss & wiring clearance pocket through the inner collar (above Z = 0)
    translate([inner_x - side * 1.5, 0, (pogo_tower_h + tower_clearance)/2])
        cube([3.5, 29.0, pogo_tower_h + tower_clearance + 0.1], center = true);

    // 4. Lead-in Chamfer on collar bottom edge at Z = 0 for smooth vertical mating
    translate([inner_x - side * 1.0, 0, 0.4])
        rotate([0, side * 45, 0])
            cube([1.2, pogo_tower_w + lap_step_w * 2 + 1.0, 1.2], center = true);
}

// -------------------------------------------------------------
// Snap-Lock Tabs & Detents for the Snap Carrier Ladder
// -------------------------------------------------------------

// Snap tab positions along Y on the outer and center flanks of the carrier ladder
snap_y_positions = [
    set_y_positions[1],        // Top Set dot (+91.67mm)
    blank_y_position,          // Middle spacer rung (+58.33mm)
    game_y_positions[4],       // Middle Game dot (-25.00mm)
    game_y_positions[0]        // Bottom Game dot (-91.67mm)
];

module ladder_snap_teeth(is_subtraction = false) {
    if (enable_snap_locks) {
        reach = is_subtraction ? (snap_tooth_reach + 0.2) : snap_tooth_reach;
        w = is_subtraction ? (snap_tooth_w + 0.4) : snap_tooth_w;
        h = is_subtraction ? (snap_tooth_h + 0.4) : snap_tooth_h;
        
        for (y = snap_y_positions) {
            // Left outer flank (X = -col_spacing/2 - (game_dot_radius + white_wall))
            translate([-col_spacing/2 - (game_dot_radius + white_wall), y, snap_z_pos]) {
                if (is_subtraction) {
                    cube([reach * 2 + 0.2, w, h], center = true);
                } else {
                    rotate([0, 180, 0])
                        linear_extrude(w, center = true)
                            polygon([
                                [0, -h/2],
                                [reach, -h/4],
                                [reach, h/4],
                                [0, h/2]
                            ]);
                }
            }
            
            // Right outer flank (X = +col_spacing/2 + (game_dot_radius + white_wall))
            translate([col_spacing/2 + (game_dot_radius + white_wall), y, snap_z_pos]) {
                if (is_subtraction) {
                    cube([reach * 2 + 0.2, w, h], center = true);
                } else {
                    linear_extrude(w, center = true)
                        polygon([
                            [0, -h/2],
                            [reach, -h/4],
                            [reach, h/4],
                            [0, h/2]
                        ]);
                }
            }
        }
    }
}

// Compliance flex slits in the ladder walls behind each snap tooth for easy elasticity
module ladder_flex_slits() {
    if (enable_snap_locks) {
        slit_w = 0.8;
        slit_l = 3.5;
        slit_h = 6.0;
        
        for (y = snap_y_positions) {
            for (dy = [-2.2, 2.2]) {
                // Left column flex slits
                translate([-col_spacing/2 - (game_dot_radius + white_wall), y + dy, slit_h/2 - 0.1])
                    cube([slit_l, slit_w, slit_h + 0.2], center = true);
                // Right column flex slits
                translate([col_spacing/2 + (game_dot_radius + white_wall), y + dy, slit_h/2 - 0.1])
                    cube([slit_l, slit_w, slit_h + 0.2], center = true);
            }
        }
    }
}

// -------------------------------------------------------------
// Component: Unified 22-Dot Snap Carrier Ladder (White Diffusers)
// -------------------------------------------------------------
module games_sets_snap_carrier_ladder() {
    difference() {
        union() {
            // 1. The 22 White Reflector/Diffuser Cylinders (11 Team 1 + 11 Team 2)
            for (col = [-col_spacing/2, col_spacing/2]) {
                // Sets cylinders
                for (y = set_y_positions) {
                    translate([col, y, 0])
                        cylinder(h = total_depth, r = set_dot_radius + white_wall - ladder_clearance, $fn = 32);
                }
                // Games cylinders
                for (y = game_y_positions) {
                    translate([col, y, 0])
                        cylinder(h = total_depth, r = game_dot_radius + white_wall - ladder_clearance, $fn = 32);
                }
            }
            
            // 2. Vertical Column Spine Runners (connects the 11 dots in each column as a continuous spine)
            for (col = [-col_spacing/2, col_spacing/2]) {
                // Lower Games spine (from Y = -91.67 to +41.67)
                translate([col, (game_y_positions[0] + game_y_positions[8])/2, ladder_spine_thick/2])
                    cube([game_dot_radius * 2, game_y_positions[8] - game_y_positions[0], ladder_spine_thick], center = true);
                    
                // Upper Sets spine (from Y = +75.00 to +91.67)
                translate([col, (set_y_positions[0] + set_y_positions[1])/2, ladder_spine_thick/2])
                    cube([set_dot_radius * 2, set_y_positions[1] - set_y_positions[0], ladder_spine_thick], center = true);
            }
            
            // 3. Horizontal Cross-Rungs (Bridges Team 1 and Team 2 into a single unified rigid ladder)
            // Rung A: Top Sets Bridge (Y = +83.33mm)
            translate([0, (set_y_positions[0] + set_y_positions[1])/2, ladder_spine_thick/2])
                cube([col_spacing, 6.0, ladder_spine_thick], center = true);
                
            // Rung B: Mid Spacer Gap Bridge (Y = +58.33mm - blank spacer location)
            translate([0, blank_y_position, ladder_spine_thick/2])
                cube([col_spacing, 10.0, ladder_spine_thick], center = true);
                
            // Rung C: Center Games Bridge (Y = -25.00mm)
            translate([0, game_y_positions[4], ladder_spine_thick/2])
                cube([col_spacing, 6.0, ladder_spine_thick], center = true);
                
            // Rung D: Bottom Games Bridge (Y = -91.67mm)
            translate([0, game_y_positions[0], ladder_spine_thick/2])
                cube([col_spacing, 6.0, ladder_spine_thick], center = true);
                
            // 4. Cantilever Snap Teeth along the outer sides
            ladder_snap_teeth(is_subtraction = false);
        }
        
        // --- SUBTRACTIONS FROM WHITE CARRIER ---
        // Hollow internal light chambers (leaves 0.6mm solid white front diffuser face)
        for (col = [-col_spacing/2, col_spacing/2]) {
            for (y = set_y_positions) {
                translate([col, y, -0.1])
                    cylinder(h = tunnel_depth + 0.1, r = set_dot_radius, $fn = 32);
            }
            for (y = game_y_positions) {
                translate([col, y, -0.1])
                    cylinder(h = tunnel_depth + 0.1, r = game_dot_radius, $fn = 32);
            }
        }
        
        // Elastic flex slits behind snap teeth
        ladder_flex_slits();
    }
}

// -------------------------------------------------------------
// Component: Black Frontplate Housing
// -------------------------------------------------------------
module games_sets_frontplate_black() {
    difference() {
        union() {
            // 1. Main outer shell frame (-backplate_thick to total_depth)
            difference() {
                translate([-spacer_width/2, -digit_height/2, -backplate_thick])
                    cube([spacer_width, digit_height, total_depth + backplate_thick]);
                translate([-spacer_width/2 + 2.0, -digit_height/2 + 2.0, -backplate_thick - 0.1])
                    cube([spacer_width - 4.0, digit_height - 4.0, total_depth + backplate_thick - 1.2 + 0.1]);
            }
            
            // 2. Light-isolation cylindrical collars around every LED indicator
            for (col = [-col_spacing/2, col_spacing/2]) {
                for (y = set_y_positions) {
                    translate([col, y, 0])
                        cylinder(h = total_depth, r = set_dot_radius + white_wall + 1.2, $fn = 32);
                }
                for (y = game_y_positions) {
                    translate([col, y, 0])
                        cylinder(h = total_depth, r = game_dot_radius + white_wall + 1.2, $fn = 32);
                }
            }
            
            // 3. Corner backplate screw bosses
            for (x = [spacer_width/2 - 6, -spacer_width/2 + 6]) {
                for (y = [digit_height/2 - 6, -digit_height/2 + 6]) {
                    translate([x, y, 0]) cylinder(h = total_depth - 1.2, r = 4.2, $fn = 20);
                }
            }
            
            // 4. U-shape retention collars around left and right connector towers (above Z = 0)
            games_sets_frontplate_tower_u_collar(is_left = true);
            games_sets_frontplate_tower_u_collar(is_left = false);
        }
        
        // --- SUBTRACTIONS ---
        
        // Boreholes for white snap carrier ladder lightguides (Sets + Games)
        for (col = [-col_spacing/2, col_spacing/2]) {
            for (y = set_y_positions) {
                translate([col, y, -1.0])
                    cylinder(h = total_depth + 2.0, r = set_dot_radius + white_wall, $fn = 32);
            }
            for (y = game_y_positions) {
                translate([col, y, -1.0])
                    cylinder(h = total_depth + 2.0, r = game_dot_radius + white_wall, $fn = 32);
            }
        }
        
        // Snap detent pockets for the Snap Carrier Ladder
        ladder_snap_teeth(is_subtraction = true);
        
        // Backplate M3 screw pilot holes (heat-set inserts)
        for (x = [spacer_width/2 - 6, -spacer_width/2 + 6]) {
            for (y = [digit_height/2 - 6, -digit_height/2 + 6]) {
                translate([x, y, -1]) cylinder(h = total_depth - 0.5, r = 2.1, $fn = 20);
            }
        }
        
        // Stepped U-Notch cutouts mating over the backplate connector towers
        games_sets_frontplate_stepped_notch(is_left = true);
        games_sets_frontplate_stepped_notch(is_left = false);
        
        // Text labels debossed on front face
        translate([0, 105.0, total_depth - 0.6])
            linear_extrude(0.8)
                text("SETS", size=4.0, font="Liberation Sans:style=Bold", halign="center", valign="center");
                
        // "GAMES" text placed neatly in the blank spacer gap between Sets and Games (at Y = +58.33mm)
        translate([0, blank_y_position, total_depth - 0.6])
            linear_extrude(0.8)
                text("GAMES", size=3.8, font="Liberation Sans:style=Bold", halign="center", valign="center");
                
        // Team indicator labels: "1" and "2"
        translate([-col_spacing/2, 105.0, total_depth - 0.6])
            linear_extrude(0.8)
                text("1", size=4.0, font="Liberation Sans:style=Bold", halign="center", valign="center");
        translate([col_spacing/2, 105.0, total_depth - 0.6])
            linear_extrude(0.8)
                text("2", size=4.0, font="Liberation Sans:style=Bold", halign="center", valign="center");
    }
}

// -------------------------------------------------------------
// Component: Backplate
// -------------------------------------------------------------
module games_sets_backplate() {
    difference() {
        union() {
            // Main flat backplate plate
            translate([-(spacer_width - 4.4)/2, -(digit_height - 4.4)/2, -backplate_thick])
                cube([spacer_width - 4.4, digit_height - 4.4, backplate_thick]);
                
            // Left Connector Tower (Female Pogo)
            games_sets_backplate_connector_tower(is_left = true);
            
            // Right Connector Tower (Male Pogo)
            games_sets_backplate_connector_tower(is_left = false);
        }
            
        // 2 Continuous vertical LED strip / wiring channels (one under Team 1, one under Team 2)
        for (col = [-col_spacing/2, col_spacing/2]) {
            translate([col, 0, -strip_recess_depth/2 + 0.05])
                cube([strip_width, digit_height - 24.0, strip_recess_depth + 0.1], center=true);
        }
        
        // Cross-over wire routing channels (connects left and right columns at top and bottom)
        for (y = [-100.0, 100.0]) {
            translate([0, y, -strip_recess_depth/2 + 0.05])
                cube([col_spacing + 4.0, 8.0, strip_recess_depth + 0.1], center=true);
        }
        
        // Direct Horizontal Connector-to-Columns Wire Highway (stays safely inside inner 2mm walls)
        translate([0, 0, -strip_recess_depth/2 + 0.05])
            cube([spacer_width - 4.8, 10.0, strip_recess_depth + 0.1], center=true);
        
        // Mounting screw holes (M3 clearance with countersink)
        for (x = [spacer_width/2 - 6, -spacer_width/2 + 6]) {
            for (y = [digit_height/2 - 6, -digit_height/2 + 6]) {
                translate([x, y, -backplate_thick - 0.1]) {
                    cylinder(h=backplate_thick + 0.2, r=1.6, $fn=20);       
                    cylinder(h=1.6, r1=3.2, r2=1.6, $fn=20);                
                }
            }
        }
        
        // Orientation indicator debossed into the top of the backplate
        translate([0, 95.0, -backplate_thick - 0.1])
            linear_extrude(1.0)
                mirror([1, 0, 0])
                    text("↑ TOP", size=6.0, font="Liberation Sans:style=Bold", halign="center", valign="center");

        // Debossed rear label & copyright
        translate([0, 20.0, -backplate_thick - 0.1])
            linear_extrude(1.0)
                mirror([1, 0, 0])
                    text("GAMES / SETS", size=4.5, font="Liberation Sans:style=Bold", halign="center", valign="center");
                    
        translate([0, -100.0, -backplate_thick - 0.1])
            linear_extrude(1.0)
                mirror([1, 0, 0])
                    text("© GSC", size=5.5, font="Liberation Sans:style=Bold", halign="center", valign="center");
    }
}

// -------------------------------------------------------------
// Visual 3D Pogo Connector Model
// -------------------------------------------------------------
module pogo_connector_model(is_male = true, alpha = 1.0) {
    color("#1e293b", alpha) {
        cube([4.8, 17.5, 4.0], center=true);
        for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
            difference() {
                translate([0, y, 0])
                    hull() {
                        cube([2.0, 3.5, 3.8], center=true);
                        translate([0, (y > 0 ? 1 : -1) * 0.25, 0]) rotate([0, 90, 0]) cylinder(h=2.0, r=2.0, center=true, $fn=24);
                    }
                translate([0, y, 0]) rotate([0, 90, 0]) cylinder(h=3.5, r=0.9, center=true, $fn=20);
            }
        }
    }
    color("#94a3b8", alpha) {
        for (y = [-7.0, 7.0]) {
            translate([2.2, y, 0]) rotate([0, 90, 0]) cylinder(h=0.5, r=1.4, center=true, $fn=20);
        }
    }
    for (py = [-4.0, -2.0, 0.0, 2.0, 4.0]) {
        color("#eab308", alpha) {
            if (is_male) {
                translate([2.6, py, 0]) rotate([0, 90, 0]) cylinder(h=1.0, r=0.5, center=true, $fn=16);
            } else {
                translate([2.2, py, 0]) rotate([0, 90, 0]) cylinder(h=0.3, r=0.6, center=true, $fn=16);
            }
            translate([-3.2, py, 0]) rotate([0, 90, 0]) cylinder(h=2.5, r=0.4, center=true, $fn=12);
        }
    }
}

// -------------------------------------------------------------
// Assembly / Exploded & Inspection Render
// -------------------------------------------------------------
module render_games_sets_assembly() {
    if (inspection_mode == "collision_check") {
        // 1. Interference between Black Housing and Backplate
        show_collision() {
            games_sets_frontplate_black();
            games_sets_backplate();
        }
        // 2. Interference between Black Housing and White Snap Carrier Ladder
        show_collision() {
            games_sets_frontplate_black();
            games_sets_snap_carrier_ladder();
        }
    } else if (inspection_mode == "carrier_only") {
        color("#f8fafc", alpha_frontplate_white) games_sets_snap_carrier_ladder();
    } else if (inspection_mode == "frontplate_only") {
        color("#1e293b", alpha_frontplate_black) games_sets_frontplate_black();
    } else if (inspection_mode == "backplate_only") {
        color("#334155", alpha_backplate) games_sets_backplate();
    } else if (inspection_mode == "cutaway_x") {
        cutaway(axis = "x", cut_depth = cutaway_depth) {
            if (show_frontplate_black) color("#1e293b", alpha_frontplate_black) games_sets_frontplate_black();
            if (show_frontplate_white) color("#f8fafc", alpha_frontplate_white) games_sets_snap_carrier_ladder();
            if (show_backplate) color("#334155", alpha_backplate) games_sets_backplate();
            if (show_pogo_hardware) {
                translate([spacer_width/2 - pogo_boss_depth + 1.0, 0, pogo_z]) pogo_connector_model(is_male = true, alpha = alpha_pogo_hardware);
                translate([-spacer_width/2 + pogo_boss_depth - 1.0, 0, pogo_z]) rotate([0, 180, 0]) pogo_connector_model(is_male = false, alpha = alpha_pogo_hardware);
            }
        }
    } else if (inspection_mode == "cutaway_y") {
        cutaway(axis = "y", cut_depth = cutaway_depth) {
            if (show_frontplate_black) color("#1e293b", alpha_frontplate_black) games_sets_frontplate_black();
            if (show_frontplate_white) color("#f8fafc", alpha_frontplate_white) games_sets_snap_carrier_ladder();
            if (show_backplate) color("#334155", alpha_backplate) games_sets_backplate();
            if (show_pogo_hardware) {
                translate([spacer_width/2 - pogo_boss_depth + 1.0, 0, pogo_z]) pogo_connector_model(is_male = true, alpha = alpha_pogo_hardware);
                translate([-spacer_width/2 + pogo_boss_depth - 1.0, 0, pogo_z]) rotate([0, 180, 0]) pogo_connector_model(is_male = false, alpha = alpha_pogo_hardware);
            }
        }
    } else if (inspection_mode == "exploded" || exploded_view) {
        exp_z = explode_distance;
        if (show_frontplate_black) color("#1e293b", alpha_frontplate_black) games_sets_frontplate_black();
        if (show_frontplate_white) translate([0, 0, exp_z]) color("#f8fafc", alpha_frontplate_white) games_sets_snap_carrier_ladder();
        if (show_backplate) translate([0, 0, -exp_z]) color("#334155", alpha_backplate) games_sets_backplate();
        if (show_pogo_hardware) {
            translate([spacer_width/2 - pogo_boss_depth + 1.0, 0, pogo_z]) pogo_connector_model(is_male = true, alpha = alpha_pogo_hardware);
            translate([-spacer_width/2 + pogo_boss_depth - 1.0, 0, pogo_z]) rotate([0, 180, 0]) pogo_connector_model(is_male = false, alpha = alpha_pogo_hardware);
        }
    } else {
        // Fully Assembled
        if (show_frontplate_black) color("#1e293b", alpha_frontplate_black) games_sets_frontplate_black();
        if (show_frontplate_white) color("#f8fafc", alpha_frontplate_white) games_sets_snap_carrier_ladder();
        if (show_backplate) color("#334155", alpha_backplate) games_sets_backplate();
        if (show_pogo_hardware) {
            translate([spacer_width/2 - pogo_boss_depth + 1.0, 0, pogo_z]) pogo_connector_model(is_male = true, alpha = alpha_pogo_hardware);
            translate([-spacer_width/2 + pogo_boss_depth - 1.0, 0, pogo_z]) rotate([0, 180, 0]) pogo_connector_model(is_male = false, alpha = alpha_pogo_hardware);
        }
    }
}

render_games_sets_assembly();
