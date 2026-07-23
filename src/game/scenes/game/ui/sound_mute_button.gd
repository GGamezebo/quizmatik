extends MuteButton

## Toggle mute for all game audio (Master bus).


func _get_bus_name() -> String:
	return "Master"


func _is_muted() -> bool:
	return user_settings.is_sound_mute


func _set_muted(is_mute: bool) -> void:
	user_settings.is_sound_mute = is_mute
