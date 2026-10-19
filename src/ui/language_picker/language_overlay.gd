class_name LanguageOverlay
extends CanvasLayer

## Full language list (overlay, not a stacked window): big cards with flag + native name, default language first.
## Tap a card → `ev_chosen(code)`; closes on back button, tap on the dim, `ui_cancel`.

signal ev_chosen(code: String)

@export var screen: Control
@export var dim: Control
@export var grid: GridContainer
@export var close_button: BaseButton
@export var card_scene: PackedScene
## Pause after a choice so the new check mark is seen before the overlay fades.
@export var close_delay: float = 0.25

const FADE_DURATION: float = 0.2

var _cards: Array[LanguageCard] = []


func _ready() -> void:
	hide()
	close_button.pressed.connect(close)
	dim.gui_input.connect(_on_dim_gui_input)


## `langs` already in picker order; `flags` = code → flag texture.
func open(langs: PackedStringArray, active: String, flags: Dictionary[String, Texture2D]) -> void:
	for card in _cards:
		grid.remove_child(card)
		card.free()
	_cards.clear()
	for code in langs:
		var card: LanguageCard = card_scene.instantiate()
		grid.add_child(card)
		card.setup(code, flags.get(code), code == active)
		card.pressed.connect(_on_card_pressed.bind(code))
		_cards.append(card)
	screen.modulate.a = 0.0
	show()
	create_tween().tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not visible:
		return
	hide()


func _on_card_pressed(code: String) -> void:
	for card in _cards:
		card.set_active(card.code == code)
	ev_chosen.emit(code)
	var tween := create_tween()
	tween.tween_interval(close_delay)
	tween.tween_property(screen, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(close)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_dim_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null and mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
		close()
