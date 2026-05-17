extends TextureButton


@export var bus_name: String = "Music"
@export var user_settings: UserSettings

var _bus_index: int


func _ready() -> void:
	_bus_index = AudioServer.get_bus_index(bus_name)
	if _bus_index == -1:
		push_error("Audio bus not found: " + bus_name)
		return
	
	toggled.connect(_on_toggled)

	var is_muted: bool = user_settings.is_music_mute
	AudioServer.set_bus_mute(_bus_index, is_muted)
	button_pressed = is_muted

## Connected to the TextureButton's 'toggled' signal
func _on_toggled(toggled_on: bool) -> void:
	var is_mute: bool = toggled_on
	AudioServer.set_bus_mute(_bus_index, is_mute)
	
	user_settings.is_music_mute = is_mute
	user_settings.save()
