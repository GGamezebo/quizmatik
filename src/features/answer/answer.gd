extends Area2D

class_name Answer

signal ev_killed(answer:Answer)

const ENTRY_MIN_DURATION: float = 0.28
const ENTRY_MAX_DURATION: float = 0.45
const ENTRY_SPEED: float = 650.0

## Average fill colors of balloons_atlas frames (row-major), for pop tint.
const BALLOON_TINTS: Array[Color] = [
	Color(0.683, 0.360, 0.389),
	Color(0.842, 0.718, 0.327),
	Color(0.604, 0.762, 0.655),
	Color(0.655, 0.769, 0.814),
	Color(0.759, 0.393, 0.558),
	Color(0.584, 0.468, 0.666),
	Color(0.850, 0.551, 0.309),
	Color(0.475, 0.773, 0.753),
	Color(0.374, 0.539, 0.420),
	Color(0.811, 0.641, 0.317),
	Color(0.230, 0.484, 0.487),
	Color(0.711, 0.747, 0.329),
	Color(0.271, 0.426, 0.683),
	Color(0.692, 0.584, 0.692),
	Color(0.577, 0.261, 0.276),
]

@export var label: Label
@export var balloon_pop_scene: PackedScene
@export var _entry_pending: bool = true
@export var _collision_shape: CollisionShape2D = null
@export var _sprite: Sprite2D = null
@export var _visual: Node2D = null
@export_range(0.5, 1.0, 0.01) var lane_fill_ratio: float = 0.94
@export var wind_bob_speed: float = 2.4
@export var wind_bob_strength: float = 11.0
@export var wind_sway_speed: float = 2.1
@export var wind_sway_degrees: float = 14.0
@export var wind_pulse_speed: float = 2.4
@export var wind_pulse_strength: float = 0.06
@export var label_body_offset: Vector2 = Vector2(0, 8)
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
var _lane_height: float = 0.0
var _is_entering: bool = false
var _is_dying: bool = false
var _base_sprite_scale: Vector2 = Vector2.ONE
var _base_sprite_offset: Vector2 = Vector2.ZERO
var _wind_pos: PositionShaker
var _wind_rot: RotationShaker
var _wind_scale: ScaleShacker


func _ready() -> void:
	_sprite.frame = randi() % (_sprite.hframes * _sprite.vframes)
	_saved_collision_layer = collision_layer
	_base_sprite_scale = _sprite.scale
	_base_sprite_offset = _sprite.offset
	_center_label_on_body()
	_fit_to_lane()
	_init_wind()
	if _entry_pending:
		_begin_entry()

func _exit_tree() -> void:
	ev_killed.emit(self)

func _process(delta: float) -> void:
	_update_wind(delta)

	if _is_entering:
		return

	position.x -= speed * _acceleration * delta

	if position.x < -100:
		queue_free()


func initialize(
	x: float,
	y: float,
	new_value: int,
	_speed: float,
	gameplay_area: Rect2,
	lane_height: float = 0.0,
) -> void:
	position = Vector2(x, y)
	value = new_value
	speed = _speed
	_spawn_x = x
	_gameplay_area = gameplay_area
	_lane_height = lane_height


func set_acceleration(acceleration: float) -> void:
	_acceleration = acceleration


func is_hittable() -> bool:
	return not _is_entering and not _is_dying


func _fit_to_lane() -> void:
	if _lane_height <= 0.0 or _sprite == null or _sprite.texture == null:
		_refresh_collision_radius()
		return

	var frame_h: float = float(_sprite.texture.get_height()) / float(_sprite.vframes)
	var local_h: float = frame_h * absf(_sprite.scale.y)
	if local_h <= 0.0:
		_refresh_collision_radius()
		return

	var target_h: float = _lane_height * lane_fill_ratio
	var s: float = target_h / local_h
	scale = Vector2(s, s)
	_refresh_collision_radius()


func _refresh_collision_radius() -> void:
	var shape: CircleShape2D = _collision_shape.shape as CircleShape2D
	if shape:
		_collision_radius = shape.radius * absf(scale.x)


func _init_wind() -> void:
	# Unique phase per balloon so a row doesn't sway in sync.
	_wind_pos = PositionShaker.new(wind_bob_speed, wind_bob_strength, 0.045)
	_wind_rot = RotationShaker.new(wind_sway_speed, wind_sway_degrees, 0.04)
	_wind_scale = ScaleShacker.new(wind_pulse_speed, wind_pulse_strength, 0.05)


func _update_wind(delta: float) -> void:
	if _is_dying or _wind_pos == null:
		return

	_wind_pos.update(delta)
	_wind_rot.update(delta)
	_wind_scale.update(delta)

	var bob: Vector2 = _wind_pos.get_pos_offset()
	# Prefer vertical float; keep some horizontal sway without leaving the lane.
	bob.x *= 0.55

	if _visual:
		_visual.position = bob
		_visual.rotation = _wind_rot.get_rotation_offset()
		_visual.scale = Vector2.ONE + _wind_scale.get_scale_offset()
	_sprite.offset = _base_sprite_offset
	_sprite.rotation = 0.0
	_sprite.scale = _base_sprite_scale


func _center_label_on_body() -> void:
	if label == null:
		return
	# Keep the Control rect centered on the balloon body (sprite is nudged down by offset).
	var half: Vector2 = label.size * 0.5
	if half == Vector2.ZERO:
		half = Vector2(36, 36)
	label.position = label_body_offset - half
	label.pivot_offset = half


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
	if _is_dying:
		return
	_is_dying = true
	_disable_collision()

	if label:
		label.visible = false
	if _sprite:
		_sprite.visible = false

	if balloon_pop_scene == null:
		queue_free()
		return

	var tint: Color = Color.WHITE
	if _sprite:
		tint = BALLOON_TINTS[_sprite.frame % BALLOON_TINTS.size()]
	var pop_pos: Vector2 = _base_sprite_offset * _base_sprite_scale
	if _visual:
		pop_pos += _visual.position
	var pop: BalloonPop = BalloonPop.spawn(balloon_pop_scene, self, pop_pos, tint)
	pop.tree_exited.connect(queue_free, CONNECT_ONE_SHOT)


func right() -> void:
	label.label_settings.font_color = right_color


func fail() -> void:
	label.label_settings.font_color = wrong_color
