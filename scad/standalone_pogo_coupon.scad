// Standalone Pogo Pin Connector Test Coupon
// Outside mount: connector drops in from outside, ears rest on bosses at -3mm depth, front face flush at 0mm.

$fn = 32;

// Exact parameters
pogo_ear_span       = 23.9; // 23.5mm nominal + 0.4mm clearance across ears
pogo_ear_pitch      = 20.0; // 20.0mm exact hole-to-hole
pogo_hole_d         = 1.8;  // 1.8mm pilot hole
pogo_hole_depth     = 7.0;  // 7mm deep into solid boss
pogo_body_w         = 18.0; // 17.5mm nominal + 0.5mm clearance
pogo_body_h         = 4.4;  // 4.0mm nominal + 0.4mm clearance
pogo_boss_depth     = 3.0;  // Boss seating plane is exactly 3.0mm deep from outside
pogo_boss_r         = 3.0;  // Radius 3.0mm (dia 6.0mm)

coupon_w = 40.0;
coupon_h = 13.0;
coupon_wall_t = 2.0;
boss_len = 6.0;

// Coordinate plane:
// X = 0.0 mm: OUTSIDE face of housing wall
// X = -2.0 mm: INSIDE face of 2.0mm housing wall
// X = -3.0 mm: Screw boss seating face (-3.0mm from outside)
// X = -9.0 mm: Back of screw boss

module rounded_stadium_slot(depth, length_y, height_z, center = true) {
    r = height_z / 2;
    linear_extrude(height = depth, center = center) {
        hull() {
            translate([0, -(length_y/2 - r)]) circle(r = r, $fn = 24);
            translate([0,  (length_y/2 - r)]) circle(r = r, $fn = 24);
        }
    }
}

module pogo_test_coupon() {
    outer_x = 0.0;
    boss_face_x = outer_x - pogo_boss_depth; // -3.0 mm
    
    difference() {
        union() {
            // 1. Main outer housing wall (40 x 13 x 2 mm from X = -2.0 to 0.0)
            translate([-coupon_wall_t / 2, 0, coupon_h / 2])
                cube([coupon_wall_t, coupon_w, coupon_h], center = true);
            
            // 2. Solid screw bosses behind the ears (extending from X = -2.0 to X = -9.0)
            for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
                hull() {
                    translate([-coupon_wall_t + 0.1, y, coupon_h / 2])
                        cube([0.2, pogo_boss_r * 2, pogo_body_h + 2.0], center = true);
                    translate([boss_face_x - boss_len, y, coupon_h / 2])
                        rotate([0, 90, 0])
                            cylinder(h = 0.5, r = pogo_boss_r, center = true, $fn = 24);
                }
            }
            
            // Stiffening top and bottom ribs
            translate([(boss_face_x - boss_len) / 2, 0, 0.6])
                cube([boss_len + pogo_boss_depth, coupon_w, 1.2], center = true);
            translate([(boss_face_x - boss_len) / 2, 0, coupon_h - 0.6])
                cube([boss_len + pogo_boss_depth, coupon_w, 1.2], center = true);
        }
        
        // --- SUBTRACTIONS (Cut from outside face X = 0) ---
        
        // 1. Full Connector & Ear Pocket (23.9 x 4.4 mm) recessed 3.0mm deep from outside (X = 0 to X = -3.0)
        translate([-pogo_boss_depth / 2 + 0.05, 0, coupon_h / 2])
            rotate([0, 90, 0])
                rounded_stadium_slot(depth = pogo_boss_depth + 0.1, length_y = pogo_ear_span, height_z = pogo_body_h, center = true);
        
        // 2. Central Body Through-Opening (18.0 x 4.4 mm) passing all the way through into inside cavity
        translate([-10.0, 0, coupon_h / 2])
            rotate([0, 90, 0])
                rounded_stadium_slot(depth = 25.0, length_y = pogo_body_w, height_z = pogo_body_h, center = true);
                
        // 3. 2x Screw Pilot Holes (1.8mm dia, 7mm deep) drilled into the bosses starting at X = -3.0mm
        for (y = [-pogo_ear_pitch/2, pogo_ear_pitch/2]) {
            translate([boss_face_x + 0.5, y, coupon_h / 2])
                rotate([0, -90, 0])
                    cylinder(h = pogo_hole_depth + 1.0, r = pogo_hole_d / 2, $fn = 20);
        }
    }
}

pogo_test_coupon();
