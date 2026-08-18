@tool
class_name MovementModeButton
extends HoverScaleButton

@export var user_settings: UserSettings
@export var air_plane: AirPlane
@export var direct_texture: Texture2D
@export var discrete_texture: Texture2D


func _ready() -> void:
	super._ready()
	pressed.connect(_on_pressed)
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
