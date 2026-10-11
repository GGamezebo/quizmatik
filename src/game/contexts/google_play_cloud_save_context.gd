class_name GooglePlayCloudSaveContext
extends CloudSaveContext

## `Platform/Android/GooglePlay/GooglePlayCloudSave`: save envelope in a Play Games Saved Games snapshot via the
## `godot-play-game-services` plugin (singleton called by name → project compiles without it; missing plugin /
## not signed in = save stays local). Backend is ready only after Play Games sign-in succeeded.
## Plugin signals carry JSON strings; `conflictEmitted` is informational (the plugin resolves by its policy).

const PLUGIN_NAME := "GodotPlayGameServices"
const SNAPSHOT_NAME := "jet_math_progress"
const SNAPSHOT_DESCRIPTION := "Jet Math progress"

var _plugin: Object = null
var _listener_plugin: EventListener = EventListener.new()
var _sign_in_retried: bool = false
var _is_saving: bool = false
var _queued_json: String = ""
var _has_queued: bool = false


func _open_backend() -> void:
	if not Engine.has_singleton(PLUGIN_NAME):
		push_warning("GooglePlayCloudSave: %s plugin missing — save stays local" % PLUGIN_NAME)
		return
	_plugin = Engine.get_singleton(PLUGIN_NAME)
	_listener_plugin.add(Signal(_plugin, "userAuthenticated"), _on_user_authenticated)
	_listener_plugin.add(Signal(_plugin, "gameLoaded"), _on_game_loaded)
	_listener_plugin.add(Signal(_plugin, "gameSaved"), _on_game_saved)
	_listener_plugin.add(Signal(_plugin, "conflictEmitted"), _on_conflict)
	if _plugin.has_method("initialize"):
		_plugin.initialize()
	_plugin.isAuthenticated()

func deinit() -> void:
	_listener_plugin.deinit()
	_plugin = null
	super.deinit()


func _on_user_authenticated(is_authenticated: bool) -> void:
	if not _is_alive:
		return
	if is_authenticated:
		_set_backend_ready()
	elif not _sign_in_retried:
		_sign_in_retried = true
		_plugin.signIn()


func _pull() -> void:
	if _plugin != null:
		_plugin.loadGame(SNAPSHOT_NAME, true)

func _on_game_loaded(json: String) -> void:
	var parsed: Variant = JSON.parse_string(json)
	if not (parsed is Dictionary):
		_answer_pull("")  # snapshot not found (null payload) — nothing stored yet
		return
	_answer_pull(_content_to_text((parsed as Dictionary).get("content")))


## Gson serializes the snapshot bytes as an int array (signed bytes); also accept raw bytes / base64.
func _content_to_text(content: Variant) -> String:
	var bytes := PackedByteArray()
	if content is PackedByteArray:
		bytes = content
	elif content is Array:
		for value: Variant in content as Array:
			bytes.append(int(value) & 0xFF)
	elif content is String:
		bytes = Marshalls.base64_to_raw(content)
	return bytes.get_string_from_utf8()


func _push(json: String) -> void:
	if _plugin == null or CloudSaveCodec.is_too_big(json):
		return
	if _is_saving:
		_queued_json = json
		_has_queued = true
		return
	_is_saving = true
	_plugin.saveGame(SNAPSHOT_NAME, SNAPSHOT_DESCRIPTION, json.to_utf8_buffer(), 0, 0)

func _on_game_saved(_is_saved: bool, _name: String, _description: String) -> void:
	_is_saving = false
	if _has_queued:
		_has_queued = false
		_push(_queued_json)


func _on_conflict(_json: String) -> void:
	push_warning("GooglePlayCloudSave: snapshot conflict reported by plugin")
