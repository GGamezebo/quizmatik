extends RefCounted

const PATHS := {
	"menu": "res://src/game/scene/menu_scene/menu_scene.tscn",
	"game": "res://src/game/scene/game_scene/game_scene.tscn",
	"post_battle": "res://src/game/scene/post_battle_scene/post_battle_scene.tscn",
}


static func getPath(scene_id: String) -> String:
	return PATHS.get(scene_id, "")
