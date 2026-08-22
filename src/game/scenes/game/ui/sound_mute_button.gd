@tool
extends MuteButton

@export var image_active: Texture
@export var image_inacitve: Texture

## Toggle mute for the SFX bus.


func _ready() -> void:
	super._ready()
	texture_normal = image_active
	texture_pressed = image_inacitve


func _get_bus_name() -> String:
	return "SFX"


func _is_muted() -> bool:
	return user_settings.is_sound_mute


func _set_muted(is_mute: bool) -> void:
	user_settings.is_sound_mute = is_mute
