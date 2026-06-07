extends Node2D

@onready var _sky: TextureRect = $TextureRect

func _ready() -> void:
	get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()

func _fit_to_viewport() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_sky.position = Vector2.ZERO
	_sky.size = viewport_size

	for child in get_children():
		if child is GPUParticles2D:
			child.position = Vector2(viewport_size.x + 520.0, viewport_size.y * 0.5)
