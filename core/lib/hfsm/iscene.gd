class_name IScene
extends Node

## Base for HFSM-mounted Godot scenes (`scene: { id, loading }` on a state).
## HfsmSceneRegistry calls initialize / deinit / on_event.

var _hfsm: HFSM = null

static func NAME() -> String:
	return ""


func _ready() -> void:
	if _is_isolated_run():
		initialize(_default_data())

func sync_hfsm(hfsm: HFSM) -> void:
	_hfsm = hfsm

func initialize(_data: Dictionary) -> void:
	pass

func deinit() -> void:
	_hfsm = null

func on_event(_event_name: String, _data: Dictionary) -> void:
	pass

func _is_isolated_run() -> bool:
	return get_tree().current_scene == self

func _default_data() -> Dictionary:
	return {}
