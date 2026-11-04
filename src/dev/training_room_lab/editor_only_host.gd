extends MarginContainer

## Shows only in the Godot editor (F5/F6) or a `dev_lab` test export (`DevBuild`).

func _ready() -> void:
	visible = DevBuild.is_enabled()
