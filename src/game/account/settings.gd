extends Node

const MIN_VOLUME_DB: float = -40.0

@export var _user_settings: UserSettings
@export var vibration_controller: VibrationController


func _ready() -> void:
	_load_settings(_user_settings)


func apply_user_settings(settings: UserSettings = null) -> void:
	var target: UserSettings = settings if settings != null else _user_settings
	if target == null:
		return
	_apply_audio_settings(target)
	_apply_vibration_settings(target)


func _load_settings(resource: Resource) -> void:
	var result: Dictionary = ResourceUtils.load_json(resource.SAVE_PATH)
	match int(result["status"]):
		ResourceUtils.JsonLoadStatus.OK:
			ResourceUtils.apply_dict(resource, result["data"])
			print("Settings loaded ", resource.SAVE_PATH)
		ResourceUtils.JsonLoadStatus.MISSING:
			print("Settings not found ", resource.SAVE_PATH)
		ResourceUtils.JsonLoadStatus.CORRUPT:
			push_error("Settings corrupt, keeping defaults: %s" % resource.SAVE_PATH)
			_try_restore_settings_from_bak(resource)
	apply_user_settings(resource as UserSettings)


func _try_restore_settings_from_bak(resource: Resource) -> void:
	var bak: Dictionary = ResourceUtils.load_json(ResourceUtils.bak_path(resource.SAVE_PATH))
	if int(bak["status"]) != ResourceUtils.JsonLoadStatus.OK:
		return
	ResourceUtils.apply_dict(resource, bak["data"])
	print("Settings restored from bak ", ResourceUtils.bak_path(resource.SAVE_PATH))
	ResourceUtils.save_json(resource.SAVE_PATH, ResourceUtils.resource_to_dict(resource), false)


func _apply_audio_settings(settings: UserSettings) -> void:
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_mute(master_idx, false)

	var music_idx: int = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_mute(music_idx, settings.is_music_mute)
		if not settings.is_music_mute:
			AudioServer.set_bus_volume_db(music_idx, _volume_to_db(settings.music_volume))

	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_mute(sfx_idx, settings.is_sound_mute)
		if not settings.is_sound_mute:
			AudioServer.set_bus_volume_db(sfx_idx, _volume_to_db(settings.sfx_volume))


func _apply_vibration_settings(settings: UserSettings) -> void:
	if vibration_controller != null:
		vibration_controller.enabled = settings.is_vibration_enabled


static func _volume_to_db(volume: float) -> float:
	return lerpf(MIN_VOLUME_DB, 0.0, clampf(volume, 0.0, 1.0))
