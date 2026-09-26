// ---------------------------------------------------------------------------
//  Star Activity Tracker
//
//  Model page: https://www.printables.com/model/1854921-star-activity-tracker
//
//  All dimensions are in millimetres.
//
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
//  Quality
// ---------------------------------------------------------------------------

$fn = 50;

// ---------------------------------------------------------------------------
//  Parameters
// ---------------------------------------------------------------------------

// Token
token_width = 30;   // square footprint of a token window
token_height = 35;  // token length; taller than the window so it can be gripped
token_depth = 6;    // window cavity depth
inset = 1;          // clearance shaved from token and cavity edges

// Case
thickness = 3;      // window floor and rear panel thickness
spacing = 3;        // gap between windows, also the width of a window's frame wall
tokens = 3;         // number of windows in the case

// Layout
eps = 0.01;          // fudge factor for clean boolean cuts
panel_clearance = 5; // gap between the window row and the rear panel
case_or_token = "case";

// Window star cut-out
star_points = 5;
star_corner_radius = 2; // softens the star's points
star_cut_height = 100;  // tall enough to punch through anything it meets

// ---------------------------------------------------------------------------
//  Derived dimensions
// ---------------------------------------------------------------------------

column_pitch = token_width + spacing;
case_length = tokens * column_pitch + spacing; // window row and panel width

// ---------------------------------------------------------------------------
//  Star
// ---------------------------------------------------------------------------

// An n-pointed star with rounded corners, extruded to height z
module rounded_star(x = 50, y = 50, z = 5, points = 5, rounding = 1, inner_ratio = 0.45) {
    linear_extrude(height = z)
        offset(r = rounding)
            offset(delta = -rounding)
                polygon([
                    for (i = [0 : 2 * points - 1])
                        let (
                            angle = 90 + i * 180 / points,
                            radius = (i % 2 == 0) ? 1 : inner_ratio
                        )
                            [
                                (x / 2) * radius * cos(angle),
                                (y / 2) * radius * sin(angle)
                            ]
                ]);
}

// ---------------------------------------------------------------------------
//  Token window
// ---------------------------------------------------------------------------

module window(x_offset) {
    translate([x_offset, 0, 0])
        difference() {
            cube([token_width + 2 * spacing, token_width, token_depth + thickness]);

            translate([spacing, thickness, thickness + eps])
                cube([token_width, token_width + eps, token_depth]);

            translate([spacing + token_width / 2, token_width / 2, -eps])
                rounded_star(token_width, token_width, star_cut_height, star_points, star_corner_radius);
        }
}

// One window per token, pitched along x.
module windows() {
    for (i = [0 : tokens - 1])
        window(i * column_pitch);
}

// ---------------------------------------------------------------------------
//  Rear panel
// ---------------------------------------------------------------------------

// A flat panel sitting `panel_clearance` behind the window row. The token
// windows are subtracted from it, leaving shallow notches on its inner face
// where the window frames land.
module rear_panel() {
    translate([0, 2 * token_width + panel_clearance, 2 * token_depth])
        rotate([180, 0, 0])
            difference() {
                translate([0, 0, thickness + token_depth - inset])
                    cube([case_length, token_width, thickness + inset]);

                windows();
            }
}

// ---------------------------------------------------------------------------
//  Tokens
// ---------------------------------------------------------------------------

module blank_tokens() {
    for (i = [0 : tokens - 1])
        translate([i * column_pitch + spacing, 2 * token_width + 2 * panel_clearance, 0])
            cube([token_width - inset, token_height, (token_depth - inset) / 2]);
}

module highlighted_token() {
    cube([token_width - inset, token_height, (token_depth - inset) / 3]);
}

// ---------------------------------------------------------------------------
//  Top level
// ---------------------------------------------------------------------------

assert(tokens >= 1, "tokens must be 1 or more");
assert(
    case_or_token == "case" || case_or_token == "token",
    "case_or_token must be \"case\" or \"token\""
);

if (case_or_token == "case") {
    windows();
    rear_panel();
    blank_tokens();
} else {
    highlighted_token();
}

