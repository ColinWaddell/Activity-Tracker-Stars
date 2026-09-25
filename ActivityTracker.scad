$fn = 50;

token_width = 30;
token_height = 35;
token_depth = 6;
inset = 1;
thickness = 3;
spacing = 3;
tokens = 3;
eps = 0.01;
case_or_token = "case";

module rounded_star(x=50, y=50, z=5, points=5, rounding=1) {
    inner_ratio = 0.45;

    linear_extrude(height=z)
        offset(r=rounding)
            offset(delta=-rounding)
                polygon([
                    for (i = [0 : points * 2 - 1])
                        let(
                            angle = 90 + i * 180 / points,
                            r = (i % 2 == 0) ? 1 : inner_ratio
                        )
                        [
                            (x / 2) * r * cos(angle),
                            (y / 2) * r * sin(angle)
                        ]
                ]);
}

module window(x)
{
    translate([x, 0, 0])
        difference(){
            cube([
                token_width + (spacing * 2),
                token_width,
                token_depth + thickness
            ]);
            translate([spacing, thickness, thickness + eps])
                cube([
                    token_width,
                    token_width + eps,
                    token_depth        
                ]);
            translate([spacing + (token_width / 2), (token_width / 2), -eps])
                rounded_star(token_width, token_width, 100, 5, 2);
        }

}

module windows(){
    for(i = [0:tokens - 1]){
        x_pos = i * ((spacing) + token_width);
        window(x_pos);
    }    
}

// Draw everything
if (case_or_token == "case"){
    // Dookets
    windows();

    // Back Panel
    translate([0, (2 * token_width) + 5, token_depth * 2])
        rotate([180, 0, 0])
            difference(){
                // Back panel
                translate([0, 0, thickness + token_depth - inset])
                    cube([(token_width * tokens) + (spacing * (tokens + 1)), token_width, thickness + inset]);

                windows();
            }
            
    // Tokens
    for(i = [0:tokens - 1]){
        x_pos = i * ((spacing) + token_width);
        translate([x_pos + spacing, (2 * token_width) + 10, 0])
            cube([token_width - inset, token_height, (token_depth - inset) / 2]);
    } 
}
else {
    cube([token_width - inset, token_height, (token_depth - inset) / 3]);
}

