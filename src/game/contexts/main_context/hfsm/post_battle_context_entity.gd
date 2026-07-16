extends HfsmBoundEntity

static func NAME() -> String:
	return "PostBattleContext"
const AppRoot := preload("res://src/game/contexts/main_context/hfsm/app_root_entity.gd")


func _init(data: Dictionary = {}) -> void:
	super._init(data)
	var main: Node = AppRoot.require_host()
	main.mount_context(main.post_battle_context_path, data, false)


func deinit() -> void:
	var main: Node = AppRoot.host
	if main:
		main.release_current_context()
