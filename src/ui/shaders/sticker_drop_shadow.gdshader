shader_type canvas_item;

// Soft drop shadow for TextureButton / TextureRect / Sprite2D.
// Tip: leave transparent padding in the texture so the shadow is not clipped.

/// Pixels: light from top-left → shadow down-right.
uniform vec2 shadow_offset = vec2(-5.0, 10.0);
/// Shadow tint and strength.
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
/// Fake blur radius in pixels (4-corner sample).
uniform float shadow_blur : hint_range(0.0, 20.0) = 2.0;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);

	vec2 text_size = vec2(textureSize(TEXTURE, 0));
	vec2 uv_offset = shadow_offset / text_size;

	float alpha_shadow = 0.0;
	alpha_shadow += texture(TEXTURE, UV - uv_offset + vec2(-shadow_blur, -shadow_blur) / text_size).a;
	alpha_shadow += texture(TEXTURE, UV - uv_offset + vec2(shadow_blur, -shadow_blur) / text_size).a;
	alpha_shadow += texture(TEXTURE, UV - uv_offset + vec2(-shadow_blur, shadow_blur) / text_size).a;
	alpha_shadow += texture(TEXTURE, UV - uv_offset + vec2(shadow_blur, shadow_blur) / text_size).a;
	alpha_shadow /= 4.0;

	vec4 final_shadow = vec4(shadow_color.rgb, alpha_shadow * shadow_color.a);

	COLOR = mix(final_shadow, original_color, original_color.a);
}
