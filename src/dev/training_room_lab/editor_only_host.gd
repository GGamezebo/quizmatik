extends MarginContainer

## Shows only when running the project from the Godot editor (F5/F6).

func _ready() -> void:
	visible = OS.has_feature("editor")
