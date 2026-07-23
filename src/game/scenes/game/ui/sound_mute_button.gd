extends TextureButton

## Toggle mute for all game audio (Master bus).

@export var user_settings: UserSettings

var _bus_index: int = -1


func _ready() -> void:
	_bus_index = AudioServer.get_bus_index("Master")
	if _bus_index == -1:
		push_error("Audio bus not found: Master")
		return

	toggle_mode = true
	toggled.connect(_on_toggled)

	var is_muted: bool = user_settings.is_sound_mute
	AudioServer.set_bus_mute(_bus_index, is_muted)
	set_pressed_no_signal(is_muted)


func _on_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(_bus_index, toggled_on)
	user_settings.is_sound_mute = toggled_on
	user_settings.save()
