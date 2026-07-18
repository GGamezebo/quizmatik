class_name HfsmBoundEntity
extends RefCounted

## Base class for entities bound to FSM states.
## Subclasses must override: static func NAME() -> String

static func NAME() -> String:
	return ""


func _init(_data: Dictionary = {}) -> void:
	pass


func on_event(_event_name: String, _data: Dictionary) -> void:
	pass


func deinit() -> void:
	pass
