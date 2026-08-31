use <7segment_v2.scad>

// Flip the frontplate over so we can see the deep light tunnels inside
rotate([180, 0, 0]) {
    color("DimGray") frontplate_black();
    color("White") frontplate_white();
}
