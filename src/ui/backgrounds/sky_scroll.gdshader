shader_type canvas_item;

// Dual modes:
// - mirror_seamless: endless scroll via mirrored copy (classic sky, no hard seam).
// - else: current TEXTURE then next_texture side-by-side (notebook sketch cycle).
// color_amount 0 = washed graphite, 1 = full clear paint.
// subdue is the max wash at color_amount 0; it fades out as clarity rises.
uniform float scroll_offset = 0.0;
uniform float color_amount = 0.0;
uniform float subdue : hint_range(0.0, 1.0) = 0.82;
uniform vec3 paper_tint = vec3(0.953, 0.902, 0.784);
uniform bool mirror_seamless = false;
uniform sampler2D next_texture : source_color, hint_default_white;
// Aspect "cover" crop (set by BackgroundBase on resize): uv = UV * cover_scale + cover_offset.
uniform vec2 cover_scale = vec2(1.0);
uniform vec2 cover_offset = vec2(0.0);
// Chase level: left of drain_edge (screen share 0..1) the world fades back to washed graphite,
// soft over ±drain_softness. Default -1 = off.
uniform float drain_edge = -1.0;
uniform float drain_softness = 0.1;

void fragment() {
	vec2 uv = UV * cover_scale + cover_offset;
	vec4 col;
	if (mirror_seamless) {
		// Period 2: [0..1] normal, [1..2] mirrored — edges always match.
		float x = mod(uv.x + scroll_offset, 2.0);
		if (x > 1.0) {
			x = 2.0 - x;
		}
		col = texture(TEXTURE, vec2(x, uv.y));
	} else {
		float x = uv.x + scroll_offset;
		if (x < 1.0) {
			col = texture(TEXTURE, vec2(x, uv.y));
		} else {
			col = texture(next_texture, vec2(fract(x), uv.y));
		}
	}
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	float t = clamp(color_amount, 0.0, 1.0);
	t *= smoothstep(drain_edge - drain_softness, drain_edge + drain_softness, UV.x);
	vec3 rgb = mix(vec3(gray), col.rgb, t);
	float s = clamp(subdue, 0.0, 1.0) * (1.0 - t);
	float luma = dot(rgb, vec3(0.299, 0.587, 0.114));
	rgb = mix(rgb, vec3(mix(luma, 0.82, 0.55)), s * 0.78);
	rgb = mix(rgb, paper_tint, s * 0.68);
	COLOR = vec4(rgb, col.a);
}
