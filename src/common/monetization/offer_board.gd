class_name OfferBoard
extends Resource

## Host UI ↔ `App/Monetization`. Host scenes only read this board and emit requests;
## they never touch PlatformServices. State is published only by the Monetization scene,
## which is mounted only when a store context is up → default `.tres` (testers) = no offers, all valleys open.

@warning_ignore("unused_signal") signal ev_changed
## Host → Monetization: player tapped «+N 🪙 за рекламу».
@warning_ignore("unused_signal") signal ev_rewarded_gold_requested(placement: StringName, amount: int)
## Monetization → host: `granted` = gold given (0 = not watched / limit / error).
@warning_ignore("unused_signal") signal ev_rewarded_gold_finished(placement: StringName, granted: int)
## Host → Monetization: open the paywall (paid valley tap, settings button).
@warning_ignore("unused_signal") signal ev_paywall_requested(placement: StringName)

## Valleys that stay free when the store sells the full version.
@export var free_container_ids: Array[String] = ["addition"]
@export var min_rewarded_gold: int = 1
@export var max_rewarded_gold: int = 5

var is_rewarded_available: bool = false
## Mirrors PlatformServices.offer_kind / offer_price (empty kind = nothing for sale).
var purchase_kind: StringName = &""
var purchase_price: String = ""
var is_content_locked: bool = false


## Rewarded payout for a screen where `earned` gold was already given (post-battle: ×2, at least min).
func rewarded_gold(earned: int) -> int:
	return clampi(earned, min_rewarded_gold, max_rewarded_gold)


func is_container_paywalled(container_id: String) -> bool:
	return is_content_locked and not free_container_ids.has(container_id)


## Called only by `App/Monetization`.
func publish(rewarded: bool, kind: StringName, price: String, content_locked: bool) -> void:
	if (
		is_rewarded_available == rewarded and purchase_kind == kind
		and purchase_price == price and is_content_locked == content_locked
	):
		return
	is_rewarded_available = rewarded
	purchase_kind = kind
	purchase_price = price
	is_content_locked = content_locked
	ev_changed.emit()
