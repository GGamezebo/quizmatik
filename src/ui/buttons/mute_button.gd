@tool
class_name MuteButton
extends HoverScaleButton

## Base toggle that mutes an AudioServer bus and persists via UserSettings.

@export var user_settings: UserSettings

var _bus_index: int = -1


func _ready() -> void:
	super._ready()
	var bus_name: String = _get_bus_name()
	_bus_index = AudioServer.get_bus_index(bus_name)
	if _bus_index == -1:
		push_error("Audio bus not found: " + bus_name)
		return

	toggle_mode = true
	toggled.connect(_on_toggled)

	var is_muted: bool = _is_muted()
	AudioServer.set_bus_mute(_bus_index, is_muted)
	set_pressed_no_signal(is_muted)


func _on_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(_bus_index, toggled_on)
	_set_muted(toggled_on)
	user_settings.save()


func _get_bus_name() -> String:
	push_error("MuteButton._get_bus_name() must be overridden")
	return ""


func _is_muted() -> bool:
	push_error("MuteButton._is_muted() must be overridden")
	return false


func _set_muted(_is_mute: bool) -> void:
	push_error("MuteButton._set_muted() must be overridden")
