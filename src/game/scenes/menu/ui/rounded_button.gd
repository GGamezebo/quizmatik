@tool
extends HoverScaleButton

@export var image: Texture

func _ready() -> void:
	super._ready()
	$Icon.texture = image
