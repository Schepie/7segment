// 3D Measurement Overlay for 7segment_v1 Backplate (Panel 1)
use <7segment_v1.scad>

// Render Backplate in slate gray with panel_id=1
color("SlateGray") backplate(1);

// Dimension Overlay in vibrant cyan, orange, and red
color("Cyan") {
    // 1. Overall Width (Bottom): 136.0 mm
    translate([-68.0, -145, 0]) cube([136.0, 1.5, 0.8]);
    translate([-68.0, -150, 0]) cube([1.5, 10, 0.8]);
    translate([66.5, -150, 0]) cube([1.5, 10, 0.8]);
    translate([0, -158, 0]) linear_extrude(0.8) text("136.0 mm (Backplate Width)", size=8, font="Liberation Sans:style=Bold", halign="center");

    // 2. Segment Pitch X (Top): 94.0 mm
    translate([-47.0, 125, 0]) cube([94.0, 1.5, 0.8]);
    translate([-47.0, 120, 0]) cube([1.5, 10, 0.8]);
    translate([45.5, 120, 0]) cube([1.5, 10, 0.8]);
    translate([0, 130, 0]) linear_extrude(0.8) text("Pitch X: 94.0 mm", size=7, font="Liberation Sans:style=Bold", halign="center");

    // 3. Overall Height (Right): 230.0 mm
    translate([82, -115.0, 0]) cube([1.5, 230.0, 0.8]);
    translate([77, -115.0, 0]) cube([10, 1.5, 0.8]);
    translate([77, 113.5, 0]) cube([10, 1.5, 0.8]);
    translate([98, 0, 0]) rotate([0, 0, 90]) linear_extrude(0.8) text("230.0 mm (Backplate Height)", size=8, font="Liberation Sans:style=Bold", halign="center");

    // 4. Center Pitches Y: 94 mm and 94 mm
    translate([68, 0, 0]) cube([1.2, 94.0, 0.8]);
    translate([64, 0, 0]) cube([8, 1.2, 0.8]);
    translate([64, 92.8, 0]) cube([8, 1.2, 0.8]);
    translate([76, 47.0, 0]) rotate([0, 0, 90]) linear_extrude(0.8) text("Pitch Y: 94 mm", size=5.5, font="Liberation Sans:style=Bold", halign="center");

    translate([68, -94.0, 0]) cube([1.2, 94.0, 0.8]);
    translate([64, -94.0, 0]) cube([8, 1.2, 0.8]);
    translate([64, -1.2, 0]) cube([8, 1.2, 0.8]);
    translate([76, -47.0, 0]) rotate([0, 0, 90]) linear_extrude(0.8) text("Pitch Y: 94 mm", size=5.5, font="Liberation Sans:style=Bold", halign="center");
}

color("Orange") {
    // 5. Orange Dimensions: Inner Windows ±82 mm
    // Horizontal window between strips: 82.0 mm
    translate([-41.0, 47.0, 0.8]) cube([82.0, 1.5, 0.8]);
    translate([-41.0, 43.0, 0.8]) cube([1.5, 8, 0.8]);
    translate([39.5, 43.0, 0.8]) cube([1.5, 8, 0.8]);
    translate([0, 51.0, 0.8]) linear_extrude(0.8) text("Window: ±82 mm", size=6, font="Liberation Sans:style=Bold", halign="center");

    // Vertical top window: 82.0 mm (between Y=+6 and Y=+88)
    translate([0, 6.0, 0.8]) cube([1.2, 82.0, 0.8]);
    translate([-4, 6.0, 0.8]) cube([8, 1.2, 0.8]);
    translate([-4, 86.8, 0.8]) cube([8, 1.2, 0.8]);
    translate([8, 47.0, 0.8]) rotate([0, 0, 90]) linear_extrude(0.8) text("±82 mm", size=5.5, font="Liberation Sans:style=Bold", halign="center");

    // Vertical bottom window: 82.0 mm (between Y=-88 and Y=-6)
    translate([20, -88.0, 0.8]) cube([1.2, 82.0, 0.8]);
    translate([16, -88.0, 0.8]) cube([8, 1.2, 0.8]);
    translate([16, -7.2, 0.8]) cube([8, 1.2, 0.8]);
    translate([28, -47.0, 0.8]) rotate([0, 0, 90]) linear_extrude(0.8) text("±82 mm", size=5.5, font="Liberation Sans:style=Bold", halign="center");

    // 6. VESA 50x50 mm Pattern
    translate([-25, 30, 4.5]) cube([50, 1, 0.8]);
    translate([-25, 27, 4.5]) cube([1, 6, 0.8]);
    translate([24, 27, 4.5]) cube([1, 6, 0.8]);
    translate([0, 33, 4.5]) linear_extrude(0.8) text("VESA: 50.0 mm", size=5, font="Liberation Sans:style=Bold", halign="center");
}

color("Red") {
    // 7. Middle Transition Span: 38.0 mm (from Y = +19.0 to Y = -19.0)
    translate([53, -19.0, 0.8]) cube([1.2, 38.0, 0.8]);
    translate([49, -19.0, 0.8]) cube([8, 1.2, 0.8]);
    translate([49, 17.8, 0.8]) cube([8, 1.2, 0.8]);
    translate([58, 0, 0.8]) rotate([0, 0, 90]) linear_extrude(0.8) text("Middle Cavity: 38 mm", size=4.5, font="Liberation Sans:style=Bold", halign="center");
}
