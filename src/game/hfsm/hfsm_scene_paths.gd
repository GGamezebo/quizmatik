class_name HfsmScenePaths
extends RefCounted

const SCENES := {
	"app_root": "res://src/game/scenes/app_root/root.tscn",
	"menu": "res://src/game/scenes/menu/menu.tscn",
	"game": "res://src/game/scenes/game/game.tscn",
	"post_battle": "res://src/game/scenes/post_battle/post_battle.tscn",
}


static func getPath(scene_id: String) -> String:
	return SCENES.get(scene_id, "")
