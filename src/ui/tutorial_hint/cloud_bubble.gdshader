shader_type canvas_item;

// Semi-transparent cloud bubble: one SDF (rounded core + puffs on top/bottom/sides),
// so overlapping puffs never double the alpha. `rect_size` is set by TutorialHint.

uniform vec2 rect_size = vec2(300.0, 100.0);
uniform vec4 fill_color : source_color = vec4(1.0, 0.99, 0.96, 1.0);
// Alpha fades from the rim (edge_alpha) to the text area (core_alpha) over `fade_depth` px.
uniform float edge_alpha : hint_range(0.0, 1.0) = 0.45;
uniform float core_alpha : hint_range(0.0, 1.0) = 0.85;
uniform float fade_depth = 22.0;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 0.7);
uniform float outline_width = 3.0;
uniform float puff_radius = 38.0;
uniform float blend = 8.0;

float sd_round_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float smin(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
}

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 p = UV * rect_size;
	float w = rect_size.x;
	float h = rect_size.y;
	float r = min(puff_radius, h * 0.34);

	float d = sd_round_box(p - rect_size * 0.5, rect_size * 0.5 - vec2(r * 0.55), r * 0.7);

	int n = max(2, int((w - 2.0 * r) / (1.7 * r)) + 1);
	float step_x = (w - 2.2 * r) / float(n - 1);
	for (int i = 0; i < 24; i++) {
		if (i >= n) {
			break;
		}
		float x = r * 1.1 + float(i) * step_x;
		float top_r = r * (0.8 + 0.2 * hash(float(i) + 1.0));
		float bottom_r = r * (0.72 + 0.2 * hash(float(i) + 31.0));
		d = smin(d, length(p - vec2(x, top_r)) - top_r, blend);
		if (i < n - 1) {
			d = smin(d, length(p - vec2(x + step_x * 0.5, h - bottom_r)) - bottom_r, blend);
		}
	}
	float side_r = min(h * 0.5 - 1.0, r * 1.1);
	d = smin(d, length(p - vec2(side_r, h * 0.5)) - side_r, blend);
	d = smin(d, length(p - vec2(w - side_r, h * 0.5)) - side_r, blend);

	float inside = clamp(0.5 - d, 0.0, 1.0);
	float line = clamp(0.5 - abs(d + outline_width * 0.5) + outline_width * 0.5, 0.0, 1.0);
	vec4 fill = fill_color;
	fill.a *= mix(edge_alpha, core_alpha, smoothstep(0.0, fade_depth, -d));
	vec4 col = mix(fill, outline_color, line);
	col.a *= inside;
	COLOR = col;
}
