class_name AdsOnlyShopContext
extends PlatformContext

## Base for portal `*Shop` states without payments (CrazyGames, Poki): interstitial + rewarded ads, nothing for sale
## (`offer_kind` stays empty → no paywall / purchase UI). Subclass: `_start_interstitial` / `_start_rewarded`
## call the portal SDK; `_set_ad_open(true/false)` around the ad (pause + mute); rewarded always ends in
## `_answer_rewarded` (granted only on the SDK's «finished» signal, never on error).

var _listener: EventListener = EventListener.new()
var _is_alive: bool = true
var _is_ad_open: bool = false
# JS callbacks must stay referenced, otherwise the browser drops them.
var _ad_callbacks: Array[JavaScriptObject] = []


func _enter() -> void:
	if services == null:
		return
	_listener.add(services.ev_request_interstitial, _start_interstitial)
	_listener.add(services.ev_request_rewarded, _start_rewarded)
	services.set_ads(true, true)
	open_monetization()

func deinit() -> void:
	_is_alive = false
	_listener.deinit()
	if services != null:
		services.set_ads(false, false)
	_ad_callbacks.clear()
	super.deinit()


func _start_interstitial(_placement: StringName) -> void:
	pass

func _start_rewarded(placement: StringName) -> void:
	_answer_rewarded(placement, false)


## Idempotent: SDKs may report «error» after «finished».
func _set_ad_open(is_open: bool) -> void:
	if _is_ad_open == is_open:
		return
	_is_ad_open = is_open
	if _is_alive and root_events != null:
		root_events.ev_app_visibility_changed.emit(not is_open)

func _answer_rewarded(placement: StringName, is_granted: bool) -> void:
	if _is_alive and services != null:
		services.ev_rewarded_result.emit(placement, is_granted)


func _keep(method: Callable) -> JavaScriptObject:
	var cb: JavaScriptObject = JavaScriptBridge.create_callback(method)
	_ad_callbacks.append(cb)
	return cb
