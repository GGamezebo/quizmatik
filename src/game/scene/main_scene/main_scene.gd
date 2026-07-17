extends Node

const HFSM_CONFIG_PATH := "res://src/common/hfsm/app_hfsm.json"
const AppRoot := preload("res://src/game/scene/main_scene/hfsm/app_root_entity.gd")
const HfsmEntityRegistry := preload("res://src/game/scene/main_scene/hfsm/hfsm_entity_registry.gd")
const HfsmScenePaths := preload("res://src/game/scene/main_scene/hfsm/hfsm_scene_paths.gd")

@export var loading_screen_scene: PackedScene
@export var main_events: MainEvents
@export var min_load_time: float = 0.0

var _hfsm: HFSM
var listener: EventListener = EventListener.new()


func _ready() -> void:
	AppRoot.host = self
	listener.add(main_events.ev_start_game, _on_ev_start_game)
	listener.add(main_events.ev_exit_game, _on_ev_exit_game)
	listener.add(main_events.ev_return_to_menu, _on_ev_return_to_menu)
	# Defer past main-scene dependency settle (shared ProgressController / levels).
	_start_hfsm_when_ready()


func _start_hfsm_when_ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_hfsm = HFSM.new(
		HfsmLoader.load_tree(HFSM_CONFIG_PATH),
		HfsmEntityRegistry.build(),
		{
			"host": self,
			"paths": HfsmScenePaths.PATHS,
			"loading_screen": loading_screen_scene,
			"min_load_time": min_load_time,
		}
	)


func _exit_tree() -> void:
	listener.deinit()
	if _hfsm:
		_hfsm.clear()
	AppRoot.host = null
	_hfsm = null


func get_hfsm() -> HFSM:
	return _hfsm


func _on_ev_start_game(data: Dictionary) -> void:
	if _hfsm:
		_hfsm.add_event("ev.start_game", data)


func _on_ev_exit_game(data: Dictionary = {}) -> void:
	if _hfsm:
		_hfsm.add_event("ev.exit_game", data)


func _on_ev_return_to_menu() -> void:
	if _hfsm:
		_hfsm.add_event("ev.return_to_menu")
