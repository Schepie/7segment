// ==============================================================================
// Full Padel Scoreboard Assembly Preview (Pogo Pin Edition)
// Layout: [Digit 1] + [Digit 2] + [Games & Sets Panel] + [Digit 3] + [Digit 4]
//
// Shows all 5 modules docked magnetically across the 4 seams.
// ==============================================================================

/* [Display Toggles] */
show_frontplate_black = true; // Black structural housing & segment walls
show_frontplate_white = true; // White diffuser lenses
show_backplate        = true; // Rear backplates
show_pogo_connectors  = true; // 3D Magnetic pogo connectors inside seams
exploded_view         = false;// Set to true to view all panels and layers separated
explode_z             = 35.0; // Vertical layer explosion distance in mm
panel_gap             = 0.0;  // Gap between panels (0.0mm = fully docked, 15.0mm = exploded panels)

// Use libraries without executing their root-level render blocks
use <7segment_pogo.scad>
use <games_sets_pogo.scad>

$fn = 24;

// Key parameters matching 7segment_pogo and games_sets_pogo
pitch_x         = 92.0;
pitch_y_top     = 92.0;
pitch_y_bot     = 92.0;
strip_width     = 12.0;
white_wall      = 1.2;
margin_x        = 15.0;
margin_y        = 15.0;
diffuser_w      = strip_width + 2.0;
total_seg_w     = diffuser_w + white_wall * 2.0;
digit_w         = pitch_x + total_seg_w + margin_x * 2.0; // 138.4 mm
games_w         = 56.0;                                   // 56.0 mm
pogo_z          = 6.0;
pogo_boss_depth = 3.0;

seam_gap = exploded_view ? 18.0 : panel_gap;

// X-positions for all 5 modules centered around origin:
// D1: Leftmost Team 1 Digit (Panel 1 with USB-C)
// D2: Right Team 1 Digit (Panel 2)
// GS: Center Games & Sets Indicator Panel
// D3: Left Team 2 Digit (Panel 3)
// D4: Rightmost Team 2 Digit (Panel 4)

x_d1 = - (games_w/2 + digit_w + digit_w/2 + seam_gap * 2);
x_d2 = - (games_w/2 + digit_w/2 + seam_gap);
x_gs = 0.0;
x_d3 =   (games_w/2 + digit_w/2 + seam_gap);
x_d4 =   (games_w/2 + digit_w + digit_w/2 + seam_gap * 2);

exp_w_z = exploded_view ? explode_z : 0;
exp_b_z = exploded_view ? -explode_z : 0;

// -------------------------------------------------------------
// Assembly Rendering
// -------------------------------------------------------------

module render_padel_scoreboard() {
    // 1. DIGIT 1 (Leftmost, Panel 1 with USB-C on left wall, Pogo on right wall)
    translate([x_d1, 0, 0]) {
        if (show_frontplate_black) color("#1e293b") frontplate_black(panel_id = 1);
        if (show_frontplate_white) translate([0, 0, exp_w_z]) color("#f8fafc") frontplate_white();
        if (show_backplate) translate([0, 0, exp_b_z]) color("#334155") backplate(panel_id = 1);
        if (show_pogo_connectors) {
            // Right pogo
            translate([digit_w/2 - pogo_boss_depth + 1.0, 0, pogo_z]) pogo_connector_model(is_male = true);
        }
    }
    
    // 2. DIGIT 2 (Team 1 Second Digit, Panel 2 with Pogo on both left and right walls)
    translate([x_d2, 0, 0]) {
        if (show_frontplate_black) color("#1e293b") frontplate_black(panel_id = 2);
        if (show_frontplate_white) translate([0, 0, exp_w_z]) color("#f8fafc") frontplate_white();
        if (show_backplate) translate([0, 0, exp_b_z]) color("#334155") backplate(panel_id = 2);
        if (show_pogo_connectors) {
            // Left pogo
            translate([-digit_w/2 + pogo_boss_depth - 1.0, 0, pogo_z]) rotate([0, 180, 0]) pogo_connector_model(is_male = false);
            // Right pogo
            translate([digit_w/2 - pogo_boss_depth + 1.0, 0, pogo_z]) pogo_connector_model(is_male = true);
        }
    }
    
    // 3. GAMES & SETS INDICATOR PANEL (Center, 56mm width, 12 LEDs per team)
    translate([x_gs, 0, 0]) {
        if (show_frontplate_black) color("#1e293b") games_sets_frontplate_black();
        if (show_frontplate_white) translate([0, 0, exp_w_z]) color("#f8fafc") games_sets_frontplate_white();
        if (show_backplate) translate([0, 0, exp_b_z]) color("#334155") games_sets_backplate();
        if (show_pogo_connectors) {
            // Left pogo
            translate([-games_w/2 + pogo_boss_depth - 1.0, 0, pogo_z]) rotate([0, 180, 0]) pogo_connector_model(is_male = false);
            // Right pogo
            translate([games_w/2 - pogo_boss_depth + 1.0, 0, pogo_z]) pogo_connector_model(is_male = true);
        }
    }
    
    // 4. DIGIT 3 (Team 2 First Digit, Panel 3 with Pogo on both left and right walls)
    translate([x_d3, 0, 0]) {
        if (show_frontplate_black) color("#1e293b") frontplate_black(panel_id = 3);
        if (show_frontplate_white) translate([0, 0, exp_w_z]) color("#f8fafc") frontplate_white();
        if (show_backplate) translate([0, 0, exp_b_z]) color("#334155") backplate(panel_id = 3);
        if (show_pogo_connectors) {
            // Left pogo
            translate([-digit_w/2 + pogo_boss_depth - 1.0, 0, pogo_z]) rotate([0, 180, 0]) pogo_connector_model(is_male = false);
            // Right pogo
            translate([digit_w/2 - pogo_boss_depth + 1.0, 0, pogo_z]) pogo_connector_model(is_male = true);
        }
    }
    
    // 5. DIGIT 4 (Rightmost End Panel, Panel 4 with Pogo on left wall, solid right wall)
    translate([x_d4, 0, 0]) {
        if (show_frontplate_black) color("#1e293b") frontplate_black(panel_id = 4);
        if (show_frontplate_white) translate([0, 0, exp_w_z]) color("#f8fafc") frontplate_white();
        if (show_backplate) translate([0, 0, exp_b_z]) color("#334155") backplate(panel_id = 4);
        if (show_pogo_connectors) {
            // Left pogo
            translate([-digit_w/2 + pogo_boss_depth - 1.0, 0, pogo_z]) rotate([0, 180, 0]) pogo_connector_model(is_male = false);
        }
    }
}

render_padel_scoreboard();
