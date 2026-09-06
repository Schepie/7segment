// A simple 3D printing test piece - a hollow cube with a sphere cutout
difference() {
    // Main block
    cube([20, 20, 20], center = true);
    
    // Hollow inside
    sphere(r = 12, $fn=100);
}
