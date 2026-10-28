shader_type canvas_item;

// Plane body: soft drop shadow (same as sticker_drop_shadow) + tint + procedural paint pattern.
// Pattern lives in local sprite pixels (works on atlas frames) and only covers colored pencil
// fill: dark outline and white sticker edge stay untouched.

uniform vec2 shadow_offset = vec2(-5.0, 10.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform float shadow_blur : hint_range(0.0, 20.0) = 2.0;
uniform vec4 sprite_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

/// `PaintItem.Pattern`: 0 none, 1 stripes, 2 dots, 3 checker, 4 stars, 5 zigzag, 6 watercolor, 7 rainbow,
/// 8 math signs, 9 tiger, 10 giraffe, 11 diamonds, 12 scales, 13 galaxy.
uniform int paint_pattern = 0;
/// Alpha 0 = keep the plane's own color there.
uniform vec4 paint_color_a : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform vec4 paint_color_b : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float paint_cell_px = 18.0;
uniform float paint_strength : hint_range(0.0, 1.0) = 0.75;
/// Sprite `offset` (battle shake moves the body by offset): the pattern must ride on the body.
uniform vec2 paint_offset = vec2(0.0);

varying vec2 local_px;

void vertex() {
	local_px = VERTEX - paint_offset;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
	return vec2(hash(p), hash(p + vec2(17.3, 9.1)));
}

vec2 rotate(vec2 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

/// Rounded box: `half_size` = half extents, `r` = corner radius.
float box_sdf(vec2 p, vec2 half_size, float r) {
	vec2 d = abs(p) - half_size + r;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

/// Math sign in a unit cell (`f` in -0.5..0.5): 0 plus, 1 minus, 2 times, 3 divide.
float sign_sdf(vec2 f, int kind) {
	vec2 g = f;
	if (kind == 2) {
		g = rotate(f, 0.785398);
	}
	float bar = box_sdf(g, vec2(0.3, 0.085), 0.08);
	if (kind == 0 || kind == 2) {
		return min(bar, box_sdf(g, vec2(0.085, 0.3), 0.08));
	}
	if (kind == 3) {
		float dots = min(length(g - vec2(0.0, 0.22)), length(g + vec2(0.0, 0.22))) - 0.085;
		return min(box_sdf(g, vec2(0.28, 0.07), 0.07), dots);
	}
	return bar;
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
	} else if (paint_pattern == 8) {
		// + − × ÷ on a staggered grid, each slightly tilted like chalk.
		vec2 cell = q + vec2(0.5 * mod(floor(q.y), 2.0), 0.0);
		vec2 id = floor(cell);
		int kind = int(mod(id.x + id.y * 3.0, 4.0) + 0.5);
		vec2 f = rotate(fract(cell) - 0.5, (hash(id) - 0.5) * 0.45);
		p = 1.0 - smoothstep(-0.02, 0.03, sign_sdf(f, kind));
	} else if (paint_pattern == 9) {
		// Vertical stripes bent by noise, thickness tapering along the body.
		float w = q.x * 0.55 + value_noise(vec2(q.x * 0.35, q.y * 0.8)) * 1.1;
		float band = abs(fract(w) - 0.5) * 2.0;
		float thick = 0.2 + 0.24 * value_noise(q * vec2(0.5, 1.3) + 5.0);
		p = 1.0 - smoothstep(thick - 0.08, thick + 0.04, band);
	} else if (paint_pattern == 10) {
		// Voronoi patches (color b) split by cream seams (color a).
		vec2 id = floor(q);
		float f1 = 8.0;
		float f2 = 8.0;
		for (int j = -1; j <= 1; j++) {
			for (int i = -1; i <= 1; i++) {
				vec2 c = id + vec2(float(i), float(j));
				float d = length(q - c - 0.15 - 0.7 * hash2(c));
				if (d < f1) {
					f2 = f1;
					f1 = d;
				} else if (d < f2) {
					f2 = d;
				}
			}
		}
		p = smoothstep(0.12, 0.2, f2 - f1);
	} else if (paint_pattern == 11) {
		// Harlequin diamonds with a thin darker seam.
		vec2 r = vec2(q.x + q.y * 0.7, q.x - q.y * 0.7);
		vec2 fr = fract(r);
		float seam = min(min(fr.x, 1.0 - fr.x), min(fr.y, 1.0 - fr.y));
		vec4 tile = mix(paint_color_a, paint_color_b, mod(floor(r.x) + floor(r.y), 2.0));
		return vec4(tile.rgb * (1.0 - 0.3 * (1.0 - smoothstep(0.02, 0.07, seam))), tile.a);
	} else if (paint_pattern == 12) {
		// Overlapping scales: row above lies on top, rim (color b) darkens toward the edge.
		float row_h = 0.62;
		float row0 = floor(q.y / row_h);
		float d = 1.0;
		for (int k = 0; k <= 1; k++) {
			float row = row0 + float(k);
			float shift = 0.5 * mod(row, 2.0);
			vec2 c = vec2(floor(q.x - shift + 0.5) + shift, row * row_h);
			float dist = length(q - c) / 0.6;
			if (dist < 1.0) {
				d = dist;
				break;
			}
		}
		p = smoothstep(0.45, 1.0, d);
	} else if (paint_pattern == 13) {
		// Nebula between both colors + scattered white stars.
		float n = value_noise(q * 0.7) * 0.6 + value_noise(q * 1.9 + 3.0) * 0.3 + value_noise(q * 4.3) * 0.1;
		vec3 sky = mix(paint_color_a.rgb, paint_color_b.rgb, smoothstep(0.3, 0.75, n));
		vec2 star_cell = floor(q * 2.0);
		vec2 star_f = fract(q * 2.0) - 0.5 - (hash2(star_cell) - 0.5) * 0.5;
		float star = step(0.78, hash(star_cell)) * (1.0 - smoothstep(0.08, 0.2, length(star_f)));
		return vec4(mix(sky, vec3(1.0, 0.98, 0.9), star), 1.0);
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
