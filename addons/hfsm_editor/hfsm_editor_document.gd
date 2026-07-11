@tool
extends RefCounted
class_name HfsmEditorDocument

signal changed

const RESERVED := ["enter", "leave", "consume", "states"]

var root_name: String = "App"
var root_data: Dictionary = {}
var file_path: String = ""
var dirty: bool = false


func new_document(p_root_name: String = "App") -> void:
	root_name = p_root_name
	root_data = {"states": {}}
	file_path = ""
	_mark_dirty()


func load_from_path(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "File not found: %s" % path
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Cannot open: %s" % path
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null or not parsed is Dictionary:
		return "Invalid JSON object"
	var data: Dictionary = parsed
	if data.size() != 1:
		return "HFSM config must contain exactly one root state"
	var key: String = str(data.keys()[0])
	var value = data[key]
	if not value is Dictionary:
		return "Root state must be an object"
	root_name = key
	root_data = (value as Dictionary).duplicate(true)
	if not root_data.has("states"):
		root_data["states"] = {}
	file_path = path
	dirty = false
	changed.emit()
	return ""


func to_dict() -> Dictionary:
	return {root_name: root_data.duplicate(true)}


func to_json_text() -> String:
	return JSON.stringify(to_dict(), "\t")


func save_to_path(path: String = "") -> String:
	var target := path if path != "" else file_path
	if target.is_empty():
		return "No file path"
	var parsed = JSON.parse_string(to_json_text())
	var result := HfsmLoader.try_load_tree(parsed)
	if result.get("error", "") != "":
		return "Validation failed: %s" % result.error
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		return "Cannot write: %s" % target
	file.store_string(to_json_text())
	file_path = target
	dirty = false
	changed.emit()
	return ""


func validate() -> String:
	var parsed = JSON.parse_string(to_json_text())
	var result := HfsmLoader.try_load_tree(parsed)
	return str(result.get("error", ""))


func get_state(path: PackedStringArray) -> Dictionary:
	if path.is_empty() or path[0] != root_name:
		return {}
	if path.size() == 1:
		return root_data
	var node: Dictionary = root_data
	for i in range(1, path.size()):
		var states: Dictionary = node.get("states", {})
		var child_name := path[i]
		if not states.has(child_name):
			return {}
		var child = states[child_name]
		if not child is Dictionary:
			return {}
		node = child
	return node


func collect_state_names() -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray([root_name])
	_collect_names(root_data, names)
	return names


func _collect_names(node: Dictionary, names: PackedStringArray) -> void:
	var states: Dictionary = node.get("states", {})
	for child_name in states.keys():
		names.append(str(child_name))
		var child = states[child_name]
		if child is Dictionary:
			_collect_names(child, names)


func rename_state(path: PackedStringArray, new_name: String) -> String:
	new_name = new_name.strip_edges()
	if new_name.is_empty():
		return "Name cannot be empty"
	if path.is_empty():
		return "Invalid path"
	var names := collect_state_names()
	var old_name := path[path.size() - 1]
	if new_name != old_name and new_name in names:
		return "State name '%s' already exists" % new_name
	if path.size() == 1:
		root_name = new_name
		_mark_dirty()
		return ""
	var parent_path := path.slice(0, path.size() - 1)
	var parent := get_state(parent_path)
	if parent.is_empty():
		return "Parent not found"
	var states: Dictionary = parent.get("states", {})
	if not states.has(old_name):
		return "State not found"
	var data = states[old_name]
	states.erase(old_name)
	states[new_name] = data
	parent["states"] = states
	_mark_dirty()
	return ""


func add_child_state(parent_path: PackedStringArray, child_name: String) -> String:
	child_name = child_name.strip_edges()
	if child_name.is_empty():
		return "Name cannot be empty"
	if child_name in collect_state_names():
		return "State name '%s' already exists" % child_name
	var parent := get_state(parent_path)
	if parent.is_empty():
		return "Parent not found"
	if not parent.has("states") or not parent["states"] is Dictionary:
		parent["states"] = {}
	var states: Dictionary = parent["states"]
	states[child_name] = {"states": {}}
	parent["states"] = states
	_mark_dirty()
	return ""


func delete_state(path: PackedStringArray) -> String:
	if path.size() <= 1:
		return "Cannot delete root state"
	var parent_path := path.slice(0, path.size() - 1)
	var parent := get_state(parent_path)
	if parent.is_empty():
		return "Parent not found"
	var child_name := path[path.size() - 1]
	var states: Dictionary = parent.get("states", {})
	if not states.has(child_name):
		return "State not found"
	states.erase(child_name)
	parent["states"] = states
	_mark_dirty()
	return ""


func set_event_list(path: PackedStringArray, field: String, lines: PackedStringArray) -> String:
	if field not in ["enter", "leave", "consume"]:
		return "Invalid field"
	var node := get_state(path)
	if node.is_empty():
		return "State not found"
	var events: Array = []
	for line in lines:
		var s := String(line).strip_edges()
		if s.is_empty():
			continue
		var err := HfsmUtils.validate_event_pattern(s, path[path.size() - 1], field)
		if err != "":
			return err
		events.append(s)
	if field == "enter":
		if events.is_empty():
			node.erase("enter")
		else:
			node["enter"] = events
	else:
		if events.is_empty():
			node.erase(field)
		else:
			node[field] = events
	_mark_dirty()
	return ""


func get_event_list(path: PackedStringArray, field: String) -> PackedStringArray:
	var node := get_state(path)
	if node.is_empty():
		return PackedStringArray()
	if field == "enter" and not node.has("enter"):
		return PackedStringArray(["sys.enter"])
	var raw = node.get(field, [])
	var out: PackedStringArray = PackedStringArray()
	if raw is Array:
		for item in raw:
			out.append(str(item))
	return out


func get_bindings(path: PackedStringArray) -> Dictionary:
	var node := get_state(path)
	if node.is_empty():
		return {}
	var bindings: Dictionary = {}
	for key in node.keys():
		if key in RESERVED:
			continue
		bindings[str(key)] = str(node[key])
	return bindings


func set_bindings(path: PackedStringArray, bindings: Dictionary) -> String:
	var node := get_state(path)
	if node.is_empty():
		return "State not found"
	var to_erase: Array = []
	for key in node.keys():
		if key in RESERVED:
			continue
		to_erase.append(key)
	for key in to_erase:
		node.erase(key)
	for slot in bindings.keys():
		var slot_name := str(slot).strip_edges()
		var entity_name := str(bindings[slot]).strip_edges()
		if slot_name.is_empty():
			return "Binding slot cannot be empty"
		if slot_name in RESERVED:
			return "Slot '%s' is reserved" % slot_name
		if entity_name.is_empty():
			return "Binding value for '%s' cannot be empty" % slot_name
		node[slot_name] = entity_name
	_mark_dirty()
	return ""


func _mark_dirty() -> void:
	dirty = true
	changed.emit()
