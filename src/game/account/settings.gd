extends Node

@export var _user_settings: UserSettings

func _ready() -> void:
	_load_settings(_user_settings)

func _load_settings(resource: Resource) -> void:
	var result: Dictionary = ResourceUtils.load_json(resource.SAVE_PATH)
	match int(result["status"]):
		ResourceUtils.JsonLoadStatus.OK:
			ResourceUtils.apply_dict(resource, result["data"])
			print("Settings loaded ", resource.SAVE_PATH)
		ResourceUtils.JsonLoadStatus.MISSING:
			print("Settings not found ", resource.SAVE_PATH)
		ResourceUtils.JsonLoadStatus.CORRUPT:
			# Keep in-memory defaults; do not overwrite the damaged file.
			push_error("Settings corrupt, keeping defaults: %s" % resource.SAVE_PATH)
			_try_restore_settings_from_bak(resource)
	_apply_audio_mute_settings(resource as UserSettings)


func _try_restore_settings_from_bak(resource: Resource) -> void:
	var bak: Dictionary = ResourceUtils.load_json(ResourceUtils.bak_path(resource.SAVE_PATH))
	if int(bak["status"]) != ResourceUtils.JsonLoadStatus.OK:
		return
	ResourceUtils.apply_dict(resource, bak["data"])
	print("Settings restored from bak ", ResourceUtils.bak_path(resource.SAVE_PATH))
	# Repair main without clobbering the good bak.
	ResourceUtils.save_json(resource.SAVE_PATH, ResourceUtils.resource_to_dict(resource), false)


func _apply_audio_mute_settings(settings: UserSettings) -> void:
	if settings == null:
		return
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_mute(master_idx, settings.is_sound_mute)
	var music_idx: int = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_mute(music_idx, settings.is_music_mute)
