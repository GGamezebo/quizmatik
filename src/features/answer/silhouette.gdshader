shader_type canvas_item;

// Flat-color silhouette of the texture (sticker outline when drawn scaled-up behind the original).
uniform vec4 color : source_color = vec4(1.0);

void fragment() {
	COLOR = vec4(color.rgb, texture(TEXTURE, UV).a * color.a);
}
