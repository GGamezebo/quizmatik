extends Area2D

class_name Answer

signal ev_killed(answer:Answer)

const ENTRY_MIN_DURATION: float = 0.28
const ENTRY_MAX_DURATION: float = 0.45
const ENTRY_SPEED: float = 650.0

@export var label: Label
@export var animation_time: float = 1.0
@export var dead_animation_scale: float = 1.5
@export var _entry_pending: bool = true
@export var _collision_shape: CollisionShape2D = null
@export var _sprite: Sprite2D = null
@export_color_no_alpha var right_color: Color = Color.GREEN
@export_color_no_alpha var wrong_color: Color = Color.RED

var value: int = 0:
	set(new_value):
		value = new_value
		label.text = str(value)

var speed: float = 50.0
var _acceleration: float = GameConfig.PLAYER_ACCELERATION_DEFAULT
var _collision_radius: float = 64.0
var _saved_collision_layer: int = 0
var _gameplay_area: Rect2 = Rect2()
var _spawn_x: float = 0.0
var _is_entering: bool = false


func _ready() -> void:
	_saved_collision_layer = collision_layer
	var shape: CircleShape2D = _collision_shape.shape as CircleShape2D
	if shape:
		_collision_radius = shape.radius
	if _entry_pending:
		_begin_entry()

func _exit_tree() -> void:
	ev_killed.emit(self)

func _process(delta: float) -> void:
	if _is_entering:
		return

	position.x -= speed * _acceleration * delta

	if position.x < -100:
		queue_free()

	_sprite.rotation += delta


func initialize(x: float, y: float, new_value: int, _speed: float, gameplay_area: Rect2) -> void:
	position = Vector2(x, y)
	value = new_value
	speed = _speed
	_spawn_x = x
	_gameplay_area = gameplay_area


func set_acceleration(acceleration: float) -> void:
	_acceleration = acceleration


func is_hittable() -> bool:
	return not _is_entering


func _begin_entry() -> void:
	_entry_pending = false
	if _is_fully_inside_viewport():
		return

	_is_entering = true
	collision_layer = 0
	monitorable = false

	var target_x: float = _entry_target_x()
	var distance: float = maxf(_spawn_x - target_x, 1.0)
	var duration: float = clampf(distance / ENTRY_SPEED, ENTRY_MIN_DURATION, ENTRY_MAX_DURATION)

	var tween := create_tween()
	tween.tween_property(self, "position:x", target_x, duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(_finish_entry)


func _entry_target_x() -> float:
	return _gameplay_area.end.x - _collision_radius


func _is_fully_inside_viewport() -> bool:
	return position.x + _collision_radius <= _gameplay_area.end.x \
		and position.x - _collision_radius >= _gameplay_area.position.x


func _finish_entry() -> void:
	_is_entering = false
	collision_layer = _saved_collision_layer
	monitorable = true


func _disable_collision() -> void:
	collision_layer = 0
	collision_mask = 0


func take_damage() -> void:
	_disable_collision()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, animation_time)
	tween.tween_property(self, "scale", scale * dead_animation_scale, animation_time)
	tween.tween_property(self, "position:y", position.y, animation_time)
	tween.chain().tween_callback(queue_free)


func right() -> void:
	label.label_settings.font_color = right_color


func fail() -> void:
	label.label_settings.font_color = wrong_color
