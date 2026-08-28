class_name ValleyTrophyArt
extends RefCounted

## Valley exam trophies for the achievements window and exam victory popup.

const TROPHIES: Dictionary = {
	"addition": preload("res://src/game/scenes/menu/trophy_room_window/ui/trophies/trophy_addition.png"),
	"subtraction": preload("res://src/game/scenes/menu/trophy_room_window/ui/trophies/trophy_subtraction.png"),
	"multiplication": preload("res://src/game/scenes/menu/trophy_room_window/ui/trophies/trophy_multiplication.png"),
	"division": preload("res://src/game/scenes/menu/trophy_room_window/ui/trophies/trophy_division.png"),
	"mix": preload("res://src/game/scenes/menu/trophy_room_window/ui/trophies/trophy_mix.png"),
}

const LOCKED_TROPHY: Texture2D = preload(
	"res://src/game/scenes/menu/trophy_room_window/ui/trophies/trophy_locked.png"
)

const SHORT_NAMES: Dictionary = {
	"addition": "Сложение",
	"subtraction": "Вычитание",
	"multiplication": "Умножение",
	"division": "Деление",
	"mix": "Смешение",
}

const CONTAINER_ORDER: Array[String] = [
	"addition",
	"subtraction",
	"multiplication",
	"division",
	"mix",
]


static func get_trophy(container_id: String) -> Texture2D:
	return TROPHIES.get(container_id) as Texture2D


static func get_locked_trophy() -> Texture2D:
	return LOCKED_TROPHY


static func get_short_name(container_id: String) -> String:
	return SHORT_NAMES.get(container_id, container_id)


static func get_container_ids() -> Array[String]:
	return CONTAINER_ORDER.duplicate()
