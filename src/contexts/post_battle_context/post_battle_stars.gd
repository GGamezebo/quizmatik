class_name PostBattleStars
extends HBoxContainer

const STAR_FILLED_COLOR := Color(1.0, 0.84, 0.2, 1.0)
const STAR_EMPTY_COLOR := Color(0.35, 0.42, 0.55, 0.45)

@export var stars: Array[TextureRect] = []

func show_stars(count: int, animate: bool = true) -> void:
	for index in range(stars.size()):
		var star: TextureRect = stars[index]
		var is_filled: bool = index < count
		star.visible = true
		star.modulate = STAR_FILLED_COLOR if is_filled else STAR_EMPTY_COLOR
		star.scale = Vector2.ONE
		star.pivot_offset = star.custom_minimum_size * 0.5
		if animate and is_filled:
			_animate_star(star, index)

func _animate_star(star: TextureRect, index: int) -> void:
	star.scale = Vector2.ZERO
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "scale", Vector2.ONE, 0.35).set_delay(index * 0.12)
