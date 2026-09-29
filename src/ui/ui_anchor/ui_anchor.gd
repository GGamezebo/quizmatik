class_name UiAnchor
extends Node

## Marks `target` under `anchor_id` in a shared `UiAnchorRegistry` while this node is in the tree.
## Target may be swapped at runtime (e.g. a spawned list item) via `set_target`.

@export var registry: UiAnchorRegistry
@export var anchor_id: String
@export var target: Control


func _ready() -> void:
	_register()


func _exit_tree() -> void:
	_unregister()


func set_target(control: Control) -> void:
	_unregister()
	target = control
	if is_node_ready():
		_register()


func _register() -> void:
	if registry != null and target != null:
		registry.register(anchor_id, target)


func _unregister() -> void:
	if registry != null and target != null:
		registry.unregister(anchor_id, target)
