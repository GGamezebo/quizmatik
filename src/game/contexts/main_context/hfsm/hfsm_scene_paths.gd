extends RefCounted

const PATHS := {
	"menu": "res://src/game/contexts/menu_context/menu_context.tscn",
	"game": "res://src/game/contexts/game_context/game_context.tscn",
	"post_battle": "res://src/game/contexts/post_battle_context/post_battle_context.tscn",
}


static func getPath(scene_id: String) -> String:
	return PATHS.get(scene_id, "")
