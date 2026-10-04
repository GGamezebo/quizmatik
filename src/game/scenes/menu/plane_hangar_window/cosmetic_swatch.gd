class_name CosmeticSwatch
extends Control

## Tiny preview drawing for trail / shot items (dots in the item's style, ink drips in its colors).

@export var sample_count: int = 7

var _item: CosmeticItem = null


func set_item(item: CosmeticItem) -> void:
	_item = item
	queue_redraw()


func _draw() -> void:
	if _item is TrailItem:
		_draw_trail(_item as TrailItem)
	elif _item is ShotItem:
		_draw_shot(_item as ShotItem)


func _draw_trail(trail: TrailItem) -> void:
	if trail.style == TrailItem.Style.NONE:
		_draw_none()
		return
	var y := size.y * 0.5
	var step := size.x / float(sample_count + 1)
	for i in sample_count:
		var point := Vector2(step * (i + 1), y)
		var color := trail.color
		if trail.style == TrailItem.Style.RAINBOW:
			color = Color.from_hsv(float(i) / float(sample_count), 0.6, 0.95, color.a)
		elif not trail.palette.is_empty():
			color = trail.palette[i % trail.palette.size()]
		color.a *= 0.4 + 0.6 * float(i) / float(sample_count)
		var radius := minf(trail.width, size.y * 0.3)
		match trail.style:
			TrailItem.Style.DASH:
				if i % 2 == 0:
					draw_line(point, point + Vector2(step, 0.0), color, radius, true)
			TrailItem.Style.CRAYON:
				for k in 3:
					var offset := Vector2.from_angle(float(i * 7 + k * 13) / 17.0 * TAU) * radius * 0.45
					draw_circle(point + offset, radius * (0.7 + 0.1 * k), Color(color, color.a * 0.55))
			_:
				draw_circle(point, radius, color)


func _draw_shot(shot: ShotItem) -> void:
	var count := 5
	var step := size.x / float(count + 1)
	# Stable look per item: own RNG, never reseeds the global one.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(shot.id)
	for i in count:
		var center := Vector2(step * (i + 1), size.y * (0.35 + 0.3 * float(i % 2)))
		var color := Color(0.1, 0.14, 0.3, 0.85)
		if not shot.ink_colors.is_empty():
			color = shot.ink_colors[rng.randi() % shot.ink_colors.size()]
			color.a = maxf(color.a, 0.75)
		if shot.drip_texture != null:
			var side := size.y * 0.42
			draw_texture_rect(shot.drip_texture, Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side)), false, color)
		else:
			var radius := size.y * rng.randf_range(0.11, 0.18)
			draw_circle(center, radius, color)
			draw_circle(center + Vector2(radius * 0.8, radius * 0.5), radius * 0.45, color)


## Crossed-out circle for «none» items.
func _draw_none() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.28
	var ink := Color(0.165, 0.2, 0.251, 0.45)
	draw_arc(center, radius, 0.0, TAU, 32, ink, 3.0, true)
	draw_line(center + Vector2(-radius, radius) * 0.7, center + Vector2(radius, -radius) * 0.7, ink, 3.0, true)
