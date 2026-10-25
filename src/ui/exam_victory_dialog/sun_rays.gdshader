shader_type canvas_item;

// Slowly turning sun rays fading out from the center (behind a celebrated icon).
uniform vec4 ray_color : source_color = vec4(1.0, 0.76, 0.24, 0.9);
uniform float rays = 12.0;
uniform float speed = 0.35;
uniform float softness = 0.25;

void fragment() {
	vec2 p = UV - 0.5;
	float r = length(p) * 2.0;
	float a = atan(p.y, p.x) + TIME * speed;
	float ray = smoothstep(-softness, softness, sin(a * rays));
	float fade = 1.0 - smoothstep(0.25, 1.0, r);
	COLOR = vec4(ray_color.rgb, ray_color.a * ray * fade);
}
