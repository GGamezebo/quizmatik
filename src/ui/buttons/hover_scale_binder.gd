class_name HoverScaleBinder
extends Node

## Binds hover-scale to every BaseButton under the parent Control (and in windows a `LazyWindow` child
## loads later — bound as they enter, before their `_ready`, like the rest).

@export var scale_factor: float = HoverScaleButton.HOVER_SCALE_FACTOR


func _ready() -> void:
	var root: Node = get_parent()
	if root == null:
		return
	HoverScaleButton.bind_tree(root, scale_factor)
	root.child_entered_tree.connect(_on_child_entered_tree)
	for child in root.get_children():
		if child is LazyWindow:
			child.child_entered_tree.connect(_on_child_entered_tree)


func _on_child_entered_tree(node: Node) -> void:
	HoverScaleButton.bind_tree(node, scale_factor)
