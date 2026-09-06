use <7segment_v2.scad>

color("SlateGray") backplate();

color("Red") {
    // Width dimension line (bottom) - 138.4 mm
    translate([-69.2, -135, 0]) cube([138.4, 2, 1]);
    translate([-69.2, -140, 0]) cube([2, 12, 1]);
    translate([67.2, -140, 0]) cube([2, 12, 1]);
    translate([0, -150, 0]) linear_extrude(1) text("138.4 mm (Width)", size=9, halign="center");
    
    // Height dimension line (right) - 231.4 mm
    translate([82, -115.7, 0]) cube([2, 231.4, 1]);
    translate([77, -115.7, 0]) cube([12, 2, 1]);
    translate([77, 113.7, 0]) cube([12, 2, 1]);
    translate([98, 0, 0]) rotate([0, 0, 90]) linear_extrude(1) text("231.4 mm (Height)", size=9, halign="center");
    
    // Pitch between parallel vertical strips (Top) - 93 mm
    translate([-46.5, 112, 0]) cube([93, 1.5, 1]);
    translate([-46.5, 108, 0]) cube([1.5, 9, 1]);
    translate([45, 108, 0]) cube([1.5, 9, 1]);
    translate([0, 118, 0]) linear_extrude(1) text("Parallel Pitch: 93 mm", size=6, halign="center");
    
    // Total Segment Length with Connectors (Top Segment) - 105 mm
    translate([-52.5, 82, 0]) cube([105, 1.2, 1]);
    translate([-52.5, 78, 0]) cube([1.2, 8, 1]);
    translate([51.3, 78, 0]) cube([1.2, 8, 1]);
    translate([0, 87, 0]) linear_extrude(1) text("Total Segment Span: 105 mm", size=5.5, halign="center");
    
    // LED strip length - 68 mm (Middle Segment)
    translate([-34, 15, 0]) cube([68, 1.2, 1]);
    translate([-34, 11, 0]) cube([1.2, 8, 1]);
    translate([32.8, 11, 0]) cube([1.2, 8, 1]);
    translate([0, 19, 0]) linear_extrude(1) text("LED Strip: 68 mm", size=5.5, halign="center");
    
    // 90-degree Connector Space - 18.5 mm (Left side of Middle Segment)
    translate([-52.5, -20, 0]) cube([18.5, 1, 1]);
    translate([-52.5, -23, 0]) cube([1, 6, 1]);
    translate([-34, -23, 0]) cube([1, 6, 1]);
    translate([-43.25, -28, 0]) linear_extrude(1) text("90° Conn: 18.5 mm", size=4, halign="center");
    
    // LED strip width - 11 mm
    translate([-60, -5.5, 0]) cube([1, 11, 1]);
    translate([-63, -5.5, 0]) cube([6, 1, 1]);
    translate([-63, 4.5, 0]) cube([6, 1, 1]);
    translate([-72, 0, 0]) rotate([0, 0, 90]) linear_extrude(1) text("11 mm", size=4.5, halign="center", valign="center");
}
