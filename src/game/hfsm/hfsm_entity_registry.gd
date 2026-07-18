class_name HfsmEntityRegistry
extends RefCounted

static func build() -> Dictionary:
	return {
		"window": {
			"MainMenuWindow": preload("res://src/game/hfsm/windows/main_menu_window_entity.gd"),
			"LevelsWindow": preload("res://src/game/hfsm/windows/levels_window_entity.gd"),
			"LevelSelectWindow": preload("res://src/game/hfsm/windows/level_select_window_entity.gd"),
			"TrainingRoomWindow": preload("res://src/game/hfsm/windows/training_room_window_entity.gd"),
			"SettingsWindow": preload("res://src/game/hfsm/windows/settings_window_entity.gd"),
		},
	}
