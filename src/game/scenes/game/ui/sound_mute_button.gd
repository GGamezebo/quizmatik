@tool
extends MuteButton

## Toggle mute for the Music bus. SFX stay audible.


func _ready() -> void:
	super._ready()
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_mute(master_idx, false)


func _get_bus_name() -> String:
	return "Music"


func _is_muted() -> bool:
	return user_settings.is_music_mute


func _set_muted(is_mute: bool) -> void:
	user_settings.is_music_mute = is_mute
