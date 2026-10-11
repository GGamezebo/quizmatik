class_name CrazyGamesShopContext
extends AdsOnlyShopContext

## `Platform/WEB/CrazyGames/CrazyGamesShop`: `SDK.ad.requestAd("midgame" | "rewarded", callbacks)`.
## Mute + pause on `adStarted` (not on request: ad may be unfilled), resume on `adFinished` / `adError`.
## Reward only on `adFinished`. Midgame frequency (≤ 1 per 3 min) is enforced by the SDK itself.

var _sdk: JavaScriptObject = null
var _rewarded_placement: StringName = &""


func _enter() -> void:
	_sdk = data.get("cg_sdk") as JavaScriptObject
	if _sdk == null:
		return
	super._enter()

func deinit() -> void:
	_sdk = null
	super.deinit()


func _start_interstitial(_placement: StringName) -> void:
	_request("midgame", Callable())

func _start_rewarded(placement: StringName) -> void:
	_rewarded_placement = placement
	_request("rewarded", _on_rewarded_done)


func _request(type: String, on_done: Callable) -> void:
	_ad_callbacks.clear()
	var callbacks: JavaScriptObject = JavaScriptBridge.create_object("Object")
	callbacks.set("adStarted", _keep(func(_args: Array) -> void: _set_ad_open(true)))
	callbacks.set("adFinished", _keep(func(_args: Array) -> void: _finish(on_done, true)))
	callbacks.set("adError", _keep(func(_args: Array) -> void: _finish(on_done, false)))
	_sdk.ad.requestAd(type, callbacks)

func _finish(on_done: Callable, is_granted: bool) -> void:
	_set_ad_open(false)
	if on_done.is_valid():
		on_done.call(is_granted)

func _on_rewarded_done(is_granted: bool) -> void:
	_answer_rewarded(_rewarded_placement, is_granted)
	_rewarded_placement = &""
