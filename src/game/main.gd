extends Node

## App entry: boots HFSM. Gameplay/UI live in mounted IScene nodes + HFSM states.

const HFSM_CONFIG_PATH := "res://src/common/hfsm/app_hfsm.json"
const HfsmEntityRegistry := preload("res://src/game/hfsm/hfsm_entity_registry.gd")
const HfsmScenePaths := preload("res://src/game/hfsm/hfsm_scene_paths.gd")

@export var loading_screen_scene: PackedScene
@export var min_load_time: float = 0.0

var _hfsm: HFSM


func _ready() -> void:
	# Defer past tree settle so mounted scenes can resolve shared deps.
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
	if _hfsm:
		_hfsm.clear()
	_hfsm = null


func get_hfsm() -> HFSM:
	return _hfsm
