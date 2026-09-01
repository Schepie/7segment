// ==============================================================================
// Games & Sets Indicator Module (Pogo Pin Edition) - "games_sets_pogo.scad"
// Fits between digits (e.g. between Team 1 and Team 2 digits on a Padel Scoreboard).
//
// Display Layout:
// 2 Vertical Columns of LEDs:
// - Left Column  (X = -col_spacing/2): Team 1 Indicators
// - Right Column (X = +col_spacing/2): Team 2 Indicators
//
// In each column (running vertically along Y):
// - Top 2 Dots:    SETS WON (Set 1, Set 2) - Larger/accentuated (r = 4.5mm)
// - Lower 9 Dots:  GAMES WON (Game 1 to 9) - Compact dots (r = 3.5mm)
// Total per team: 11 LEDs (2 sets + 9 games) -> 22 LEDs total.
//
// Features flush outside-mount 4-pin magnetic pogo connectors on left and right walls.
// ==============================================================================

/* [Display Configuration] */
spacer_width = 56.0;         // Width of the indicator module in mm (widened to 56mm to give generous clearance from pogo connectors)
col_spacing  = 22.0;         // Center-to-center distance between Team 1 and Team 2 columns (+/- 11mm)
show_pogo_hardware = true;   // Preview 3D pogo connectors in mounting pockets

/* [Visibility & Exploded View] */
show_frontplate_black = true; // Black structural housing & light-isolation wells
show_frontplate_white = true; // White diffuser inserts / light guides
show_backplate        = true; // Rear backplate with PCB/LED channels & screw holes
exploded_view         = false; // Set to true to view all layers exploded along Z and X axes
explode_distance      = 35.0; // Distance between exploded layers in mm

/* [System Dimensions matching 7segment_pogo.scad] */
pitch_x = 92.0;               // Distance between middle vertical LED strips (92 mm)
pitch_y_top = 92.0;           // Pitch from center to top horizontal segment (92 mm)
pitch_y_bot = 92.0;           // Pitch from center to bottom horizontal segment (92 mm)
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
digit_height = pitch_y_top + pitch_y_bot + total_seg_w + margin_y * 2.0; // 230.4 mm (EXACT match with 7segment_pogo.scad)

/* [LED Strip Configuration - Standard 60 LEDs/m Strip] */
led_pitch = 1000.0 / 60.0; // Exact 16.667 mm pitch between consecutive LEDs on a 60 LED/m strip

// Indicator dot radii
set_dot_radius   = 4.5;      // Radius for Sets indicators (top 2 LEDs)
game_dot_radius  = 4.5;      // Radius for Games indicators (lower 9 LEDs)

// Each column has 1 continuous, uncut strip of 12 consecutive LEDs (index 0 to 11):
// Total vertical span = 11 * 16.667mm = 183.33mm (centered vertically from Y = -91.67 to +91.67)
// - LEDs 0 to 8   (lower 9 LEDs):  GAMES 1 to 9 (Y = -91.67mm to +41.67mm)
// - LED 9         (1 blank LED):   SPACER GAP   (Y = +58.33mm) - Left unpunched / solid plastic / never turned on!
// - LEDs 10 to 11 (top 2 LEDs):    SETS 1 & 2   (Y = +75.00mm & +91.67mm)

led_y_base = - (11 * led_pitch) / 2; // -91.667 mm

game_y_positions = [ for (i = [0 : 8]) led_y_base + i * led_pitch ];   // 9 Game LEDs
blank_y_position = led_y_base + 9 * led_pitch;                         // +58.33 mm (Blank spacer LED)
set_y_positions  = [ for (i = [10 : 11]) led_y_base + i * led_pitch ]; // 2 Set LEDs

/* [4-Pin Magnetic Pogo Pin Connector Parameters] */
pogo_ear_span       = 23.9; // Outer span across mounting ears
pogo_ear_pitch      = 20.0; // Hole-to-hole center spacing
pogo_hole_d         = 1.8;  // Pilot hole for M2 screw
pogo_hole_depth     = 7.0;  // Thread depth in boss
pogo_body_w         = 18.0; // Central body width
pogo_body_h         = 4.4;  // Central body height
pogo_body_r         = 2.2;  // Corner radius
pogo_boss_depth     = 3.0;  // Boss face at -3.0mm from outside
pogo_boss_r         = 3.0;  // Boss radius
pogo_pass_depth     = 10.0; // Wiring clearance
pogo_z              = 6.0;  // Centered along Z

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

// Internal Screw Bosses on inner side walls (start at -3.0mm from outside face)
module pogo_mounting_bosses(is_left = false) {
    side = is_left ? -1 : 1;
    wall_x = side * spacer_width / 2; // Outside face (0.0mm reference)
    inner_x = side * (spacer_width / 2 - 2.0); // Inside face of 2mm wall
    boss_face_x = wall_x - side * pogo_boss_depth; // Exactly -3.0mm from outside face
    boss_len = 6.0;
    
    for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
        hull() {
            translate([inner_x + side * 0.1, y, pogo_z])
                cube([0.2, pogo_boss_r * 2, pogo_body_h + 2.0], center=true);
            translate([boss_face_x - side * boss_len, y, pogo_z])
                rotate([0, 90, 0])
                    cylinder(h=0.5, r=pogo_boss_r, center=true, $fn=24);
        }
    }
}

// Pogo connector cutout subtracted from housing
module pogo_mounting_cutout(is_left = false) {
    side = is_left ? -1 : 1;
    wall_x = side * spacer_width / 2;
    inner_x = side * (spacer_width / 2 - 2.0);
    boss_face_x = wall_x - side * pogo_boss_depth;
    
    // 1. Full Connector Pocket (23.9 x 4.4 mm) recessed 3.0mm deep from outside
    translate([wall_x - side * (pogo_boss_depth / 2 - 0.05), 0, pogo_z])
        rotate([0, 90, 0])
            rounded_stadium_slot(depth = pogo_boss_depth + 0.1, length_y = pogo_ear_span, height_z = pogo_body_h, center = true);
        
    // 2. Central Body Inward Wiring Opening (18.0 x 4.4 mm) extending only 7mm inward behind wall
    translate([wall_x - side * (3.5 + 2.0), 0, pogo_z])
        rotate([0, 90, 0])
            rounded_stadium_slot(depth = 7.0, length_y = pogo_body_w, height_z = pogo_body_h, center = true);
        
    // 3. 2x Screw Pilot Holes drilled into bosses starting at boss_face_x (-3.0mm from outside)
    for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
        translate([boss_face_x + side * 0.5, y, pogo_z])
            rotate([0, -side * 90, 0])
                cylinder(h = pogo_hole_depth + 1.0, r = pogo_hole_d / 2, $fn = 20);
    }
    
    // 4. Sense Resistor Stash Pocket
    translate([inner_x - side * 4.0, side * 8.0, pogo_z - 3.0])
        cube([5.0, 3.5, 2.5], center = true);
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
                // Sets collars
                for (y = set_y_positions) {
                    translate([col, y, 0])
                        cylinder(h=total_depth, r=set_dot_radius + white_wall + 1.2, $fn=32);
                }
                // Games collars
                for (y = game_y_positions) {
                    translate([col, y, 0])
                        cylinder(h=total_depth, r=game_dot_radius + white_wall + 1.2, $fn=32);
                }
            }
            
            // 3. Corner backplate screw bosses
            translate([spacer_width/2 - 6, digit_height/2 - 6, 0]) cylinder(h=total_depth - 1.2, r=4.2, $fn=20);
            translate([-spacer_width/2 + 6, digit_height/2 - 6, 0]) cylinder(h=total_depth - 1.2, r=4.2, $fn=20);
            translate([spacer_width/2 - 6, -digit_height/2 + 6, 0]) cylinder(h=total_depth - 1.2, r=4.2, $fn=20);
            translate([-spacer_width/2 + 6, -digit_height/2 + 6, 0]) cylinder(h=total_depth - 1.2, r=4.2, $fn=20);
            
            // 4. Internal Pogo screw bosses on left and right walls
            pogo_mounting_bosses(is_left = true);
            pogo_mounting_bosses(is_left = false);
        }
        
        // --- SUBTRACTIONS ---
        
        // Boreholes for white lightguides (Sets + Games)
        for (col = [-col_spacing/2, col_spacing/2]) {
            // Sets boreholes
            for (y = set_y_positions) {
                translate([col, y, -1.0])
                    cylinder(h=total_depth + 2.0, r=set_dot_radius + white_wall, $fn=32);
            }
            // Games boreholes
            for (y = game_y_positions) {
                translate([col, y, -1.0])
                    cylinder(h=total_depth + 2.0, r=game_dot_radius + white_wall, $fn=32);
            }
        }
        
        // Backplate M3 screw pilot holes (heat-set inserts)
        translate([spacer_width/2 - 6, digit_height/2 - 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([-spacer_width/2 + 6, digit_height/2 - 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([spacer_width/2 - 6, -digit_height/2 + 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        translate([-spacer_width/2 + 6, -digit_height/2 + 6, -1]) cylinder(h=total_depth - 0.5, r=2.1, $fn=20);
        
        // Pogo connector mounting cutouts on both left and right walls
        pogo_mounting_cutout(is_left = true);
        pogo_mounting_cutout(is_left = false);
        
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
// Component: White Diffusers / Light Guides
// -------------------------------------------------------------
module games_sets_frontplate_white() {
    difference() {
        union() {
            for (col = [-col_spacing/2, col_spacing/2]) {
                // Sets solid cylinders + top diffuser
                for (y = set_y_positions) {
                    translate([col, y, 0])
                        cylinder(h=total_depth, r=set_dot_radius + white_wall, $fn=32);
                }
                // Games solid cylinders + top diffuser
                for (y = game_y_positions) {
                    translate([col, y, 0])
                        cylinder(h=total_depth, r=game_dot_radius + white_wall, $fn=32);
                }
            }
        }
        
        // Hollow internal light chambers (leaves 0.8mm top diffuser layer)
        for (col = [-col_spacing/2, col_spacing/2]) {
            for (y = set_y_positions) {
                translate([col, y, -0.1])
                    cylinder(h=tunnel_depth + 0.1, r=set_dot_radius, $fn=32);
            }
            for (y = game_y_positions) {
                translate([col, y, -0.1])
                    cylinder(h=tunnel_depth + 0.1, r=game_dot_radius, $fn=32);
            }
        }
    }
}

// -------------------------------------------------------------
// Component: Backplate
// -------------------------------------------------------------
module games_sets_backplate() {
    difference() {
        // Main flat backplate plate
        translate([-(spacer_width - 4.4)/2, -(digit_height - 4.4)/2, -backplate_thick])
            cube([spacer_width - 4.4, digit_height - 4.4, backplate_thick]);
            
        // 2 Continuous vertical LED strip / wiring channels (one under Team 1, one under Team 2)
        for (col = [-col_spacing/2, col_spacing/2]) {
            translate([col, 0, -strip_recess_depth/2 + 0.05])
                cube([strip_width, digit_height - 24.0, strip_recess_depth + 0.1], center=true);
        }
        
        // Cross-over wire routing channels (connects left and right columns at top, middle, and bottom)
        for (y = [-100.0, 0.0, 100.0]) {
            translate([0, y, -strip_recess_depth/2 + 0.05])
                cube([col_spacing + 4.0, 8.0, strip_recess_depth + 0.1], center=true);
        }
        
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
module pogo_connector_model(is_male = true) {
    color("#1e293b") {
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
    color("#94a3b8") {
        for (y = [-7.0, 7.0]) {
            translate([2.2, y, 0]) rotate([0, 90, 0]) cylinder(h=0.5, r=1.4, center=true, $fn=20);
        }
    }
    for (py = [-4.0, -2.0, 0.0, 2.0, 4.0]) {
        color("#eab308") {
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
// Assembly / Exploded Render
// -------------------------------------------------------------
// Explode offsets:
exp_white_z = exploded_view ? explode_distance * 1.0 : 0;
exp_black_z = 0;
exp_back_z  = exploded_view ? -explode_distance * 1.0 : 0;
exp_pogo_x  = exploded_view ? explode_distance * 0.8 : 0;

// 1. White Diffusers (Exploded Forward along +Z)
if (show_frontplate_white) 
    translate([0, 0, exp_white_z]) 
        color("#f8fafc") 
            games_sets_frontplate_white();

// 2. Black Housing (Central baseline Z = 0)
if (show_frontplate_black) 
    translate([0, 0, exp_black_z]) 
        color("#1e293b") 
            games_sets_frontplate_black();

// 3. Backplate (Exploded Rearward along -Z)
if (show_backplate) 
    translate([0, 0, exp_back_z]) 
        color("#334155") 
            games_sets_backplate();

// 4. Pogo Connectors (Exploded Outward along +X and -X)
if (show_pogo_hardware) {
    // Right wall pogo (Male)
    translate([spacer_width/2 - pogo_boss_depth + 1.0 + exp_pogo_x, 0, pogo_z])
        pogo_connector_model(is_male = true);
        
    // Left wall pogo (Female)
    translate([-spacer_width/2 + pogo_boss_depth - 1.0 - exp_pogo_x, 0, pogo_z])
        rotate([0, 180, 0])
            pogo_connector_model(is_male = false);
}
