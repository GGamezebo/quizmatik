#@tool
class_name AirPlane
extends Area2D

#@export_tool_button("test_die") var test_die = die

signal ev_shoot
signal ev_air_plane_colladed(airPlane: AirPlane, area: Area2D)
signal ev_dead_animation_finished

const SPEED_DEFAULTS: float = 800.0

@export var components:Array[Node] = []
@export var directionComponents:Array[Node] = []
@export var animated_sprite: AnimatedSprite2D
@export var dead_animation_time = 2.5
@export var explosion_scene: PackedScene

var direction_y: int = 0
var speed: float = SPEED_DEFAULTS

	
func _ready() -> void:
	for component in components:
		component.initialize(self)

func initialize(_speed: float) -> void:
	direction_y = 0
	speed = _speed

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		if Input.is_action_just_pressed("shoot"):
			ev_shoot.emit(self.position + Vector2(get_size().x / 2.0, 0.0))
		
	var dirY = sign(Input.get_axis("ui_up","ui_down"))
	position.y = clamp(position.y + direction_y * speed * delta, 0, get_viewport_rect().size.y)
	
	if dirY != direction_y:
		direction_y = dirY
		for component in directionComponents:
			component.setDirection(direction_y)
	
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

func _on_area_entered(area: Area2D) -> void:
	ev_air_plane_colladed.emit(self, area)


func _disable_collision() -> void:
	collision_layer = 0
	collision_mask = 0
	
	
func die():
	set_process_input(false)
	set_process_unhandled_input(false)
	_disable_collision()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", rotation + randf_range(-3, 3), dead_animation_time * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), dead_animation_time).set_ease(Tween.EASE_IN) # Сжимаем

	for i in range(4):
		await get_tree().create_timer(0.15).timeout # Пауза между взрывами
		_spawn_explosion_at_random_pos()

	_spawn_explosion_at_random_pos(Vector2.ZERO, 1.5) # Большой взрыв в центре
	animated_sprite.visible = false
	
	await tween.finished
	ev_dead_animation_finished.emit()

func _spawn_explosion_at_random_pos(offset = Vector2.ZERO, scale_multiplier = 1.0):
	var explosion = explosion_scene.instantiate()
	
	if offset == Vector2.ZERO:
		var sprite = animated_sprite
		var current_frame_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		
		if current_frame_texture:
			var size = current_frame_texture.get_size()
			# Генерируем случайную точку в пределах размеров кадра
			offset = Vector2(
				randf_range(-size.x / 2, size.x / 2),
				randf_range(-size.y / 2, size.y / 2)
			) * scale
		
	get_parent().add_child(explosion)
	explosion.global_position = global_position + offset
	explosion.scale = Vector2(scale_multiplier, scale_multiplier)
