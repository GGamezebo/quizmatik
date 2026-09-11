class_name ValleyBackgroundArt
extends RefCounted

## Maps campaign container_id → valley BackgroundBase scene.

const SCENES: Dictionary = {
	"addition": preload("res://src/ui/backgrounds/valley_addition/valley_addition_background.tscn"),
	"subtraction": preload("res://src/ui/backgrounds/valley_subtraction/valley_subtraction_background.tscn"),
	"multiplication": preload("res://src/ui/backgrounds/valley_multiplication/valley_multiplication_background.tscn"),
	"division": preload("res://src/ui/backgrounds/valley_division/valley_division_background.tscn"),
	"mix": preload("res://src/ui/backgrounds/valley_mix/valley_mix_background.tscn"),
}


static func get_scene(container_id: String) -> PackedScene:
	return SCENES.get(container_id) as PackedScene


static func pick_random_scene() -> PackedScene:
	var ids: Array = SCENES.keys()
	if ids.is_empty():
		return null
	return SCENES[ids[randi() % ids.size()]] as PackedScene
