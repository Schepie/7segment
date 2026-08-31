use <7segment_v1.scad>

// High-resolution 3D Perspective View of the Bottomplate (Panel 1)
// Rendered in slate gray polymer with contrasting pocket depth and boss details
$fn = 60;

// Render backplate
color("#475569") 
    backplate(1);

// Optional subtle highlight on the ESP32 cradle
color("#10b981") 
    translate([0, -50, 0]) 
        intersection() {
            backplate(1);
            translate([-15, -15, 0]) cube([30, 30, 10]);
        }
