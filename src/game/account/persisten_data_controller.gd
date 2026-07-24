extends Node

## Debounce window for progress saves (seconds). Each save request while a write
## is pending restarts this timer, so bursts of mutations collapse into one write.
const SAVE_DEBOUNCE_SEC := 6.0

@export var _user_settings: UserSettings
@export var _progress: PDataProgress
@export var root_events: RootEvents

var _dirty: bool = false
var _in_battle: bool = false
var _shutting_down: bool = false
var _debounce_timer: Timer

func _ready() -> void:
	_debounce_timer = Timer.new()
	_debounce_timer.one_shot = true
	_debounce_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_debounce_timer.timeout.connect(_flush)
	add_child(_debounce_timer)

	_load_settings(_user_settings)
	_load_progress(_progress)
	root_events.ev_reset_account_progress.connect(_on_reset_account_progress)
	root_events.ev_save_progress.connect(save)
	root_events.ev_battle_started.connect(_on_battle_started)
	root_events.ev_battle_finished.connect(_on_battle_finished)
	print("Data system initialized successfully.")

## Debounced save entry point (wired to RootEvents.ev_save_progress).
## Never writes during a battle; other requests coalesce onto a single timed write.
func save() -> void:
	_dirty = true
	if _shutting_down:
		_flush()
		return
	if _in_battle:
		return
	_debounce_timer.start(SAVE_DEBOUNCE_SEC)

## Writes now if anything is pending; used at battle end, on app close, and by the timer.
func _flush() -> void:
	if not _dirty:
		return
	_write_to_disk()

func _write_to_disk() -> void:
	_dirty = false
	if _debounce_timer:
		_debounce_timer.stop()
	_progress.progress["version"] = PDataProgress.CURRENT_VERSION
	ResourceUtils.save_resource_to_disk(_progress, _progress.SAVE_PATH)

func _on_battle_started() -> void:
	_in_battle = true

func _on_battle_finished() -> void:
	_in_battle = false
	# Deferred so every other ev_battle_finished listener has marked its data dirty first.
	_flush.call_deferred()

func _notification(what: int) -> void:
	match what:
		# App is being torn down: keep writing immediately so late saves
		# (e.g. StatisticsController._exit_tree) still reach disk.
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			_shutting_down = true
			_flush()
		# Backgrounded but may resume (mobile/web): flush pending, stay debounced.
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_flush()

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
				_write_to_disk()
	else:
		_write_to_disk()

func _on_reset_account_progress() -> void:
	var default: PDataProgress = PDataProgress.new()
	_progress.progress = default.progress.duplicate(true)
	_write_to_disk()
