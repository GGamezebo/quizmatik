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
## Store → game, instead of `ev_purchase_result`: payment accepted but not settled yet (Play pending:
## cash / slow card). Content unlocks later by itself via `set_content_locked` / `set_offer`.
@warning_ignore("unused_signal") signal ev_purchase_pending

## Game → platform: read the cloud copy of the save. Answered by `ev_cloud_pulled` only on success
## (no answer = cloud unreachable → game stays local-only this session, never overwrites the cloud).
@warning_ignore("unused_signal") signal ev_request_cloud_pull
## Platform → game. `json` = cloud envelope (`CloudSaveCodec`), "" = nothing stored yet.
@warning_ignore("unused_signal") signal ev_cloud_pulled(json: String)
## Game → platform: store this envelope in the cloud (fire and forget; failures retried by the next push).
@warning_ignore("unused_signal") signal ev_request_cloud_push(json: String)

## Game → store: the store's own in-app review sheet. The store decides whether it shows (quota), no answer;
## never from a button (nothing may happen) — buttons use `ev_request_rate_page`.
@warning_ignore("unused_signal") signal ev_request_review
## Game → store: open the game's store page to rate it (button).
@warning_ignore("unused_signal") signal ev_request_rate_page
## Game → platform: system share sheet with `text` + the game's store link (`placement` tags the link for
## store acquisition reports); `image_path` = `user://` PNG to attach ("" = text only; attach failed → text).
## No answer, never rewarded; only from behind a parental gate (parents report, purchase thank-you page).
@warning_ignore("unused_signal") signal ev_request_share(placement: StringName, text: String, image_path: String)

## Offer kinds (one paid offer per store).
const OFFER_NO_ADS := &"no_ads"
const OFFER_FULL_VERSION := &"full_version"

var can_interstitial: bool = false
var can_rewarded: bool = false
## true while a platform context can store the save in the platform cloud (signed in / SDK up).
## Default false: no platform / not signed in → save stays local only.
var can_cloud_save: bool = false
## Platform-reported UI language (e.g. Yandex `environment.i18n.lang`); empty = unknown → OS locale.
var language: String = ""
## UI languages this platform build offers (`GameLocale.SUPPORTED` codes); empty = all of them.
var languages: PackedStringArray = []
## Store's paid offer still for sale; empty = nothing to buy (no store / already owned).
var offer_kind: StringName = &""
## Store-formatted price («199 ₽», «$2.99»); empty = unknown.
var offer_price: String = ""
## true only while a freemium store reports the full version NOT owned → paid valleys locked.
## Default false: no store / store unreachable → everything open.
var is_content_locked: bool = false
## true while a store context answers `ev_request_review` / `ev_request_rate_page`.
var can_rate: bool = false
## true while a platform context answers `ev_request_share` (store build with a public page to link).
## Default false: portals / desktop / tester builds → no share button.
var can_share: bool = false


## Called only by platform contexts (on SDK ready / on deinit).
func set_ads(interstitial: bool, rewarded: bool) -> void:
	if can_interstitial == interstitial and can_rewarded == rewarded:
		return
	can_interstitial = interstitial
	can_rewarded = rewarded
	ev_caps_changed.emit()


## Called only by store platform contexts (`GooglePlayContext`, fake `DevShopContext`; on enter / deinit).
func set_rate(enabled: bool) -> void:
	if can_rate == enabled:
		return
	can_rate = enabled
	ev_caps_changed.emit()


## Called only by store platform contexts (`GooglePlayContext`, `RuStoreContext`, fake `DevShopContext`).
func set_share(enabled: bool) -> void:
	if can_share == enabled:
		return
	can_share = enabled
	ev_caps_changed.emit()


## Called only by cloud-save contexts (backend ready / on deinit).
func set_cloud_save(enabled: bool) -> void:
	if can_cloud_save == enabled:
		return
	can_cloud_save = enabled
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


## Called only by platform contexts (on enter / `[]` on deinit).
func set_languages(codes: PackedStringArray) -> void:
	if languages == codes:
		return
	languages = codes
	ev_language_changed.emit()
