@tool
extends HoverScaleButton

@export var image: Texture

func _ready() -> void:
	super._ready()
	if has_node("Icon"):
		$Icon.texture = image
		$Icon.visible = image != null
