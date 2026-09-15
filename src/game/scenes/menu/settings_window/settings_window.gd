extends Control

@export var user_settings: UserSettings
@export var music_mute_button: MuteButton
@export var sound_mute_button: MuteButton
@export var music_toggle: TextureButton
@export var music_volume_slider: HSlider
@export var music_volume_label: Label
@export var sfx_toggle: TextureButton
@export var sfx_volume_slider: HSlider
@export var sfx_volume_label: Label
@export var vibration_toggle: TextureButton
@export var vibration_intensity_slider: HSlider
@export var vibration_intensity_label: Label

var _syncing_ui: bool = false


func _ready() -> void:
	music_toggle.toggled.connect(_on_music_toggle_toggled)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_toggle.toggled.connect(_on_sfx_toggle_toggled)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	vibration_toggle.toggled.connect(_on_vibration_toggle_toggled)
	vibration_intensity_slider.value_changed.connect(_on_vibration_intensity_changed)


func on_window_enter() -> void:
	_sync_ui_from_settings()


func _sync_ui_from_settings() -> void:
	if user_settings == null:
		return
	_syncing_ui = true
	music_toggle.button_pressed = not user_settings.is_music_mute
	music_volume_slider.value = user_settings.music_volume * 100.0
	music_volume_label.text = "%d%%" % int(music_volume_slider.value)
	music_volume_slider.editable = not user_settings.is_music_mute
	sfx_toggle.button_pressed = not user_settings.is_sound_mute
	sfx_volume_slider.value = user_settings.sfx_volume * 100.0
	sfx_volume_label.text = "%d%%" % int(sfx_volume_slider.value)
	sfx_volume_slider.editable = not user_settings.is_sound_mute
	vibration_toggle.button_pressed = user_settings.is_vibration_enabled
	vibration_intensity_slider.value = user_settings.vibration_intensity * 100.0
	vibration_intensity_label.text = "%d%%" % int(vibration_intensity_slider.value)
	vibration_intensity_slider.editable = user_settings.is_vibration_enabled
	_syncing_ui = false


func _on_music_toggle_toggled(enabled_music: bool) -> void:
	if _syncing_ui or user_settings == null:
		return
	user_settings.is_music_mute = not enabled_music
	music_volume_slider.editable = enabled_music
	if music_mute_button != null:
		music_mute_button.set_pressed_no_signal(user_settings.is_music_mute)
	_commit_settings()


func _on_sfx_toggle_toggled(enabled_sfx: bool) -> void:
	if _syncing_ui or user_settings == null:
		return
	user_settings.is_sound_mute = not enabled_sfx
	sfx_volume_slider.editable = enabled_sfx
	if sound_mute_button != null:
		sound_mute_button.set_pressed_no_signal(user_settings.is_sound_mute)
	_commit_settings()


func _on_music_volume_changed(value: float) -> void:
	if _syncing_ui or user_settings == null:
		return
	user_settings.music_volume = value / 100.0
	music_volume_label.text = "%d%%" % int(value)
	_commit_settings()


func _on_sfx_volume_changed(value: float) -> void:
	if _syncing_ui or user_settings == null:
		return
	user_settings.sfx_volume = value / 100.0
	sfx_volume_label.text = "%d%%" % int(value)
	_commit_settings()


func _on_vibration_toggle_toggled(enabled_vibration: bool) -> void:
	if _syncing_ui or user_settings == null:
		return
	user_settings.is_vibration_enabled = enabled_vibration
	vibration_intensity_slider.editable = enabled_vibration
	_commit_settings()


func _on_vibration_intensity_changed(value: float) -> void:
	if _syncing_ui or user_settings == null:
		return
	user_settings.vibration_intensity = value / 100.0
	vibration_intensity_label.text = "%d%%" % int(value)
	_commit_settings()


func _commit_settings() -> void:
	user_settings.save()
	_apply_settings()


func _apply_settings() -> void:
	var applier := _find_settings_applier()
	if applier != null:
		applier.apply_user_settings(user_settings)
	else:
		_apply_settings_fallback()


func _find_settings_applier() -> Node:
	return get_tree().root.find_child("Settings", true, false)


func _apply_settings_fallback() -> void:
	if user_settings == null:
		return
	var music_idx: int = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_mute(music_idx, user_settings.is_music_mute)
		if not user_settings.is_music_mute:
			AudioServer.set_bus_volume_db(music_idx, lerpf(-40.0, 0.0, user_settings.music_volume))
	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_mute(sfx_idx, user_settings.is_sound_mute)
		if not user_settings.is_sound_mute:
			AudioServer.set_bus_volume_db(sfx_idx, lerpf(-40.0, 0.0, user_settings.sfx_volume))
