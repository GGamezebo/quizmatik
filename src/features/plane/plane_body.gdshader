shader_type canvas_item;

// Plane body: soft drop shadow (same as sticker_drop_shadow) + tint + procedural paint pattern.
// Pattern lives in local sprite pixels (works on atlas frames) and only covers colored pencil
// fill: dark outline and white sticker edge stay untouched.

uniform vec2 shadow_offset = vec2(-5.0, 10.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform float shadow_blur : hint_range(0.0, 20.0) = 2.0;
uniform vec4 sprite_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

/// `PaintItem.Pattern`: 0 none, 1 stripes, 2 dots, 3 checker, 4 stars, 5 zigzag, 6 watercolor, 7 rainbow.
uniform int paint_pattern = 0;
/// Alpha 0 = keep the plane's own color there.
uniform vec4 paint_color_a : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform vec4 paint_color_b : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float paint_cell_px = 18.0;
uniform float paint_strength : hint_range(0.0, 1.0) = 0.75;

varying vec2 local_px;

void vertex() {
	local_px = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

vec3 hue_to_rgb(float h) {
	vec3 k = clamp(abs(fract(h + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
	return mix(vec3(1.0), k, 0.75);
}

/// Pattern color at this pixel; alpha = how much it covers.
vec4 pattern_color(vec2 px) {
	vec2 q = px / max(paint_cell_px, 1.0);
	float p = 0.0;
	if (paint_pattern == 1) {
		p = smoothstep(0.45, 0.55, abs(fract((q.x + q.y) * 0.5) - 0.5) * 2.0);
	} else if (paint_pattern == 2) {
		vec2 cell = q + vec2(0.5 * mod(floor(q.y), 2.0), 0.0);
		p = 1.0 - smoothstep(0.24, 0.3, length(fract(cell) - 0.5));
	} else if (paint_pattern == 3) {
		p = mod(floor(q.x) + floor(q.y), 2.0);
	} else if (paint_pattern == 4) {
		vec2 cell = q + vec2(0.5 * mod(floor(q.y), 2.0), 0.0);
		vec2 f = fract(cell) - 0.5;
		float a = atan(f.x, -f.y);
		float r = length(f);
		float star_r = 0.17 + 0.13 * pow(abs(cos(a * 2.5)), 3.0);
		p = 1.0 - smoothstep(star_r - 0.02, star_r + 0.02, r);
	} else if (paint_pattern == 5) {
		float v = q.y + abs(fract(q.x) - 0.5);
		p = smoothstep(0.4, 0.5, abs(fract(v) - 0.5) * 2.0);
	} else if (paint_pattern == 6) {
		float n = value_noise(q) * 0.6 + value_noise(q * 2.3 + 7.0) * 0.3 + value_noise(q * 5.1) * 0.1;
		p = smoothstep(0.38, 0.62, n);
	} else if (paint_pattern == 7) {
		return vec4(hue_to_rgb(fract(px.x / max(paint_cell_px, 1.0) + px.y * 0.002)), 1.0);
	}
	return mix(paint_color_a, paint_color_b, p);
}

vec4 paint(vec4 base) {
	if (paint_pattern == 0) {
		return base;
	}
	float lum = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	float fill = smoothstep(0.2, 0.32, lum) * (1.0 - smoothstep(0.86, 0.95, lum)) * step(0.9, base.a);
	vec4 pc = pattern_color(local_px);
	vec3 recolored = pc.rgb * (0.35 + 0.85 * lum);
	return vec4(mix(base.rgb, recolored, fill * pc.a * paint_strength), base.a);
}

void fragment() {
	vec4 original_color = paint(texture(TEXTURE, UV) * sprite_tint);

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
