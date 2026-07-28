shader_type canvas_item;

// Horizontal offset in UV space, driven by background.gd.
// The [0..2] range is folded back on itself so the texture scrolls endlessly
// through a mirrored copy instead of showing a hard seam at the edges.
uniform float scroll_offset = 0.0;

void fragment() {
	float x = mod(UV.x + scroll_offset, 2.0);
	if (x > 1.0) {
		x = 2.0 - x;
	}
	vec4 col = texture(TEXTURE, vec2(x, UV.y));
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray), col.a);
}
