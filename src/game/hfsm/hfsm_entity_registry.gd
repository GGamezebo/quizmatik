class_name HfsmEntityRegistry
extends RefCounted

static func build() -> Dictionary:
	return {
		"window": [
			preload("res://src/game/windows/main_menu_window_entity.gd"),
			preload("res://src/game/windows/levels_window_entity.gd"),
			preload("res://src/game/windows/level_select_window_entity.gd"),
			preload("res://src/game/windows/training_room_window_entity.gd"),
			preload("res://src/game/windows/settings_window_entity.gd"),
		],
	}
