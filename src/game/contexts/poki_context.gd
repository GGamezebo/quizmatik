class_name PokiContext
extends PlatformContext

## `Platform/WEB/Poki`: Poki SDK (`PokiSDK`, script from the Web-Poki export `head_include`).
## `init()` (success or failure — never block the game) → shop; menu opened → `gameLoadingFinished()` once;
## battle → gameplayStart/Stop. Ads live in child `Poki/PokiShop` (unless `no_monetization`). No cloud save
## (Poki has no player-data API; save stays local). Payload to children: `poki`.

var _poki: JavaScriptObject = null
var _listener: EventListener = EventListener.new()
var _is_alive: bool = true
var _is_menu_opened: bool = false
var _is_loading_sent: bool = false
# JS callbacks must stay referenced, otherwise the browser drops them.
var _sdk_callbacks: Array[JavaScriptObject] = []


func _enter() -> void:
	var poki: JavaScriptObject = JavaScriptBridge.get_interface("PokiSDK")
	if poki == null:
		push_warning("PokiContext: PokiSDK missing — Web-Poki export must include the SDK script")
		return
	var cb: JavaScriptObject = JavaScriptBridge.create_callback(_on_sdk_done.bind(poki))
	_sdk_callbacks.append(cb)
	poki.init().then(cb, cb)

func on_event(event_name: String, _data: Dictionary) -> void:
	if event_name == "ev.open_menu":
		_is_menu_opened = true
		_send_loading_finished()

func deinit() -> void:
	_is_alive = false
	_listener.deinit()
	_poki = null
	_sdk_callbacks.clear()
	super.deinit()


func _on_sdk_done(_args: Array, poki: JavaScriptObject) -> void:
	if not _is_alive:
		return
	_poki = poki
	if root_events != null:
		_listener.add(root_events.ev_battle_started, _on_battle_started)
		_listener.add(root_events.ev_battle_finished, _on_battle_finished)
	_send_loading_finished()
	open_shop({"poki": _poki})

func _send_loading_finished() -> void:
	if _is_loading_sent or _poki == null or not _is_menu_opened:
		return
	_is_loading_sent = true
	_poki.gameLoadingFinished()


func _on_battle_started() -> void:
	_poki.gameplayStart()

func _on_battle_finished() -> void:
	_poki.gameplayStop()
