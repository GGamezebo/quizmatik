extends Node

## Rare, low-contrast emphasis for adult support actions; never changes geometry.
@export var buttons: Array[BaseButton] = []
@export var timer: Timer
@export_range(1.0, 1.1, 0.005) var brightness: float = 1.035
@export var fade_in_sec: float = 0.6
@export var fade_out_sec: float = 0.9

var _base_colors: Dictionary[BaseButton, Color] = {}
var _tweens: Dictionary[BaseButton, Tween] = {}


func _ready() -> void:
	for button in buttons:
		_base_colors[button] = button.self_modulate
		button.visibility_changed.connect(_restart)
		button.mouse_entered.connect(_restart)
		button.button_down.connect(_restart)
		button.focus_entered.connect(_restart)
	timer.timeout.connect(_pulse)


func _exit_tree() -> void:
	_stop()


func _restart() -> void:
	_stop()
	timer.start()


func _stop() -> void:
	for tween in _tweens.values():
		tween.kill()
	_tweens.clear()
	for button in _base_colors:
		if is_instance_valid(button):
			button.self_modulate = _base_colors[button]


func _pulse() -> void:
	_stop()
	for button in buttons:
		if not button.is_visible_in_tree() or button.disabled or button.is_hovered() or button.has_focus() or button.is_pressed():
			continue
		var base: Color = _base_colors[button]
		var glow := Color(base.r * brightness, base.g * brightness, base.b * brightness, base.a)
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tweens[button] = tween
		tween.tween_property(button, "self_modulate", glow, fade_in_sec)
		tween.tween_property(button, "self_modulate", base, fade_out_sec)
