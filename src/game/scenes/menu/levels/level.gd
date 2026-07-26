extends Button

@export var text_lable: Label
@export var stars: Array[TextureRect]
@export var star_empty: Texture2D
@export var star_filled: Texture2D
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
		stars[i].modulate = Color.WHITE
		stars[i].texture = star_filled if i < stars_count else star_empty

	disabled = not is_exam and not is_unlocked
