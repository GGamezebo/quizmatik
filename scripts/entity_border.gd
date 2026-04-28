extends Node2D

@export var gameArea: GameArea
@export var entities: Array[Node]
@export var BOTTOM_OFFSET: float = 80
@export var UP_OFFSET: float = 220

func _physics_process(_delta):
	for entity in entities:
		var area = gameArea.gameplay_area
		
		var height = entity.get_size().y
		entity.position.x = clamp(entity.position.x, area.position.x, area.end.x)
		entity.position.y = clamp(entity.position.y, area.position.y + height/2, area.end.y - height/2)
