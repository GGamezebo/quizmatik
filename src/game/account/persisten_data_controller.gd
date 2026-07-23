extends Node

@export var _user_settings: UserSettings
@export var _progress: PDataProgress
@export var root_events: RootEvents

func _ready() -> void:
	_load_settings(_user_settings)
	_load_progress(_progress)
	root_events.ev_reset_account_progress.connect(_on_reset_account_progress)
	print("Data system initialized successfully.")

func _load_settings(resource: Resource) -> void:
	if ResourceLoader.exists(resource.SAVE_PATH):
		var saved_res = ResourceLoader.load(resource.SAVE_PATH)
		if saved_res:
			ResourceUtils.update_resource(resource, saved_res)
			print("Resource is loaded ", resource.SAVE_PATH)
	else:
		print("Resource is not found ", resource.SAVE_PATH)
	_apply_audio_mute_settings(resource as UserSettings)


func _apply_audio_mute_settings(settings: UserSettings) -> void:
	if settings == null:
		return
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_mute(master_idx, settings.is_sound_mute)
	var music_idx: int = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_mute(music_idx, settings.is_music_mute)

func _load_progress(pdata: PDataProgress) -> void:
	if ResourceLoader.exists(pdata.SAVE_PATH):
		var saved_res: PDataProgress = ResourceLoader.load(pdata.SAVE_PATH)
		if saved_res:
			ResourceUtils.update_resource(pdata, saved_res)
			print("Resource is loaded ", pdata.SAVE_PATH)
			var saved_version: int = pdata.progress["version"]
			if saved_version < pdata.CURRENT_VERSION:
				print("run migration from %d to %d" % [saved_version, pdata.CURRENT_VERSION])
				PDataMigrator.migrate(
					pdata.progress, 
					saved_version, 
					PDataProgress.CURRENT_VERSION
				)
				_save_pdata(pdata)
	else:
		_save_pdata(pdata)

func _on_reset_account_progress() -> void:
	var default: PDataProgress = PDataProgress.new()
	_progress.progress = default.progress.duplicate(true)
	_save_pdata(_progress)
	
func _save_pdata(pdata: PDataProgress) -> void:
	pdata.progress["version"] = PDataProgress.CURRENT_VERSION
	ResourceUtils.save_resource_to_disk(pdata, pdata.SAVE_PATH)
