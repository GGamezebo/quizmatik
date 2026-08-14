class_name HoverScaleBinder
extends Node

## Binds hover-scale to every BaseButton under the parent Control.


func _ready() -> void:
	var root: Node = get_parent()
	if root == null:
		return
	HoverScaleButton.bind_tree(root)
	root.child_entered_tree.connect(_on_child_entered_tree)


func _on_child_entered_tree(node: Node) -> void:
	HoverScaleButton.bind_tree(node)
