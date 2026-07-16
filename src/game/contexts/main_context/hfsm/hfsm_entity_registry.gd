extends RefCounted

const HFSM_CONFIG_PATH := "res://src/common/hfsm/app_hfsm.json"


static func build() -> Dictionary:
	return {
		"context": {
			"AppRoot": preload("res://src/game/contexts/main_context/hfsm/app_root_entity.gd"),
			"MenuContext": preload("res://src/game/contexts/main_context/hfsm/menu_context_entity.gd"),
			"GameContext": preload("res://src/game/contexts/main_context/hfsm/game_context_entity.gd"),
			"PostBattleContext": preload("res://src/game/contexts/main_context/hfsm/post_battle_context_entity.gd"),
		},
		"window": {
			"MainMenuWindow": preload("res://src/game/contexts/main_context/hfsm/windows/main_menu_window_entity.gd"),
			"LevelsWindow": preload("res://src/game/contexts/main_context/hfsm/windows/levels_window_entity.gd"),
			"LevelSelectWindow": preload("res://src/game/contexts/main_context/hfsm/windows/level_select_window_entity.gd"),
			"TrainingRoomWindow": preload("res://src/game/contexts/main_context/hfsm/windows/training_room_window_entity.gd"),
			"SettingsWindow": preload("res://src/game/contexts/main_context/hfsm/windows/settings_window_entity.gd"),
		},
		"scene": {
			"GameScene": preload("res://src/game/scenes/game_scene/game_scene.gd"),
			# "MenuScene": preload("res://src/game/scenes/menu_scene/menu_scene.gd"),
			# "PostBattleScene": preload("res://src/game/scenes/post_battle_scene/post_battle_scene.gd"),
			# "LoadingScene": preload("res://src/game/scenes/loading_scene/loading_scene.gd"),
			# "SettingsScene": preload("res://src/game/scenes/settings_scene/settings_scene.gd"),
			# "LevelsScene": preload("res://src/game/scenes/levels_scene/levels_scene.gd"),
			# "LevelSelectScene": preload("res://src/game/scenes/level_select_scene/level_select_scene.gd"),
			# "TrainingRoomScene": preload("res://src/game/scenes/training_room_scene/training_room_scene.gd"),
		}
	}
