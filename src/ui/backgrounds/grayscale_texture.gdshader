shader_type canvas_item;

/// Grayscale for standalone background textures (loading screen, overlays).

void fragment() {
	vec4 col = texture(TEXTURE, UV) * COLOR;
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray), col.a);
}
