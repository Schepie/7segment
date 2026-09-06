// ==============================================================================
// Games & Sets Indicator Module (Pogo Pin Edition) - "games_sets_pogo.scad"
// (Also available as "games_sets_pogo_snap_carrier_ladder.scad")
// ==============================================================================

include <./games_sets_pogo_snap_carrier_ladder.scad>

// Legacy alias for compatibility with dependent scoreboard assemblies
module games_sets_frontplate_white() {
    games_sets_snap_carrier_ladder();
}
