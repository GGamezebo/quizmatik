shader_type canvas_item;

// Seamless horizontal flight: current TEXTURE then next_texture side-by-side in UV.
// color_amount 0 = graphite sketch, 1 = full paint (driven by correct answers).
uniform float scroll_offset = 0.0;
uniform float color_amount = 0.0;
uniform sampler2D next_texture : source_color, hint_default_white;

void fragment() {
	float x = UV.x + scroll_offset;
	vec4 col;
	if (x < 1.0) {
		col = texture(TEXTURE, vec2(x, UV.y));
	} else {
		col = texture(next_texture, vec2(fract(x), UV.y));
	}
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	float t = clamp(color_amount, 0.0, 1.0);
	vec3 rgb = mix(vec3(gray), col.rgb, t);
	COLOR = vec4(rgb, col.a);
}
