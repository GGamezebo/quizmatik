class_name GreetingCard
extends CanvasLayer

## RuStore «Привет от разработчиков» card (overlay, not a stacked window): thanks text, channel links,
## «Оценить игру» / «Поделиться» styled like the parents report. Opens nothing itself: link →
## `ev_link_pressed(url)`, rate / share → own signals. Closes on the back button, tap on the dim, `ui_cancel`.

signal ev_link_pressed(url: String)
signal ev_rate_pressed
signal ev_share_pressed

@export var screen: Control
@export var dim: Control
@export var close_button: BaseButton
@export var link_buttons: Array[GreetingLinkButton] = []
@export var rate_button: Button
@export var share_button: Button
@export var support_hint: Label

const FADE_DURATION: float = 0.22
## Same keys as the parents report (`ParentsWindow`).
const HINT_TEXT := "Спасибо, что помогаете игре расти!"
const RATE_THANKS := "Спасибо за поддержку! Нам важно ваше мнение."
const SHARE_THANKS := "Спасибо, что помогаете игре находить новых друзей!"

var _hint_tween: Tween


func _ready() -> void:
	hide()
	close_button.pressed.connect(close)
	dim.gui_input.connect(_on_dim_gui_input)
	for button in link_buttons:
		button.pressed.connect(_on_link_pressed.bind(button))
	rate_button.pressed.connect(_on_rate_pressed)
	share_button.pressed.connect(_on_share_pressed)


func set_caps(can_rate: bool, can_share: bool) -> void:
	rate_button.visible = can_rate
	share_button.visible = can_share
	support_hint.visible = can_rate or can_share


func open() -> void:
	if visible:
		return
	support_hint.text = HINT_TEXT
	screen.modulate.a = 0.0
	show()
	create_tween().tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)


func close() -> void:
	hide()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_dim_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null and mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
		close()


func _on_link_pressed(button: GreetingLinkButton) -> void:
	if not button.url.is_empty():
		ev_link_pressed.emit(button.url)


## The store / share sheet has no completion callback: thank the intention, never claim it succeeded.
func _on_rate_pressed() -> void:
	_show_thanks(RATE_THANKS)
	ev_rate_pressed.emit()


func _on_share_pressed() -> void:
	_show_thanks(SHARE_THANKS)
	ev_share_pressed.emit()


func _show_thanks(message: String) -> void:
	support_hint.text = message
	if _hint_tween != null:
		_hint_tween.kill()
	support_hint.modulate.a = 0.25
	_hint_tween = create_tween()
	_hint_tween.tween_property(support_hint, "modulate:a", 1.0, 0.3)
