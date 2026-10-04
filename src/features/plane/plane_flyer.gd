class_name PlaneFlyer
extends Node2D

## Visual-only plane (no collision, audio, combat): hovers on a sine, swaps idle/up/down
## frames by vertical velocity, leaves a pencil-dot trail. Loading screen / showcases.

@export var body: Node2D
@export var sprite: AnimatedSprite2D
@export var trail: PlaneFlyerTrail
## Trail spawn point (behind the flame), child of `body`.
@export var nozzle: Marker2D
@export var hover_amplitude: float = 18.0
@export var hover_period_sec: float = 1.6
## Pixels/sec of |dy| below which the idle frame is shown.
@export var tilt_threshold: float = 20.0
@export var tilt_degrees: float = 2.0

var _time: float = 0.0
var _animation: StringName = &""


func _ready() -> void:
	_set_animation(&"idle")


func apply_plane(plane_id: String) -> void:
	var tint := PlaneCatalog.get_def(plane_id).get("tint", Color.WHITE) as Color
	var mat := sprite.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("sprite_tint", tint)
	else:
		sprite.modulate = tint


func apply_paint(item: PaintItem) -> void:
	PlaneCatalog.apply_paint(sprite.material, item)


func apply_trail(item: TrailItem) -> void:
	trail.apply_style(item)


func _process(delta: float) -> void:
	_time += delta
	var omega := TAU / maxf(hover_period_sec, 0.01)
	body.position.y = sin(_time * omega) * hover_amplitude
	var velocity_y := cos(_time * omega) * hover_amplitude * omega
	if velocity_y < -tilt_threshold:
		_set_animation(&"up")
	elif velocity_y > tilt_threshold:
		_set_animation(&"down")
	else:
		_set_animation(&"idle")
	var target_rotation := deg_to_rad(tilt_degrees) * signf(velocity_y) if absf(velocity_y) > tilt_threshold else 0.0
	body.rotation = lerp_angle(body.rotation, target_rotation, minf(delta * 6.0, 1.0))
	trail.push_point(nozzle.global_position)


func _set_animation(animation_name: StringName) -> void:
	if _animation == animation_name:
		return
	_animation = animation_name
	sprite.play(animation_name)
