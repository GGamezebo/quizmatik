class_name LevelPackArt
extends RefCounted

## Maps container_id → card art and stamp textures for the pack carousel.

const ARTS: Dictionary = {
	"addition": preload("res://src/game/scenes/menu/levels/ui/valleys/valley_addition.png"),
	"subtraction": preload("res://src/game/scenes/menu/levels/ui/valleys/valley_subtraction.png"),
	"multiplication": preload("res://src/game/scenes/menu/levels/ui/valleys/valley_multiplication.png"),
	"division": preload("res://src/game/scenes/menu/levels/ui/valleys/valley_division.png"),
	"mix": preload("res://src/game/scenes/menu/levels/ui/valleys/valley_mix.png"),
}

const STAMPS: Dictionary = {
	"addition": preload("res://src/game/scenes/menu/levels/ui/stamp_sun.png"),
	"subtraction": preload("res://src/game/scenes/menu/levels/ui/stamp_flower.png"),
	"multiplication": preload("res://src/game/scenes/menu/levels/ui/stamp_cat.png"),
	"division": preload("res://src/game/scenes/menu/levels/ui/stamp_sun.png"),
	"mix": preload("res://src/game/scenes/menu/levels/ui/stamp_flower.png"),
}


static func get_art(container_id: String) -> Texture2D:
	return ARTS.get(container_id) as Texture2D


static func get_stamp(container_id: String) -> Texture2D:
	return STAMPS.get(container_id) as Texture2D
