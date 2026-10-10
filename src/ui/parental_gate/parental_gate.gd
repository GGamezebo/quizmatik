class_name ParentalGate
extends CanvasLayer

## «Только для взрослых» check before purchases / external links (Google Families, Apple Kids).
## Two-digit × two-digit product with 4 choices — above the 7–10 y.o. curriculum. Wrong answer closes the gate.

signal ev_passed
signal ev_canceled

@export var screen: Control
@export var question_label: Label
@export var answer_buttons: Array[Button] = []
@export var cancel_button: BaseButton
@export var factor_min: int = 12
@export var factor_max: int = 29

const FADE_DURATION: float = 0.18

var _answer: int = 0


func _ready() -> void:
	hide()
	cancel_button.pressed.connect(_finish.bind(false))
	for button in answer_buttons:
		button.pressed.connect(_on_answer.bind(button))


func open() -> void:
	var a := randi_range(factor_min, factor_max)
	var b := randi_range(factor_min, factor_max)
	_answer = a * b
	question_label.text = "%d × %d = ?" % [a, b]
	var options: Array[int] = [_answer]
	var decoys: Array[int] = [_answer + a, _answer - a, _answer + b, _answer - b, _answer + 10, _answer - 10]
	decoys.shuffle()
	for decoy in decoys:
		if options.size() >= answer_buttons.size():
			break
		if decoy > 0 and not options.has(decoy):
			options.append(decoy)
	options.shuffle()
	for i in answer_buttons.size():
		answer_buttons[i].text = str(options[i])
	screen.modulate.a = 0.0
	show()
	create_tween().tween_property(screen, "modulate:a", 1.0, FADE_DURATION)


func _on_answer(button: Button) -> void:
	_finish(int(button.text) == _answer)


func _finish(is_passed: bool) -> void:
	hide()
	if is_passed:
		ev_passed.emit()
	else:
		ev_canceled.emit()
