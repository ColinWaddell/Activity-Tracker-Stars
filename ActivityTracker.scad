// ---------------------------------------------------------------------------
//  Star Activity Tracker
//
//  A row of recessed token windows, each with a star-shaped cut-out through
//  its floor, plus a rear panel and the tokens themselves. A window shows its
//  star when empty; seating a token in it covers the star.
//
//  Model page: https://www.printables.com/model/1854921-star-activity-tracker
//
//  All dimensions are in millimetres.
//
//  Render targets (see Makefile):
//      -D 'case_or_token="case"'  -D "tokens=N"   one display case, N windows
//      -D 'case_or_token="token"'                 a single printable token
//
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
//  Quality
// ---------------------------------------------------------------------------

// Fixed fragment count. It shapes the star's rounded corners, so changing it
// alters the rendered mesh, not just preview smoothness.
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
eps = 0.01;         // fudge factor for clean boolean cuts
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

// An n-pointed star with rounded corners, extruded to height z. The outline
// is shrunk by the corner radius and grown back out, which rounds every
// corner. inner_ratio sets how far the inner vertices sit from the outer
// ones: 0 gives sharp spikes, 1 collapses the star into a circle.
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

// One open-backed, open-topped tray sized to a token, with a star-shaped
// cut-out through its floor. The frame walls are `spacing` wide, the floor is
// `thickness` thick, and the cavity deliberately overshoots the back face so
// the window opens cleanly.
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
// where the window frames land. It is rotated about x and offset by twice
// the token depth so it lies flat on the build plate.
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

// Tokens displayed behind the case in the preview render. These are thicker
// than the printable token below.
module preview_tokens() {
    for (i = [0 : tokens - 1])
        translate([i * column_pitch + spacing, 2 * token_width + 2 * panel_clearance, 0])
            cube([token_width - inset, token_height, (token_depth - inset) / 2]);
}

// The printable token: a plain slab. The star motif comes from the cut-out
// in the window floor, not from the token itself.
module token() {
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
    preview_tokens();
} else {
    token();
}

