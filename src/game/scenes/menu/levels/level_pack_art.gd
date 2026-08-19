class_name LevelPackArt
extends RefCounted

## Maps container_id → card art.
## Exam stamps are selected by achieved stars (1..3).

const ARTS: Dictionary = {
	"addition": preload("res://src/game/scenes/menu/levels/ui/valleys/valley_addition.png"),
	"subtraction": preload("res://src/game/scenes/menu/levels/ui/valleys/valley_subtraction.png"),
	"multiplication": preload("res://src/game/scenes/menu/levels/ui/valleys/valley_multiplication.png"),
	"division": preload("res://src/game/scenes/menu/levels/ui/valleys/valley_division.png"),
	"mix": preload("res://src/game/scenes/menu/levels/ui/valleys/valley_mix.png"),
}

const STAMPS_BY_STARS: Dictionary = {
	1: preload("res://src/game/scenes/post_battle/ui/stamp_sun.png"),      # fun
	2: preload("res://src/game/scenes/post_battle/ui/stamp_flower.png"),   # epic
	3: preload("res://src/game/scenes/post_battle/ui/stamp_cat.png"),      # super
}


static func get_art(container_id: String) -> Texture2D:
	return ARTS.get(container_id) as Texture2D


static func get_exam_stamp(stars: int) -> Texture2D:
	var s := clampi(stars, 0, 3)
	if s <= 0:
		return null
	return STAMPS_BY_STARS.get(s) as Texture2D
