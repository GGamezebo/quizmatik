extends Button

const STAR_FILLED_COLOR := Color(1.0, 0.84, 0.2, 1.0)
const STAR_EMPTY_COLOR := Color(0.35, 0.42, 0.55, 0.45)

@export var text_lable: Label
@export var stars: Array[TextureRect]
var is_exam: bool = false

func initialize(level_id: int, is_unlocked: bool, stars_count: int, _is_exam: bool) -> void:
	text_lable.text = str(level_id)
	is_exam = _is_exam
	_set_params(is_unlocked, stars_count)
	
func set_params(is_unlocked: bool, stars_count: int) -> void:
	_set_params(is_unlocked, stars_count)
	
func _set_params(is_unlocked: bool, stars_count: int) -> void:
	for i in range(stars.size()):
		if not is_unlocked:
			stars[i].visible = false
			continue
		stars[i].visible = true
		stars[i].modulate = STAR_FILLED_COLOR if i < stars_count else STAR_EMPTY_COLOR

	disabled = not is_exam and not is_unlocked
