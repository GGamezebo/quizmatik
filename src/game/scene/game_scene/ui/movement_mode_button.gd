class_name MovementModeButton
extends TextureButton

@export var user_settings: UserSettings
@export var air_plane: AirPlane
@export var direct_texture: Texture2D
@export var discrete_texture: Texture2D

const HOVER_SCALE_FACTOR: float = 1.12
const HOVER_TWEEN_DURATION: float = 0.12

var _base_scale: Vector2 = Vector2.ONE
var _hover_tween: Tween

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(_update_pivot)
	_update_pivot()
	_update_icon(user_settings.movement_mode)

func _on_pressed() -> void:
	var new_mode: int = (
		AirPlane.MovementMode.DIRECT
		if user_settings.movement_mode == AirPlane.MovementMode.DISCRETE
		else AirPlane.MovementMode.DISCRETE
	)
	_apply_mode(new_mode)

func _apply_mode(mode: int) -> void:
	user_settings.movement_mode = mode
	user_settings.save()
	_update_icon(mode)
	if air_plane:
		air_plane.set_movement(mode)

func _update_icon(mode: int) -> void:
	texture_normal = discrete_texture if mode == AirPlane.MovementMode.DISCRETE else direct_texture

func _on_mouse_entered() -> void:
	_animate_scale(_base_scale * HOVER_SCALE_FACTOR)

func _on_mouse_exited() -> void:
	_animate_scale(_base_scale)

func _animate_scale(target_scale: Vector2) -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", target_scale, HOVER_TWEEN_DURATION).set_ease(Tween.EASE_OUT)

func _update_pivot() -> void:
	pivot_offset = size * 0.5
