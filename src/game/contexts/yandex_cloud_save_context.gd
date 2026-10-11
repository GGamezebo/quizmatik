class_name YandexCloudSaveContext
extends CloudSaveContext

## `Platform/WEB/Yandex/YandexCloudSave`: save envelope in Yandex player data (`player.setData` / `getData`,
## key `save`, 200 KB limit). Payload from YandexContext: `ysdk`. A rejected SDK call = no answer
## (game stays local-only), never an «empty cloud» answer.

const DATA_KEY := "save"

var _player: JavaScriptObject = null
# JS callbacks must stay referenced, otherwise the browser drops them.
var _callbacks: Array[JavaScriptObject] = []


func _open_backend() -> void:
	var ysdk := data.get("ysdk") as JavaScriptObject
	if ysdk == null:
		return
	ysdk.getPlayer().then(_keep(_callbacks, _on_player), _keep(_callbacks, _on_failed))

func deinit() -> void:
	_player = null
	_callbacks.clear()
	super.deinit()


func _on_player(args: Array) -> void:
	if not _is_alive or args.is_empty():
		return
	_player = args[0]
	_set_backend_ready()


func _pull() -> void:
	if _player == null:
		return
	var keys: JavaScriptObject = JavaScriptBridge.create_object("Array")
	keys.push(DATA_KEY)
	_player.getData(keys).then(_keep(_callbacks, _on_data), _keep(_callbacks, _on_failed))

func _on_data(args: Array) -> void:
	var raw: Variant = null
	if not args.is_empty() and args[0] is JavaScriptObject:
		raw = (args[0] as JavaScriptObject).get(DATA_KEY)
	_answer_pull(raw if raw is String else "")


func _push(json: String) -> void:
	if _player == null or CloudSaveCodec.is_too_big(json):
		return
	var payload: JavaScriptObject = JavaScriptBridge.create_object("Object")
	payload.set(DATA_KEY, json)
	_player.setData(payload, true).then(null, _keep(_callbacks, _on_failed))


func _on_failed(args: Array) -> void:
	push_warning("YandexCloudSave: SDK call failed %s" % [args])
