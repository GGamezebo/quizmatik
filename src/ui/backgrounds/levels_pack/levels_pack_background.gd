extends Control

## Static notebook page for the level-pack carousel (grid paper + margin doodles).

@onready var _paper: TextureRect = $Paper


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_fit_paper)
	_fit_paper()


func _fit_paper() -> void:
	if _paper == null:
		return
	_paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
