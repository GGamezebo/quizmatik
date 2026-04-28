extends Area2D

signal evDirectionChanged

const RIGHT  = 1
const LEFT  = -1
const VELOCITY_SPEED = 800.0

@export var components:Array[Node] = []
@export var directionComponents:Array[Node] = []
@export var animated_sprite:AnimatedSprite2D

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
		
func get_size() -> Vector2:
	# 1. Получаем имя текущей анимации
	var anim_name = animated_sprite.animation
	# 2. Получаем индекс текущего кадра
	var frame_index = animated_sprite.frame
	# 3. Достаем текстуру этого конкретного кадра
	var texture = animated_sprite.sprite_frames.get_frame_texture(anim_name, frame_index)
	
	if texture:
		# Умножаем чистый размер картинки на масштаб узла
		return texture.get_size() * animated_sprite.global_scale
	return Vector2.ZERO
