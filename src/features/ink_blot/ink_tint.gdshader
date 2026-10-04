shader_type canvas_item;

// Colored shot ink: the blot keeps its shape (texture alpha) but takes the modulate color,
// so bright inks (red, green, rainbow) survive the dark fountain-ink atlas.

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Slight soak variation from the original stroke darkness.
	float soak = 0.85 + 0.3 * (1.0 - dot(tex.rgb, vec3(0.333)));
	COLOR = vec4(tint.rgb * soak, tint.a * tex.a);
}
