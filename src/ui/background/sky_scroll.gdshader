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
	COLOR = texture(TEXTURE, vec2(x, UV.y));
}
