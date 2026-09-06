use <7segment_v2.scad>

// Render an exploded view to see inside the light tunnels
translate([0, 0, 40]) color("White") frontplate_white();
color("DimGray") frontplate_black();
translate([0, 0, -40]) color("SlateGray") backplate();
