extends RefCounted

static func build() -> Dictionary:
	return {
		"context": {
			"AppRoot": preload("res://src/game/scene/main_scene/hfsm/app_root_entity.gd"),
		},
		"window": {
			"MainMenuWindow": preload("res://src/game/scene/main_scene/hfsm/windows/main_menu_window_entity.gd"),
			"LevelsWindow": preload("res://src/game/scene/main_scene/hfsm/windows/levels_window_entity.gd"),
			"LevelSelectWindow": preload("res://src/game/scene/main_scene/hfsm/windows/level_select_window_entity.gd"),
			"TrainingRoomWindow": preload("res://src/game/scene/main_scene/hfsm/windows/training_room_window_entity.gd"),
			"SettingsWindow": preload("res://src/game/scene/main_scene/hfsm/windows/settings_window_entity.gd"),
		},
	}
