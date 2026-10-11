class_name CrazyGamesCloudSaveContext
extends CloudSaveContext

## `Platform/WEB/CrazyGames/CrazyGamesCloudSave`: save envelope in the SDK data module (`SDK.data.getItem/setItem`,
## key `save`; synced across devices for signed-in players, local for guests). Payload from CrazyGamesContext: `cg_sdk`.

const DATA_KEY := "save"

var _data_module: JavaScriptObject = null


func _open_backend() -> void:
	var sdk := data.get("cg_sdk") as JavaScriptObject
	if sdk == null or sdk.data == null:
		return
	_data_module = sdk.data
	_set_backend_ready()

func deinit() -> void:
	_data_module = null
	super.deinit()


func _pull() -> void:
	if _data_module == null:
		return
	var raw: Variant = _data_module.getItem(DATA_KEY)
	_answer_pull(raw if raw is String else "")

func _push(json: String) -> void:
	if _data_module == null or CloudSaveCodec.is_too_big(json):
		return
	_data_module.setItem(DATA_KEY, json)
