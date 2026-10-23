extends IScene

## `App/Monetization`: game-side ad / purchase rules, platform-agnostic. Mounted only by a store context
## (`*Shop` under App/Platform) → tester builds (no store or feature `no_monetization`) never load it.
## Bridges OfferBoard (host UI hooks) ↔ PlatformServices (store): interstitial pacing, rewarded gold
## with a per-device daily limit, paywall + parental gate (thank-you page «Оценить игру» → store page).
## F6 alone = defaults, nothing for sale.

const STATE_PATH: String = "user://monetization.json"

@export var platform_services: PlatformServices
## Only for `ev_celebration_music` while the purchase thank-you page is up.
@export var root_events: RootEvents
@export var offer_board: OfferBoard
@export var profile_controller: ProfileController
@export var paywall_dialog: PaywallDialog
@export var parental_gate: ParentalGate
## Placements whose host is already behind its own parental gate («Для родителей» window) → «Купить» goes
## straight to the store, no second example.
@export var gated_placements: Array[StringName] = [&"parents"]
@export_group("Interstitial")
## Session battles before the first interstitial (kids' first minutes stay ad-free).
@export var interstitial_min_battles: int = 3
@export var interstitial_cooldown_sec: float = 180.0
@export_group("Rewarded")
## Per device (not per pilot) so switching profiles is not a gold farm.
@export var rewarded_daily_limit: int = 5

var _listener: EventListener = EventListener.new()
var _battles: int = 0
var _last_interstitial_msec: int = -1
var _pending_placement: StringName = &""
var _pending_gold: int = 0
var _is_purchasing: bool = false
var _paywall_placement: StringName = &""
var _rewarded_day: String = ""
var _rewarded_count: int = 0


func initialize(_data: Dictionary) -> void:
	_load_state()
	_listener.add(platform_services.ev_caps_changed, _publish)
	_listener.add(platform_services.ev_rewarded_result, _on_rewarded_result)
	_listener.add(platform_services.ev_purchase_result, _on_purchase_result)
	_listener.add(platform_services.ev_purchase_pending, _on_purchase_pending)
	_listener.add(offer_board.ev_rewarded_gold_requested, _on_rewarded_requested)
	_listener.add(offer_board.ev_paywall_requested, _on_paywall_requested)
	_listener.add(paywall_dialog.ev_buy_pressed, _on_buy_pressed)
	_listener.add(paywall_dialog.ev_rate_pressed, platform_services.ev_request_rate_page.emit)
	_listener.add(paywall_dialog.ev_thanks_shown, root_events.ev_celebration_music.emit)
	_listener.add(parental_gate.ev_passed, _on_gate_passed)
	_publish()

func deinit() -> void:
	paywall_dialog.close()
	_listener.deinit()
	offer_board.publish(false, &"", "", false)
	super.deinit()

func on_event(event_name: String, _data: Dictionary) -> void:
	match event_name:
		"ev.exit_game":
			_battles += 1
		"ev.open_menu":
			_maybe_show_interstitial()


func _publish() -> void:
	offer_board.publish(
		platform_services.can_rewarded and _rewarded_left() > 0,
		platform_services.offer_kind,
		platform_services.offer_price,
		platform_services.is_content_locked,
	)


# --- Interstitial: only on the way back to the menu between battles ---

func _maybe_show_interstitial() -> void:
	if not platform_services.can_interstitial or _battles < interstitial_min_battles:
		return
	var now := Time.get_ticks_msec()
	if _last_interstitial_msec >= 0 and now - _last_interstitial_msec < int(interstitial_cooldown_sec * 1000.0):
		return
	_last_interstitial_msec = now
	platform_services.ev_request_interstitial.emit(&"menu_return")


# --- Rewarded gold ---

func _on_rewarded_requested(placement: StringName, amount: int) -> void:
	if not _pending_placement.is_empty():
		return
	if not platform_services.can_rewarded or _rewarded_left() <= 0:
		offer_board.ev_rewarded_gold_finished.emit(placement, 0)
		return
	_pending_placement = placement
	_pending_gold = clampi(amount, offer_board.min_rewarded_gold, offer_board.max_rewarded_gold)
	platform_services.ev_request_rewarded.emit(placement)

func _on_rewarded_result(placement: StringName, is_granted: bool) -> void:
	if placement != _pending_placement:
		return
	var granted := _pending_gold if is_granted else 0
	_pending_placement = &""
	_pending_gold = 0
	if granted > 0:
		_rewarded_count += 1
		_save_state()
		profile_controller.add_gold(granted)
	offer_board.ev_rewarded_gold_finished.emit(placement, granted)
	_publish()

func _rewarded_left() -> int:
	if _rewarded_day != _today():
		return rewarded_daily_limit
	return maxi(0, rewarded_daily_limit - _rewarded_count)


# --- Purchase: paywall → parental gate → store ---

func _on_paywall_requested(placement: StringName, container_id: String) -> void:
	if platform_services.offer_kind.is_empty():
		return
	_paywall_placement = placement
	paywall_dialog.open(platform_services.offer_kind, platform_services.offer_price, container_id)

func _on_buy_pressed() -> void:
	if gated_placements.has(_paywall_placement):
		_on_gate_passed()
		return
	parental_gate.open()

func _on_gate_passed() -> void:
	_is_purchasing = true
	paywall_dialog.set_waiting(true)
	platform_services.ev_request_purchase.emit()

func _on_purchase_result(is_success: bool) -> void:
	if not _is_purchasing:
		return
	_is_purchasing = false
	paywall_dialog.show_result(is_success, platform_services.can_rate)

func _on_purchase_pending() -> void:
	if not _is_purchasing:
		return
	_is_purchasing = false
	paywall_dialog.show_pending()


# --- Per-device state (not in PData: shared by all pilots) ---

func _today() -> String:
	return Time.get_date_string_from_system(true)

func _load_state() -> void:
	var state: Dictionary = ResourceUtils.load_json_dict(STATE_PATH)
	_rewarded_day = String(state.get("rewarded_day", ""))
	_rewarded_count = int(state.get("rewarded_count", 0))

func _save_state() -> void:
	if _rewarded_day != _today():
		_rewarded_day = _today()
		_rewarded_count = 1
	ResourceUtils.save_json(STATE_PATH, {"rewarded_day": _rewarded_day, "rewarded_count": _rewarded_count}, false)
