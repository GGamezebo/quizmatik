class_name SaveManager
extends Node

const SAVE_DEBOUNCE_SEC := 6.0
const PROFILE: String = "save"
## Cloud writes are coalesced; battle end / pause / close push immediately.
const CLOUD_PUSH_SEC := 30.0

## Shared live progress resource (same `.tres` assigned on Progress / Daily / Stats / Profile).
@export var _pdata: PData
@export var _root_events: RootEvents
## Platform cloud copy (Yandex player data / Play Games snapshot): active only while `can_cloud_save`.
@export var _services: PlatformServices

@onready var _save = $Save

var active_profile_id: String = ""
var profiles: Dictionary = {}

var _dirty: bool = false
var _in_battle: bool = false
var _shutting_down: bool = false
var _debounce_timer: Timer
## Unix seconds of the last local write (or of the adopted cloud copy) → «newer wins» on conflict.
var _saved_at: int = 0
var _cloud_push_timer: Timer
var _is_cloud_requested: bool = false
var _is_cloud_synced: bool = false
var _is_cloud_dirty: bool = false
var _has_pending_cloud_answer: bool = false
var _pending_cloud_json: String = ""


func _ready() -> void:
	_debounce_timer = Timer.new()
	_debounce_timer.one_shot = true
	_debounce_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_debounce_timer.timeout.connect(_flush)
	add_child(_debounce_timer)
	_cloud_push_timer = Timer.new()
	_cloud_push_timer.one_shot = true
	_cloud_push_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_cloud_push_timer.timeout.connect(_push_cloud_now)
	add_child(_cloud_push_timer)

	load_pdata()
	_root_events.ev_save_progress.connect(save)
	_root_events.ev_battle_started.connect(_on_battle_started)
	_root_events.ev_battle_finished.connect(_on_battle_finished)
	if _services != null:
		_services.ev_caps_changed.connect(_on_platform_caps_changed)
		_services.ev_cloud_pulled.connect(_on_cloud_pulled)
		_on_platform_caps_changed()
	print("Data system initialized successfully.")

func save_pdata() -> void:
	_stash_live()
	_save.save_data(_envelope(), PROFILE)


func _envelope() -> Dictionary:
	return {
		"saved_at": _saved_at,
		"active_profile_id": active_profile_id,
		"profiles": profiles,
	}

func load_pdata() -> void:
	var dict: Dictionary = _save.edit_data(PROFILE)
	profiles = {}
	active_profile_id = ""
	_saved_at = int(dict.get("saved_at", 0))
	var raw_profiles: Variant = dict.get("profiles", {})
	if raw_profiles is Dictionary:
		profiles = (raw_profiles as Dictionary).duplicate(true)
	active_profile_id = String(dict.get("active_profile_id", ""))
	if active_profile_id.is_empty() or not profiles.has(active_profile_id):
		if not profiles.is_empty():
			active_profile_id = String(profiles.keys()[0])
		else:
			active_profile_id = ""
			_pdata.reset_to_defaults()
			return
	_pdata.apply_dict(profiles[active_profile_id])


func _stash_live() -> void:
	if active_profile_id.is_empty():
		return
	profiles[active_profile_id] = _pdata.to_dict()


func has_profiles() -> bool:
	return not profiles.is_empty()


## Dev wipe: empty envelope on disk now (not debounced). Live PData becomes a blank slot.
func wipe_all_profiles() -> void:
	active_profile_id = ""
	profiles.clear()
	_pdata.reset_to_defaults()
	_dirty = true
	_flush()


## Debounced save entry point (wired to RootEvents.ev_save_progress).
## Never writes during a battle; other requests coalesce onto a single timed write.
func save() -> void:
	_stash_live()
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
	_saved_at = int(Time.get_unix_time_from_system())
	save_pdata()
	_queue_cloud_push()

func _on_battle_started() -> void:
	_in_battle = true

func _on_battle_finished() -> void:
	_in_battle = false
	# Deferred so every other ev_battle_finished listener has marked its data dirty first.
	_after_battle.call_deferred()

func _after_battle() -> void:
	_flush_urgent()
	if _has_pending_cloud_answer:
		_has_pending_cloud_answer = false
		_apply_cloud_answer(_pending_cloud_json)


## Local write + immediate cloud push (battle end, backgrounded, closing).
func _flush_urgent() -> void:
	_flush()
	_push_cloud_now()


# --- Platform cloud -----------------------------------------------------------------------------

func _on_platform_caps_changed() -> void:
	if not _services.can_cloud_save:
		_is_cloud_requested = false
		_is_cloud_synced = false
		return
	if _is_cloud_requested:
		return
	_is_cloud_requested = true
	_services.ev_request_cloud_pull.emit()


func _on_cloud_pulled(json: String) -> void:
	if _in_battle:
		# Never swap progress under a running battle; decide right after it.
		_has_pending_cloud_answer = true
		_pending_cloud_json = json
		return
	_apply_cloud_answer(json)


## Newer `saved_at` wins (unsaved local changes count as «now»). Equal = already in sync.
func _apply_cloud_answer(json: String) -> void:
	_is_cloud_synced = true
	var cloud := CloudSaveCodec.decode(json)
	var cloud_profiles: Dictionary = cloud.get("profiles", {})
	if cloud_profiles.is_empty():
		_is_cloud_dirty = has_profiles()
		_push_cloud_now()
		return
	var cloud_at := int(cloud.get("saved_at", 0))
	var local_at := int(Time.get_unix_time_from_system()) if _dirty else _saved_at
	if has_profiles() and cloud_at <= local_at:
		_is_cloud_dirty = cloud_at < local_at or _is_cloud_dirty
		_push_cloud_now()
		return
	_adopt_cloud(cloud)


func _adopt_cloud(cloud: Dictionary) -> void:
	profiles = (cloud.get("profiles", {}) as Dictionary).duplicate(true)
	active_profile_id = String(cloud.get("active_profile_id", ""))
	if not profiles.has(active_profile_id):
		active_profile_id = String(profiles.keys()[0])
	_saved_at = int(cloud.get("saved_at", 0))
	_pdata.apply_dict(profiles[active_profile_id])
	_dirty = false
	_is_cloud_dirty = false
	_debounce_timer.stop()
	save_pdata()
	_root_events.ev_profiles_changed.emit()


func _queue_cloud_push() -> void:
	if _services == null or not _services.can_cloud_save:
		return
	_is_cloud_dirty = true
	if _is_cloud_synced and _cloud_push_timer.is_stopped():
		_cloud_push_timer.start(CLOUD_PUSH_SEC)


## Never before the first pull answered (would overwrite a newer cloud copy) and never an empty envelope.
func _push_cloud_now() -> void:
	_cloud_push_timer.stop()
	if not _is_cloud_dirty or not _is_cloud_synced or profiles.is_empty():
		return
	if _services == null or not _services.can_cloud_save:
		return
	_is_cloud_dirty = false
	_services.ev_request_cloud_push.emit(CloudSaveCodec.encode(_envelope()))

func _notification(what: int) -> void:
	match what:
		# App is being torn down: keep writing immediately so late saves
		# (e.g. StatisticsController._exit_tree) still reach disk.
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			_shutting_down = true
			_flush_urgent()
		# Backgrounded but may resume (mobile/web): flush pending, stay debounced.
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_flush_urgent()
