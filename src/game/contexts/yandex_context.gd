class_name YandexContext
extends PlatformContext

## `Platform/WEB/Yandex`: Yandex Games SDK v2 (`/sdk.js` from the Web-Yandex export `head_include`).
## SDK init → LoadingAPI.ready (once menu opened) + `environment.i18n.lang` → PlatformServices.language;
## battle → GameplayAPI start/stop;
## PlatformServices ad requests → fullscreen / rewarded; SDK + ad pause → RootEvents.ev_app_visibility_changed.

const SDK_PAUSE := "game_api_pause"
const SDK_RESUME := "game_api_resume"

var _ysdk: JavaScriptObject = null
var _listener: EventListener = EventListener.new()
var _is_alive: bool = true
var _is_menu_opened: bool = false
var _is_ready_sent: bool = false
var _rewarded_placement: StringName = &""
var _is_rewarded_granted: bool = false
# JS callbacks must stay referenced, otherwise the browser drops them.
var _sdk_callbacks: Array[JavaScriptObject] = []
var _ad_callbacks: Array[JavaScriptObject] = []
var _on_pause_cb: JavaScriptObject = null
var _on_resume_cb: JavaScriptObject = null


func _enter() -> void:
	var ya_games: JavaScriptObject = JavaScriptBridge.get_interface("YaGames")
	if ya_games == null:
		push_warning("YandexContext: YaGames missing — Web-Yandex export must include /sdk.js")
		return
	ya_games.init().then(_keep(_sdk_callbacks, _on_sdk_ready))

func on_event(event_name: String, _data: Dictionary) -> void:
	if event_name == "ev.open_menu":
		_is_menu_opened = true
		_send_ready()

func deinit() -> void:
	_is_alive = false
	_listener.deinit()
	if _ysdk != null:
		_ysdk.off(SDK_PAUSE, _on_pause_cb)
		_ysdk.off(SDK_RESUME, _on_resume_cb)
	if services != null:
		services.set_ads(false, false)
		services.set_language("")
	_ysdk = null
	_sdk_callbacks.clear()
	_ad_callbacks.clear()
	super.deinit()


func _on_sdk_ready(args: Array) -> void:
	if not _is_alive or args.is_empty():
		return
	_ysdk = args[0]
	_on_pause_cb = _keep(_sdk_callbacks, _on_sdk_pause)
	_on_resume_cb = _keep(_sdk_callbacks, _on_sdk_resume)
	_ysdk.on(SDK_PAUSE, _on_pause_cb)
	_ysdk.on(SDK_RESUME, _on_resume_cb)
	if root_events != null:
		_listener.add(root_events.ev_battle_started, _on_battle_started)
		_listener.add(root_events.ev_battle_finished, _on_battle_finished)
	if services != null:
		_listener.add(services.ev_request_interstitial, _show_interstitial)
		_listener.add(services.ev_request_rewarded, _show_rewarded)
		services.set_ads(true, true)
		# Yandex moderation: UI language must follow the SDK, not the browser.
		services.set_language(String(_ysdk.environment.i18n.lang))
	_send_ready()

## Game Ready must fire once, when the player can actually interact (menu requested + SDK up).
func _send_ready() -> void:
	if _is_ready_sent or _ysdk == null or not _is_menu_opened:
		return
	_is_ready_sent = true
	_ysdk.features.LoadingAPI.ready()


func _on_battle_started() -> void:
	_ysdk.features.GameplayAPI.start()

func _on_battle_finished() -> void:
	_ysdk.features.GameplayAPI.stop()


func _on_sdk_pause(_args: Array) -> void:
	_set_visible(false)

func _on_sdk_resume(_args: Array) -> void:
	_set_visible(true)

func _set_visible(is_visible: bool) -> void:
	if _is_alive and root_events != null:
		root_events.ev_app_visibility_changed.emit(is_visible)


func _show_interstitial(_placement: StringName) -> void:
	_ysdk.adv.showFullscreenAdv(_ad_options({
		"onOpen": _on_ad_open,
		"onClose": _on_ad_close,
		"onError": _on_ad_close,
	}))

func _show_rewarded(placement: StringName) -> void:
	_rewarded_placement = placement
	_is_rewarded_granted = false
	_ysdk.adv.showRewardedVideo(_ad_options({
		"onOpen": _on_ad_open,
		"onRewarded": _on_rewarded,
		"onClose": _on_rewarded_close,
		"onError": _on_rewarded_close,
	}))

func _on_ad_open(_args: Array) -> void:
	_set_visible(false)

func _on_ad_close(_args: Array) -> void:
	_set_visible(true)

func _on_rewarded(_args: Array) -> void:
	_is_rewarded_granted = true

func _on_rewarded_close(_args: Array) -> void:
	_set_visible(true)
	if _is_alive and services != null:
		services.ev_rewarded_result.emit(_rewarded_placement, _is_rewarded_granted)


## `{ callbacks: { name: fn } }` for `ysdk.adv.*`; replaces callbacks of the previous ad.
func _ad_options(handlers: Dictionary) -> JavaScriptObject:
	_ad_callbacks.clear()
	var callbacks: JavaScriptObject = JavaScriptBridge.create_object("Object")
	for key: String in handlers:
		callbacks.set(key, _keep(_ad_callbacks, handlers[key]))
	var options: JavaScriptObject = JavaScriptBridge.create_object("Object")
	options.set("callbacks", callbacks)
	return options

func _keep(store: Array[JavaScriptObject], method: Callable) -> JavaScriptObject:
	var cb: JavaScriptObject = JavaScriptBridge.create_callback(method)
	store.append(cb)
	return cb
