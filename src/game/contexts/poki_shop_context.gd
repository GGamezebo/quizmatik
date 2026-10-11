class_name PokiShopContext
extends AdsOnlyShopContext

## `Platform/WEB/Poki/PokiShop`: `PokiSDK.commercialBreak()` / `rewardedBreak()` (promises). Poki asks to mute
## and block input for the whole break and restore in `.then` (the start callback is not reliable) →
## pause + mute from the request until the promise resolves. `rewardedBreak` resolves `true` = ad was shown → reward.
## Not every commercialBreak shows an ad; Monetization pacing still applies on top.

var _poki: JavaScriptObject = null
var _rewarded_placement: StringName = &""


func _enter() -> void:
	_poki = data.get("poki") as JavaScriptObject
	if _poki == null:
		return
	super._enter()

func deinit() -> void:
	_poki = null
	super.deinit()


func _start_interstitial(_placement: StringName) -> void:
	_set_ad_open(true)
	_ad_callbacks.clear()
	_poki.commercialBreak().then(_keep(func(_args: Array) -> void: _set_ad_open(false)))

func _start_rewarded(placement: StringName) -> void:
	_rewarded_placement = placement
	_set_ad_open(true)
	_ad_callbacks.clear()
	_poki.rewardedBreak().then(_keep(func(args: Array) -> void:
		_set_ad_open(false)
		_answer_rewarded(_rewarded_placement, not args.is_empty() and args[0] == true)
	))
