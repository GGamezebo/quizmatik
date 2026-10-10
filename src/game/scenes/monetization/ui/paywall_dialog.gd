class_name PaywallDialog
extends CanvasLayer

## The store's single offer: what it gives, price, «Купить». Buy → owner runs the parental gate + purchase
## and reports back via `set_waiting` / `show_result`.

signal ev_buy_pressed

@export var screen: Control
@export var title_label: Label
@export var message_label: Label
@export var status_label: Label
@export var buy_button: Button
@export var close_button: BaseButton
@export var success_close_delay: float = 1.4

const FADE_DURATION: float = 0.2
## offer kind → [title, message] (Russian source, auto-translated by Label).
const TEXTS: Dictionary = {
	&"full_version": [
		"Полная версия",
		"Все долины: вычитание, умножение, деление и смешанные примеры. Одна покупка — навсегда.",
	],
	&"no_ads": [
		"Без рекламы",
		"Реклама между полётами больше не появится. Одна покупка — навсегда.",
	],
}

var _close_tween: Tween


func _ready() -> void:
	hide()
	buy_button.pressed.connect(ev_buy_pressed.emit)
	close_button.pressed.connect(close)


func open(kind: StringName, price: String) -> void:
	var texts: Array = TEXTS.get(kind, TEXTS[&"no_ads"])
	title_label.text = texts[0]
	message_label.text = texts[1]
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
