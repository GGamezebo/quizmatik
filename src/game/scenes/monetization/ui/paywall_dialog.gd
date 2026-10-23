class_name PaywallDialog
extends CanvasLayer

## The store's single offer: what it gives, price, «Купить». Buy → owner runs the parental gate + purchase
## and reports back via `set_waiting` / `show_result`. Opened from a valley → that valley on top (art, name,
## what is inside) for the kid; the message below stays for the parent.

signal ev_buy_pressed

@export var screen: Control
@export var title_label: Label
@export var message_label: Label
@export var status_label: Label
@export var buy_button: Button
@export var close_button: BaseButton
@export var valley_box: Control
@export var valley_art: TextureRect
@export var valley_name_label: Label
@export var valley_info_label: Label
@export var levels_config: LevelsConfig
@export var success_close_delay: float = 1.4

const FADE_DURATION: float = 0.2
## offer kind → [title, message] (Russian source, auto-translated by Label).
const TEXTS: Dictionary = {
	&"full_version": [
		"Полная версия",
		"Для родителей: открывает все долины — вычитание, умножение, деление и смешанные примеры. Без рекламы и подписок. Одна покупка — навсегда.",
	],
	&"no_ads": [
		"Без рекламы",
		"Реклама между полётами больше не появится. Одна покупка — навсегда.",
	],
}
## What a valley holds (kid-facing): its exam gives a plane, the last one a trophy.
const VALLEY_INFO_PLANE := "20 уровней, экзамен и новый самолёт!"
const VALLEY_INFO_TROPHY := "20 уровней, экзамен и кубок!"

var _close_tween: Tween


func _ready() -> void:
	hide()
	buy_button.pressed.connect(ev_buy_pressed.emit)
	close_button.pressed.connect(close)


## `container_id` = valley the player tapped ("" = none: settings button).
func open(kind: StringName, price: String, container_id: String = "") -> void:
	if not TEXTS.has(kind):
		push_warning("PaywallDialog: no texts for offer %s" % kind)
		return
	var texts: Array = TEXTS[kind]
	title_label.text = texts[0]
	message_label.text = texts[1]
	_show_valley(container_id)
	buy_button.text = tr("Купить за %s") % price if not price.is_empty() else "Купить"
	status_label.text = ""
	set_waiting(false)
	if _close_tween != null:
		_close_tween.kill()
	screen.modulate.a = 0.0
	show()
	create_tween().tween_property(screen, "modulate:a", 1.0, FADE_DURATION)


func close() -> void:
	hide()


func _show_valley(container_id: String) -> void:
	var container: Dictionary = {}
	if levels_config != null and not container_id.is_empty():
		container = levels_config.find_container_in_config(container_id)
	valley_box.visible = not container.is_empty()
	if container.is_empty():
		return
	valley_art.texture = LevelPackArt.get_art(container_id)
	valley_name_label.text = String(container.get("name", ""))
	var has_plane := not PlaneCatalog.plane_id_for_exam(container_id).is_empty()
	valley_info_label.text = VALLEY_INFO_PLANE if has_plane else VALLEY_INFO_TROPHY


func set_waiting(is_waiting: bool) -> void:
	buy_button.disabled = is_waiting
	close_button.disabled = is_waiting
	if is_waiting:
		status_label.text = "Подождите…"


func show_result(is_success: bool) -> void:
	set_waiting(false)
	if not is_success:
		status_label.text = "Покупка не завершена. Попробуйте ещё раз."
		return
	status_label.text = "Спасибо! Покупка открыта."
	buy_button.disabled = true
	_close_tween = create_tween()
	_close_tween.tween_interval(success_close_delay)
	_close_tween.tween_callback(close)


## Store accepted the payment but has not settled it (cash / slow card): no second «Купить».
func show_pending() -> void:
	set_waiting(false)
	buy_button.disabled = true
	status_label.text = "Оплата ещё обрабатывается. Покупка откроется сама, как только магазин её подтвердит."
