extends Button

@export var text_lable: Label
@export var stars: Array[TextureRect]

func initialize(level_id: int, is_unlocked: bool, stars_count: int) -> void:
	text_lable.text = str(level_id)
	_set_params(is_unlocked, stars_count)
	
func set_params(is_unlocked: bool, stars_count: int) -> void:
	_set_params(is_unlocked, stars_count)
	
func _set_params(is_unlocked: bool, stars_count: int):
	for i in range(stars.size()):
		if i < stars_count:
			stars[i].visible = true
		else:
			stars[i].visible = false
	
	self.disabled = not is_unlocked
