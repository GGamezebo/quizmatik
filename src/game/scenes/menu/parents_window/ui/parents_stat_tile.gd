class_name ParentsStatTile
extends PanelContainer

## One number in the parents report: big value + caption under it.

@export var caption: String = ""
@export var value_label: Label
@export var caption_label: Label


func _ready() -> void:
	caption_label.text = caption


func set_value(text: String) -> void:
	value_label.text = text
