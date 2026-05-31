shader_type canvas_item;

// Смещение тени (в пикселях или относительных координатах)
uniform vec2 shadow_offset = vec2(10.0, 10.0);
// Цвет и прозрачность тени
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
// Размытие тени (работает как фейковый blur)
uniform float shadow_blur : hint_range(0.0, 20.0) = 2.0;

void fragment() {
	// Получаем цвет оригинального пикселя объекта
	vec4 original_color = texture(TEXTURE, UV);
	
	// Считаем шаг текстуры (размер пикселя в пространстве UV)
	vec2 text_size = vec2(textureSize(TEXTURE, 0));
	vec2 uv_offset = shadow_offset / text_size;
	
	// Сэмплируем альфа-канал со смещением для создания тени
	// Небольшое размытие за счет усреднения соседних пикселей
	float alpha_shadow = 0.0;
	alpha_shadow += texture(TEXTURE, UV - uv_offset + vec2(-shadow_blur, -shadow_blur) / text_size).a;
	alpha_shadow += texture(TEXTURE, UV - uv_offset + vec2(shadow_blur, -shadow_blur) / text_size).a;
	alpha_shadow += texture(TEXTURE, UV - uv_offset + vec2(-shadow_blur, shadow_blur) / text_size).a;
	alpha_shadow += texture(TEXTURE, UV - uv_offset + vec2(shadow_blur, shadow_blur) / text_size).a;
	alpha_shadow /= 4.0;
	
	// Формируем финальный цвет тени
	vec4 final_shadow = vec4(shadow_color.rgb, alpha_shadow * shadow_color.a);
	
	// Смешиваем оригинальную текстуру и тень (оригинал поверх тени)
	COLOR = mix(final_shadow, original_color, original_color.a);
}