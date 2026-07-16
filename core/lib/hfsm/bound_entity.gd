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


static func get_entity_name(script: Variant) -> String:
	if script == null:
		return ""
	if script is GDScript and (script as GDScript).has_method("NAME"):
		return str((script as GDScript).call("NAME"))
	return ""
