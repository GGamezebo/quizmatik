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

void fragment() {
	vec4 col;
	if (mirror_seamless) {
		// Period 2: [0..1] normal, [1..2] mirrored — edges always match.
		float x = mod(UV.x + scroll_offset, 2.0);
		if (x > 1.0) {
			x = 2.0 - x;
		}
		col = texture(TEXTURE, vec2(x, UV.y));
	} else {
		float x = UV.x + scroll_offset;
		if (x < 1.0) {
			col = texture(TEXTURE, vec2(x, UV.y));
		} else {
			col = texture(next_texture, vec2(fract(x), UV.y));
		}
	}
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	float t = clamp(color_amount, 0.0, 1.0);
	vec3 rgb = mix(vec3(gray), col.rgb, t);
	float s = clamp(subdue, 0.0, 1.0) * (1.0 - t);
	float luma = dot(rgb, vec3(0.299, 0.587, 0.114));
	rgb = mix(rgb, vec3(mix(luma, 0.82, 0.55)), s * 0.78);
	rgb = mix(rgb, paper_tint, s * 0.68);
	COLOR = vec4(rgb, col.a);
}
