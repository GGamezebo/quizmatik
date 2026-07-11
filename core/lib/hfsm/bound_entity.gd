class_name HfsmBoundEntity
extends RefCounted

## Base class for entities bound to FSM states.
## Subclasses must define: const NAME = "EntityName"

var data: Dictionary = {}


func _init(p_data: Dictionary = {}) -> void:
	data = p_data.duplicate()


func on_event(_event_name: String, _data: Dictionary) -> void:
	pass


func deinit() -> void:
	pass


static func get_entity_name(script: Variant) -> String:
	if script == null:
		return ""
	if script is GDScript:
		var constants: Dictionary = (script as GDScript).get_script_constant_map()
		if constants.has("NAME"):
			return str(constants["NAME"])
	return ""
