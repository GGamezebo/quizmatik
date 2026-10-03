shader_type canvas_item;

// Graph-paper lines over whatever is below (ColorRect overlay). Cheap: no textures.
// rect_size = ColorRect size in canvas pixels (set from script) so cells stay square.
uniform vec2 rect_size = vec2(1280.0, 720.0);
uniform float cell_px = 32.0;
uniform float line_px = 1.5;
uniform vec4 line_color : source_color = vec4(0.42, 0.55, 0.72, 0.22);
uniform float margin_x_px = 96.0;
uniform vec4 margin_color : source_color = vec4(0.85, 0.35, 0.35, 0.35);

void fragment() {
	vec2 px = UV * rect_size;
	vec2 g = mod(px, cell_px);
	float grid = step(g.x, line_px) + step(g.y, line_px);
	float margin = step(abs(px.x - margin_x_px), line_px);
	vec4 col = line_color * clamp(grid, 0.0, 1.0);
	COLOR = mix(col, margin_color, margin);
}
