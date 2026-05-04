extends Node2D

@export var gameArea: GameArea
@export var entities: Array[Node]

func _process(_delta: float) -> void:
	for entity in entities:
		var area: Rect2 = gameArea.gameplay_area
		var height: float = entity.get_size().y
		entity.position.x = clamp(entity.position.x, area.position.x, area.end.x)
		entity.position.y = clamp(entity.position.y, area.position.y + height/2, area.end.y - height/2)
