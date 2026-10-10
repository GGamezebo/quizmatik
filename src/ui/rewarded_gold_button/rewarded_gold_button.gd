class_name RewardedGoldButton
extends Button

## Host hook «+N 🪙 за рекламу». Visible only while `App/Monetization` offers rewarded ads (OfferBoard);
## default board (testers / no store) → always hidden. Knows nothing about platforms or limits.

@export var offer_board: OfferBoard
@export var placement: StringName = &"post_battle"
## true → one reward per screen (post-battle), then shows «получено»; false → offer again (hangar).
@export var once_per_screen: bool = true

var _amount: int = 1
var _is_pending: bool = false
var _granted: int = 0
var _listener: EventListener = EventListener.new()


func _ready() -> void:
	pressed.connect(_on_pressed)
	if offer_board != null:
		_listener.add(offer_board.ev_changed, _refresh)
		_listener.add(offer_board.ev_rewarded_gold_finished, _on_finished)
		_amount = offer_board.rewarded_gold(0)
	_refresh()

func _exit_tree() -> void:
	_listener.deinit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()


## Gold already given on this screen (post-battle: level + bonus) → rewarded payout doubles it.
func setup(earned: int) -> void:
	_is_pending = false
	_granted = 0
	if offer_board != null:
		_amount = offer_board.rewarded_gold(earned)
	_refresh()


func _refresh() -> void:
	var is_offered := offer_board != null and offer_board.is_rewarded_available
	visible = is_offered or _granted > 0
	disabled = _is_pending or _granted > 0
	if _granted > 0:
		text = tr("+%d получено!") % _granted
	else:
		text = tr("+%d за рекламу") % _amount


func _on_pressed() -> void:
	if _is_pending or offer_board == null:
		return
	_is_pending = true
	_refresh()
	offer_board.ev_rewarded_gold_requested.emit(placement, _amount)


func _on_finished(finished_placement: StringName, granted: int) -> void:
	if finished_placement != placement or not _is_pending:
		return
	_is_pending = false
	if granted > 0 and once_per_screen:
		_granted = granted
	_refresh()
