class_name UiAnchorRegistry
extends Resource

## Shared id → Control lookup (a `.tres` exported by both sides).
## Scenes mark UI with `UiAnchor`; overlays in other contexts (tutorials, highlights) look it up
## without direct node references across scenes.

signal ev_changed

var _anchors: Dictionary = {}


func register(anchor_id: String, control: Control) -> void:
	if anchor_id.is_empty() or control == null:
		return
	_anchors[anchor_id] = control
	ev_changed.emit()


func unregister(anchor_id: String, control: Control) -> void:
	if _anchors.get(anchor_id) != control:
		return
	_anchors.erase(anchor_id)
	ev_changed.emit()


func get_control(anchor_id: String) -> Control:
	var control: Variant = _anchors.get(anchor_id)
	if control == null or not is_instance_valid(control):
		return null
	return control as Control


## Registered and currently visible on screen.
func get_visible(anchor_id: String) -> Control:
	var control := get_control(anchor_id)
	if control == null or not control.is_inside_tree() or not control.is_visible_in_tree():
		return null
	return control
