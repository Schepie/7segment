// Colon Dots Lightguide / Diffuser (Parametric)
// Solid continuous reflector walls (No wire cutouts)
// Optimized for maximum brightness: 0.6mm and 0.8mm top diffuser layer variants

// --- Configuration Parameter ---
diffuser_thick = 0.6; // [0.6: High Brightness (0.6mm), 0.8: Balanced (0.8mm), 1.0: Standard (1.0mm)]

total_depth = 13.0;   // Matches frontplate housing depth (13.0 mm)
tunnel_depth = total_depth - diffuser_thick; // Inner cavity depth (12.4mm for 0.6, 12.2mm for 0.8)

// --- Colon Dimensions (matching colon_pogo.scad) ---
colon_y_offset = 40.0;
colon_radius = 6.0;
white_wall = 1.2;
enable_lightguide_snap_locks = true;

// Snap-lock detents & tabs geometry
module colon_lightguide_snap_teeth(is_subtraction = false) {
    if (enable_lightguide_snap_locks) {
        tooth_w = 3.2;
        tooth_h = 2.2;
        tooth_reach = is_subtraction ? 0.7 : 0.5;
        
        for (y = [colon_y_offset, -colon_y_offset]) {
            for (side = [-1, 1]) {
                translate([side * (colon_radius + white_wall), y, 2.5]) {
                    if (is_subtraction) {
                        cube([tooth_reach * 2 + 0.4, tooth_w + 0.4, tooth_h + 0.4], center=true);
                    } else {
                        // Sunk 0.5mm into cylinder wall to guarantee 100% clean manifold union
                        rotate([0, side > 0 ? 0 : 180, 0])
                            linear_extrude(tooth_w, center=true)
                                polygon([
                                    [-0.5, -tooth_h/2],
                                    [tooth_reach, -tooth_h/4],
                                    [tooth_reach, tooth_h/4],
                                    [-0.5, tooth_h/2]
                                ]);
                    }
                }
            }
        }
    }
}

module colon_lightguide_flex_slits() {
    if (enable_lightguide_snap_locks) {
        slit_w = 0.8;
        slit_l = 4.0;
        slit_h = 5.5;
        for (y = [colon_y_offset, -colon_y_offset]) {
            for (side = [-1, 1]) {
                for (dy = [-2.0, 2.0]) {
                    translate([side * (colon_radius + white_wall), y + dy, slit_h/2 - 0.1])
                        cube([slit_l, slit_w, slit_h + 0.2], center=true);
                }
            }
        }
    }
}

module colon_frontplate_white(d_thick = diffuser_thick) {
    t_depth = total_depth - d_thick;
    difference() {
        union() {
            // Outer white reflector walls + top diffuser (Total depth = 13.0 mm)
            for (y = [colon_y_offset, -colon_y_offset]) {
                translate([0, y, 0]) cylinder(h=total_depth, r=colon_radius + white_wall, $fn=40);
            }
            
            // Outward snap-lock teeth on lightguide sides (cleanly embedded)
            colon_lightguide_snap_teeth(is_subtraction = false);
        }
        
        // Hollow light tunnel cavity, leaving d_thick solid diffuser face on top
        for (y = [colon_y_offset, -colon_y_offset]) {
            translate([0, y, -0.1]) cylinder(h=t_depth + 0.1, r=colon_radius, $fn=40);
        }
        
        // Compliance flex slits allowing snap teeth to deflect on insertion
        colon_lightguide_flex_slits();
    }
}

// Default render
color("White") colon_frontplate_white(diffuser_thick);
