class_name CelebrationSplash
extends CanvasLayer

## Queued full-screen celebrations: valley unlock, new plane, daily gold, math master (last valley).
## Not on the window stack. Hold while exam trophy dialog is up.
## Valley sold by the store (OfferBoard paywall) → «waits in the full version» + buy button → paywall.

const KIND_VALLEY := "valley"
const KIND_PLANE := "plane"
const KIND_DAILY_GOLD := "daily_gold"
const KIND_MASTER := "master"
const FADE_DURATION: float = 0.22
const PAYWALLED_ART_TINT := Color(0.78, 0.78, 0.78)

@export var root_events: RootEvents
@export var screen: Control
@export var title_label: Label
@export var message_label: Label
@export var art_rect: TextureRect
@export var confirm_button: BaseButton
## Shown only for a paywalled valley; press → `OfferBoard.ev_paywall_requested`.
@export var buy_button: BaseButton
@export var offer_board: OfferBoard
@export var levels_config: LevelsConfig
## Gold coin art for the daily-gold celebration.
@export var gold_art: Texture2D
## Art for the "math master" celebration (last valley exam).
@export var master_art: Texture2D
## Flying ribbons — emitted only during the master celebration.
@export var ribbons: CPUParticles2D

var _queue: Array[Dictionary] = []
var _busy: bool = false
var _held: bool = false
var _listener: EventListener = EventListener.new()


func _ready() -> void:
	hide()
	layer = 15
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if buy_button:
		buy_button.hide()
		buy_button.pressed.connect(_on_buy_pressed)
	if root_events != null:
		_listener.add(root_events.ev_show_celebration, _on_show_celebration)
		_listener.add(root_events.ev_celebration_hold, _on_hold)
		_listener.add(root_events.ev_celebration_unhold, _on_unhold)


func _exit_tree() -> void:
	_listener.deinit()


func enqueue(kind: String, payload: Dictionary = {}) -> void:
	_queue.append({"kind": kind, "payload": payload})
	_try_show_next()


func _on_show_celebration(kind: String, payload: Dictionary = {}) -> void:
	enqueue(kind, payload)


func _on_hold() -> void:
	_held = true


func _on_unhold() -> void:
	_held = false
	_try_show_next()


func _try_show_next() -> void:
	if _busy or _held or _queue.is_empty():
		return
	var item: Dictionary = _queue.pop_front()
	_present(String(item.get("kind", "")), item.get("payload", {}) as Dictionary)


func _present(kind: String, payload: Dictionary) -> void:
	_busy = true
	if buy_button:
		buy_button.hide()
	match kind:
		KIND_VALLEY:
			_present_valley(String(payload.get("container_id", "")))
		KIND_PLANE:
			_present_plane(String(payload.get("plane_id", PlaneCatalog.STARTER_ID)))
		KIND_DAILY_GOLD:
			_present_daily_gold()
		KIND_MASTER:
			_present_master()
		_:
			_busy = false
			_try_show_next()
			return
	screen.modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)


func _present_valley(container_id: String) -> void:
	art_rect.texture = LevelPackArt.get_art(container_id)
	if offer_board != null and offer_board.is_container_paywalled(container_id):
		title_label.text = "Новая долина ждёт!"
		message_label.text = tr("«%s» — в полной версии. Покажи родителям!") % tr(_container_name(container_id))
		art_rect.modulate = PAYWALLED_ART_TINT
		if buy_button:
			buy_button.show()
		return
	title_label.text = "Долина открыта"
	message_label.text = _container_name(container_id)
	art_rect.modulate = Color.WHITE


func _present_plane(plane_id: String) -> void:
	var def: Dictionary = PlaneCatalog.get_def(plane_id)
	title_label.text = "У тебя новый самолёт!"
	message_label.text = String(def.get("name", ""))
	PlaneCatalog.apply_preview(art_rect, plane_id)


func _present_daily_gold() -> void:
	title_label.text = "Молодец! +1 золотая"
	message_label.text = "Награда за ежедневную серию 5/5"
	art_rect.texture = gold_art
	art_rect.modulate = Color.WHITE


func _present_master() -> void:
	title_label.text = "Мастер счёта!"
	message_label.text = "Все долины пройдены! Ты — настоящий мастер математики!"
	art_rect.texture = master_art
	art_rect.modulate = Color.WHITE
	_set_ribbons(true)


func _set_ribbons(on: bool) -> void:
	if ribbons == null:
		return
	ribbons.visible = on
	if on:
		ribbons.restart()
	ribbons.emitting = on


func _container_name(container_id: String) -> String:
	if levels_config == null or container_id.is_empty():
		return container_id
	var container: Dictionary = levels_config.find_container_in_config(container_id)
	return String(container.get("name", container_id))


func _on_confirm_pressed() -> void:
	hide()
	_set_ribbons(false)
	_busy = false
	_try_show_next()


func _on_buy_pressed() -> void:
	_on_confirm_pressed()
	offer_board.ev_paywall_requested.emit(&"valley_splash")
