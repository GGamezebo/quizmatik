extends Node2D

@export var entities: Array[Node]
@export var BOTTOM_OFFSET: float = 80
@export var UP_OFFSET: float = 220

func _physics_process(delta):
	var view_size = get_viewport_rect().size
	
	for entity in entities:
		entity.position.y = clamp(entity.position.y, UP_OFFSET, view_size.y - BOTTOM_OFFSET)
