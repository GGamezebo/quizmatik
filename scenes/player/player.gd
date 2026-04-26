extends Area2D

signal evDirectionChanged

const RIGHT  = 1
const LEFT  = -1
const VELOCITY_SPEED = 400.0

@export var components:Array[Node] = []
@export var directionComponents:Array[Node] = []

var directionY = 0

func _ready() -> void:
	for component in components:
		component.setup(self)

func _process(delta: float) -> void:
	var dirY = sign(Input.get_axis("ui_up","ui_down"))
	position.y = clamp(position.y + directionY * VELOCITY_SPEED * delta, 0, get_viewport_rect().size.y)
	
	if dirY != directionY:
		directionY = dirY
		for component in directionComponents:
			component.setDirection(directionY)
		evDirectionChanged.emit(directionY)
	
	for component in components:
		component.update(delta)
