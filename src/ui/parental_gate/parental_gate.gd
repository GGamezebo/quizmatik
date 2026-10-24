class_name ParentalGate
extends CanvasLayer

## «Только для взрослых» check before purchases / external links (Google Families, Apple Kids).
## Two-digit × two-digit product (12–16: still above the 7–10 y.o. curriculum, fine in an adult's head)
## with 4 close choices. Wrong answer locks the answers for `retry_cooldown_sec` (survives close / reopen),
## then a new example — no fast guessing.

signal ev_passed
signal ev_canceled

@export var screen: Control
@export var message_label: Label
@export var question_label: Label
@export var answer_buttons: Array[Button] = []
@export var cancel_button: BaseButton
@export var factor_min: int = 12
@export var factor_max: int = 16
@export var retry_cooldown_sec: float = 30.0

const FADE_DURATION: float = 0.18
const MESSAGE_ASK := "Чтобы продолжить, попросите взрослого решить пример:"
const MESSAGE_WAIT := "Ответ неверный. Новый пример через %d с."

var _answer: int = 0
var _retry_at_msec: int = 0


func _ready() -> void:
	hide()
	set_process(false)
	cancel_button.pressed.connect(_finish.bind(false))
	for button in answer_buttons:
		button.pressed.connect(_on_answer.bind(button))


func open() -> void:
	if _is_cooling_down():
		_show_cooldown()
	else:
		_new_question()
	screen.modulate.a = 0.0
	show()
	create_tween().tween_property(screen, "modulate:a", 1.0, FADE_DURATION)


## Host leaves (window closed under the gate): hide without `ev_passed` / `ev_canceled`.
func close() -> void:
	set_process(false)
	hide()


func _process(_delta: float) -> void:
	if _is_cooling_down():
		_show_cooldown()
	else:
		set_process(false)
		_new_question()


func _new_question() -> void:
	message_label.text = MESSAGE_ASK
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
		answer_buttons[i].disabled = false


func _on_answer(button: Button) -> void:
	if int(button.text) == _answer:
		_finish(true)
		return
	_retry_at_msec = Time.get_ticks_msec() + int(retry_cooldown_sec * 1000.0)
	_show_cooldown()


func _is_cooling_down() -> bool:
	return Time.get_ticks_msec() < _retry_at_msec


func _show_cooldown() -> void:
	var left := ceili((_retry_at_msec - Time.get_ticks_msec()) / 1000.0)
	message_label.text = tr(MESSAGE_WAIT) % maxi(left, 1)
	for button in answer_buttons:
		button.disabled = true
	set_process(true)


func _finish(is_passed: bool) -> void:
	set_process(false)
	hide()
	if is_passed:
		ev_passed.emit()
	else:
		ev_canceled.emit()
