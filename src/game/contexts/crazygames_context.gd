class_name CrazyGamesContext
extends PlatformContext

## `Platform/WEB/CrazyGames`: CrazyGames HTML5 SDK v3 (`window.CrazyGames.SDK`, script from the Web-CrazyGames
## export `head_include`). SDK init → loadingStart; menu opened → loadingStop; battle → gameplayStart/Stop.
## Ads live in child `CrazyGames/CrazyGamesShop` (opened after init unless `no_monetization`), cloud save in
## `CrazyGames/CrazyGamesCloudSave` (SDK data module). Payload to children: `cg_sdk`.

var _sdk: JavaScriptObject = null
var _listener: EventListener = EventListener.new()
var _is_alive: bool = true
var _is_menu_opened: bool = false
var _is_loading_stopped: bool = false
# JS callbacks must stay referenced, otherwise the browser drops them.
var _sdk_callbacks: Array[JavaScriptObject] = []


func _enter() -> void:
	var cg: JavaScriptObject = JavaScriptBridge.get_interface("CrazyGames")
	if cg == null or cg.SDK == null:
		push_warning("CrazyGamesContext: CrazyGames.SDK missing — Web-CrazyGames export must include the SDK script")
		return
	var sdk: JavaScriptObject = cg.SDK
	var cb: JavaScriptObject = JavaScriptBridge.create_callback(_on_sdk_ready.bind(sdk))
	_sdk_callbacks.append(cb)
	sdk.init().then(cb)

func on_event(event_name: String, _data: Dictionary) -> void:
	if event_name == "ev.open_menu":
		_is_menu_opened = true
		_stop_loading()

func deinit() -> void:
	_is_alive = false
	_listener.deinit()
	_sdk = null
	_sdk_callbacks.clear()
	super.deinit()


func _on_sdk_ready(_args: Array, sdk: JavaScriptObject) -> void:
	if not _is_alive:
		return
	_sdk = sdk
	_sdk.game.loadingStart()
	if root_events != null:
		_listener.add(root_events.ev_battle_started, _on_battle_started)
		_listener.add(root_events.ev_battle_finished, _on_battle_finished)
	_stop_loading()
	var extra := {"cg_sdk": _sdk}
	open_cloud_save(extra)
	open_shop(extra)

func _stop_loading() -> void:
	if _is_loading_stopped or _sdk == null or not _is_menu_opened:
		return
	_is_loading_stopped = true
	_sdk.game.loadingStop()


func _on_battle_started() -> void:
	_sdk.game.gameplayStart()

func _on_battle_finished() -> void:
	_sdk.game.gameplayStop()
