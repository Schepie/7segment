// =============================================================================
// Padel Court Wire Mesh Battery Pack Holder - VESA 50x50 Direct Screw Mount
// Designed for Action Art. No. 3222798 (Sitecom 20,000mAh 30W Powerbank)
// Mounts directly to 50x50 mm VESA pattern on 7-Segment Scoreboard Backplates
// =============================================================================

// Force VESA 50x50 direct screw-mount configuration (no hooks, flush rear face)
mount_type = "vesa";
front_access_holes = true;    // 7mm pass-through holes for top screw access
screw_style = "countersunk";  // Flush M3 DIN 7991 countersunk cone inside cavity

// Visibility options
show_holder = true;
show_battery_preview = false;
show_backplate_preview = false;

// Include the master battery holder definitions & modules
include <padel_battery_holder.scad>
