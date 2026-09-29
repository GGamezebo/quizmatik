shader_type canvas_item;

// Screen dim with up to 4 rounded, feathered holes + a soft glow ring around each hole.
// Holes are in the node's local pixels: (x, y, w, h).

uniform vec2 rect_size = vec2(1280.0, 720.0);
uniform vec4 dim_color : source_color = vec4(0.06, 0.08, 0.12, 0.62);
uniform vec4 ring_color : source_color = vec4(1.0, 0.95, 0.75, 0.85);
uniform float ring_width = 3.0;
uniform float corner_radius = 18.0;
uniform float feather = 6.0;
uniform int hole_count = 0;
uniform vec4 holes[4];

float sd_round_box(vec2 p, vec2 half_size, float r) {
	r = min(r, min(half_size.x, half_size.y));
	vec2 q = abs(p) - half_size + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = UV * rect_size;
	float d = 1e6;
	for (int i = 0; i < 4; i++) {
		if (i >= hole_count) {
			break;
		}
		vec4 h = holes[i];
		d = min(d, sd_round_box(p - (h.xy + h.zw * 0.5), h.zw * 0.5, corner_radius));
	}
	float dim = smoothstep(-feather * 0.5, feather * 0.5, d);
	float ring = hole_count > 0 ? 1.0 - smoothstep(0.0, ring_width, abs(d - ring_width)) : 0.0;
	vec4 col = vec4(dim_color.rgb, dim_color.a * dim);
	COLOR = mix(col, ring_color, ring * ring_color.a);
}
