class_name PurchaseOfferButton
extends Button

## Host hook for the store's paid offer («Убрать рекламу» / «Полная версия»). Visible only while
## `App/Monetization` publishes an offer (OfferBoard); press → paywall (with parental gate) there.

@export var offer_board: OfferBoard
@export var placement: StringName = &"settings"

## offer kind → button text (Russian source, auto-translated).
const TEXTS: Dictionary = {
	&"no_ads": "Убрать рекламу",
	&"full_version": "Полная версия",
}

var _listener: EventListener = EventListener.new()


func _ready() -> void:
	pressed.connect(_on_pressed)
	if offer_board != null:
		_listener.add(offer_board.ev_changed, _refresh)
	_refresh()

func _exit_tree() -> void:
	_listener.deinit()


func _refresh() -> void:
	var kind: StringName = offer_board.purchase_kind if offer_board != null else &""
	visible = TEXTS.has(kind)
	if visible:
		text = TEXTS[kind]


func _on_pressed() -> void:
	offer_board.ev_paywall_requested.emit(placement, "")
