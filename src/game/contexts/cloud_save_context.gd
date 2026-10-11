class_name CloudSaveContext
extends PlatformContext

## Base for `*CloudSave` HFSM states (child of a platform context, entered by `ev.open_cloud_save`).
## Game side = `SaveManager`: it talks only through `PlatformServices` cloud signals/cap.
## Subclass: `_open_backend()` → when the backend is usable call `_set_backend_ready()`;
## `_pull()` → `_answer_pull(json)` on success only; `_push(json)` stores the envelope.

var _listener: EventListener = EventListener.new()
var _is_alive: bool = true


func _enter() -> void:
	if services == null:
		return
	_listener.add(services.ev_request_cloud_pull, _pull)
	_listener.add(services.ev_request_cloud_push, _push)
	_open_backend()


func deinit() -> void:
	_is_alive = false
	_listener.deinit()
	if services != null:
		services.set_cloud_save(false)
	super.deinit()


func _open_backend() -> void:
	pass

func _pull() -> void:
	pass

func _push(_json: String) -> void:
	pass


## Listeners are connected before this, so SaveManager's immediate pull request is heard.
func _set_backend_ready() -> void:
	if _is_alive and services != null:
		services.set_cloud_save(true)

func _answer_pull(json: String) -> void:
	if _is_alive and services != null:
		services.ev_cloud_pulled.emit(json)


func _keep(store: Array[JavaScriptObject], method: Callable) -> JavaScriptObject:
	var cb: JavaScriptObject = JavaScriptBridge.create_callback(method)
	store.append(cb)
	return cb
