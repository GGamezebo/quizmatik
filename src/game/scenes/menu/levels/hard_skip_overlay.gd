class_name HardSkipOverlay
extends CanvasLayer

## HARD profile entering an addition / subtraction valley: «you already know this — take the exam now»,
## with the gold for the exam plus every skipped level. Buttons only signal up; the level grid acts.

signal ev_exam_pressed
signal ev_in_order_pressed
signal ev_canceled

@export var screen: Control
@export var gold_label: Label
@export var exam_button: BaseButton
@export var in_order_button: BaseButton
@export var cancel_button: BaseButton

const FADE_DURATION: float = 0.22


func _ready() -> void:
	hide()
	if exam_button:
		exam_button.pressed.connect(_on_exam)
	if in_order_button:
		in_order_button.pressed.connect(_on_in_order)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel)


## `gold` = exam + skipped-levels reward shown on the coin.
func open(gold: int) -> void:
	if gold_label:
		gold_label.text = "+%d" % gold
	screen.modulate.a = 0.0
	show()
	create_tween().tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)


func close() -> void:
	hide()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_cancel()
		get_viewport().set_input_as_handled()


func _on_exam() -> void:
	close()
	ev_exam_pressed.emit()


func _on_in_order() -> void:
	close()
	ev_in_order_pressed.emit()


func _on_cancel() -> void:
	close()
	ev_canceled.emit()
