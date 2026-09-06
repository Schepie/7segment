// Highlights direct overlapping / colliding volume between two parts in bright Red.
// Automatically renders both parts in translucent background context (%) for spatial reference.
// coplanar_offset: Shifts Part B by a tiny margin (default 5 microns) to distinguish true 3D
// physical penetration from mathematically coplanar touching faces at joint seams (Z = 0).
module show_collision(show_context = true, coplanar_offset = 0.005) {
    // Overlapping volume highlighted in Red
    color("Red") 
    intersection() {
        render() children(0);
        if (coplanar_offset != 0) {
            translate([0, 0, -coplanar_offset]) render() children(1);
        } else {
            render() children(1);
        }
    }
    
    // Background context (translucent ghosting)
    if (show_context) {
        %render() children(0);
        %render() children(1);
    }
}

// Highlights anywhere Part B violates the minimum clearance gap around Part A in Magenta.
// E.g., if clearance = 0.2mm, any area where the gap is < 0.2mm will be highlighted.
module check_clearance(gap = 0.2, show_context = true) {
    color("Magenta")
    intersection() {
        minkowski() {
            render() children(0);
            sphere(r = gap, $fn = 8);
        }
        render() children(1);
    }
    
    if (show_context) {
        %render() children(0);
        %render() children(1);
    }
}

// Cross-section cutaway view to inspect internal seating, wire channels, and snap joints.
// axis: "x" (removes +X half), "-x" (removes -X half), "y", "-y", "z", "-z"
module cutaway(axis = "x", cut_depth = 0, size = 1000) {
    difference() {
        children();
        
        if (axis == "x" || axis == "+x") {
            translate([cut_depth, -size/2, -size/2]) cube([size, size, size]);
        } else if (axis == "-x") {
            translate([cut_depth - size, -size/2, -size/2]) cube([size, size, size]);
        } else if (axis == "y" || axis == "+y") {
            translate([-size/2, cut_depth, -size/2]) cube([size, size, size]);
        } else if (axis == "-y") {
            translate([-size/2, cut_depth - size, -size/2]) cube([size, size, size]);
        } else if (axis == "z" || axis == "+z") {
            translate([-size/2, -size/2, cut_depth]) cube([size, size, size]);
        } else if (axis == "-z") {
            translate([-size/2, -size/2, cut_depth - size]) cube([size, size, size]);
        }
    }
}

// 2D cross-section slice at a specific Z height for measuring mating gaps
module slice_2d(cut_z = 0) {
    projection(cut = true) {
        translate([0, 0, -cut_z]) {
            children();
        }
    }
}
