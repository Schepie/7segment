// Full 4-Digit Clock Assembly Preview with 4-Pin Magnetic Pogo Connectors
// Visualizes the complete clock assembly (Digit 1 - Digit 2 - Colon - Digit 3 - Digit 4)
// seamlessly chained together using the flush magnetic pogo pin interface.

use <7segment_pogo.scad>
use <colon_pogo.scad>
use <rear_joining_bracket.scad>

$fn = 24;

// --- Preview Controls ---
explode_z = 0;              // Set to 0 for fully assembled view, or 20 for exploded front/diffuser/back view
show_diffusers = true;      // Show white acrylic diffusers
show_backplates = true;     // Show rear backplates
show_pogo_pins = true;      // Render the 4-pin magnetic pogo connectors at each junction
show_rear_brackets = true;  // Render rear joining brackets across the top and bottom seams

// Dimensions matching 7segment_pogo & colon_pogo
digit_w = 140.4;            // Total width of a 7-segment digit
colon_w = 36.0;             // Total width of the colon spacer
pogo_z = 6.0;               // Z height of pogo connector in 12mm tunnel

// Center-to-center X positions for each module (colon centered at X = 0)
x_digit1 = -colon_w/2 - digit_w * 1.5; // X = -228.6 mm (Hour Tens)
x_digit2 = -colon_w/2 - digit_w * 0.5; // X = -88.2 mm  (Hour Ones)
x_colon  = 0;                          // X = 0.0 mm    (Blinking Colon)
x_digit3 = colon_w/2 + digit_w * 0.5;  // X = +88.2 mm  (Minute Tens)
x_digit4 = colon_w/2 + digit_w * 1.5;  // X = +228.6 mm (Minute Ones)

// -------------------------------------------------------------
// Helper: Render a complete single digit module
// -------------------------------------------------------------
module render_digit(id, x_pos) {
    translate([x_pos, 0, 0]) {
        // Black Housing
        color("DimGray") 
            frontplate_black(panel_id = id);
            
        // White Diffuser
        if (show_diffusers) {
            translate([0, 0, explode_z > 0 ? explode_z : 0])
                color("White") 
                    frontplate_white();
        }
        
        // Backplate
        if (show_backplates) {
            translate([0, 0, explode_z > 0 ? -explode_z : 0])
                color("#334155") 
                    backplate(panel_id = id);
        }
    }
}

// -------------------------------------------------------------
// Helper: Render colon module
// -------------------------------------------------------------
module render_colon(x_pos = 0) {
    translate([x_pos, 0, 0]) {
        // Black Housing
        color("DimGray") 
            colon_frontplate_black();
            
        // White Diffuser Dots
        if (show_diffusers) {
            translate([0, 0, explode_z > 0 ? explode_z : 0])
                color("White") 
                    colon_frontplate_white();
        }
        
        // Backplate
        if (show_backplates) {
            translate([0, 0, explode_z > 0 ? -explode_z : 0])
                color("#334155") 
                    colon_backplate();
        }
    }
}

// -------------------------------------------------------------
// Helper: Render mated pogo pin pair at a seam
// -------------------------------------------------------------
module render_pogo_junction(seam_x) {
    translate([seam_x, 0, pogo_z]) {
        // Left side connector (transmitting from left module, male pogo pins)
        translate([-1.8, 0, 0])
            pogo_connector_model(is_male = true);
            
        // Right side connector (receiving on right module, female target pads)
        translate([1.8, 0, 0])
            rotate([0, 180, 0])
                pogo_connector_model(is_male = false);
    }
}

// -------------------------------------------------------------
// Helper: Render rear joining brackets across a seam
// -------------------------------------------------------------
module render_seam_brackets(seam_x) {
    bracket_pitch_y = 117.2; // 234.4 / 2
    // Top corner rear bracket
    translate([seam_x, bracket_pitch_y - 6, -6.0 - 3.0])
        rotate([0, 180, 0])
            color("#0284c7")
                rear_joining_bracket();
                
    // Bottom corner rear bracket
    translate([seam_x, -bracket_pitch_y + 6, -6.0 - 3.0])
        rotate([0, 180, 180])
            color("#0284c7")
                rear_joining_bracket();
}

// =============================================================
// MAIN ASSEMBLY
// =============================================================

// 1. Digits & Colon
render_digit(1, x_digit1);
render_digit(2, x_digit2);
render_colon(x_colon);
render_digit(3, x_digit3);
render_digit(4, x_digit4);

// 2. Mated 4-Pin Magnetic Pogo Connectors at the 4 Seams
if (show_pogo_pins) {
    render_pogo_junction(x_digit1 + digit_w/2); // Seam 1: Digit 1 -> Digit 2 (X = -158.4)
    render_pogo_junction(x_digit2 + digit_w/2); // Seam 2: Digit 2 -> Colon   (X = -18.0)
    render_pogo_junction(x_colon  + colon_w/2); // Seam 3: Colon   -> Digit 3 (X = +18.0)
    render_pogo_junction(x_digit3 + digit_w/2); // Seam 4: Digit 3 -> Digit 4 (X = +158.4)
}

// 3. Optional Rear Joining Brackets
if (show_rear_brackets && explode_z == 0) {
    render_seam_brackets(x_digit1 + digit_w/2);
    render_seam_brackets(x_digit2 + digit_w/2);
    render_seam_brackets(x_colon  + colon_w/2);
    render_seam_brackets(x_digit3 + digit_w/2);
}
