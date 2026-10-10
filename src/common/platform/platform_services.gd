class_name PlatformServices
extends Resource

## Game ↔ platform contract. Game reads caps + emits requests; the active HFSM platform context
## (`src/game/contexts/`) answers. Default `.tres` = no platform: caps off → game hides ad entry points.

@warning_ignore("unused_signal") signal ev_caps_changed
@warning_ignore("unused_signal") signal ev_language_changed
## Game → platform. `placement` = where in the game the ad is shown (e.g. &"post_battle").
## Interstitial only between battles, never during gameplay (Yandex / Play policy).
@warning_ignore("unused_signal") signal ev_request_interstitial(placement: StringName)
@warning_ignore("unused_signal") signal ev_request_rewarded(placement: StringName)
## Platform → game. Always answered after `ev_request_rewarded` (`is_granted` false on error / skip).
@warning_ignore("unused_signal") signal ev_rewarded_result(placement: StringName, is_granted: bool)
## Game → store: buy the store's single offer (`offer_kind`). Parental gate is passed before this.
@warning_ignore("unused_signal") signal ev_request_purchase
## Store → game. Always answered after `ev_request_purchase` (false on cancel / error / pending).
@warning_ignore("unused_signal") signal ev_purchase_result(is_success: bool)

## Offer kinds (one paid offer per store).
const OFFER_NO_ADS := &"no_ads"
const OFFER_FULL_VERSION := &"full_version"

var can_interstitial: bool = false
var can_rewarded: bool = false
## Platform-reported UI language (e.g. Yandex `environment.i18n.lang`); empty = unknown → OS locale.
var language: String = ""
## Store's paid offer still for sale; empty = nothing to buy (no store / already owned).
var offer_kind: StringName = &""
## Store-formatted price («199 ₽», «$2.99»); empty = unknown.
var offer_price: String = ""
## true only while a freemium store reports the full version NOT owned → paid valleys locked.
## Default false: no store / store unreachable → everything open.
var is_content_locked: bool = false


## Called only by platform contexts (on SDK ready / on deinit).
func set_ads(interstitial: bool, rewarded: bool) -> void:
	if can_interstitial == interstitial and can_rewarded == rewarded:
		return
	can_interstitial = interstitial
	can_rewarded = rewarded
	ev_caps_changed.emit()


## Called only by store contexts (catalog / purchases loaded, bought, deinit).
func set_offer(kind: StringName, price: String) -> void:
	if offer_kind == kind and offer_price == price:
		return
	offer_kind = kind
	offer_price = price
	ev_caps_changed.emit()


## Called only by store contexts.
func set_content_locked(locked: bool) -> void:
	if is_content_locked == locked:
		return
	is_content_locked = locked
	ev_caps_changed.emit()


## Called only by platform contexts (on SDK ready / on deinit).
func set_language(lang: String) -> void:
	if language == lang:
		return
	language = lang
	ev_language_changed.emit()
