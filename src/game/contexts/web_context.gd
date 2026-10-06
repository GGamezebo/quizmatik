class_name WEBContext
extends PlatformContext

## Generic HTML5 hooks. Opens nested Yandex when export feature `yandex_games` is set.
## Tab hidden / minimized → RootEvents.ev_app_visibility_changed (pause + mute in AppPauseController).

var _document: JavaScriptObject = null
var _on_visibility_cb: JavaScriptObject = null


func _enter() -> void:
	_listen_visibility()
	if OS.has_feature("yandex_games"):
		open_child("ev.open_yandex")

func deinit() -> void:
	if _document != null and _on_visibility_cb != null:
		_document.removeEventListener("visibilitychange", _on_visibility_cb)
	_on_visibility_cb = null
	_document = null
	super.deinit()


func _listen_visibility() -> void:
	_document = JavaScriptBridge.get_interface("document")
	if _document == null:
		return
	# Callback must stay referenced, otherwise JS drops it.
	_on_visibility_cb = JavaScriptBridge.create_callback(_on_visibility_change)
	_document.addEventListener("visibilitychange", _on_visibility_cb)

func _on_visibility_change(_args: Array) -> void:
	if root_events == null or _document == null:
		return
	root_events.ev_app_visibility_changed.emit(String(_document.visibilityState) != "hidden")
