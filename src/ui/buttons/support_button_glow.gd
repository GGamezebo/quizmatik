extends Node

## Rare fill highlight for adult support actions; text and geometry stay unchanged.
@export var buttons: Array[BaseButton] = []
@export var timer: Timer
@export_range(0.0, 1.0, 0.05) var highlight_strength: float = 1.0
@export var fade_in_sec: float = 0.8
@export var fade_out_sec: float = 1.2

var _styles: Dictionary[BaseButton, StyleBoxFlat] = {}
var _base_colors: Dictionary[BaseButton, Color] = {}
var _highlight_colors: Dictionary[BaseButton, Color] = {}
var _original_styles: Dictionary[BaseButton, StyleBox] = {}
var _had_override: Dictionary[BaseButton, bool] = {}
var _tweens: Dictionary[BaseButton, Tween] = {}


func _ready() -> void:
	for button in buttons:
		var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
		var hover := button.get_theme_stylebox("hover") as StyleBoxFlat
		if normal == null or hover == null:
			continue
		_original_styles[button] = normal
		_had_override[button] = button.has_theme_stylebox_override("normal")
		var style := normal.duplicate() as StyleBoxFlat
		_styles[button] = style
		_base_colors[button] = style.bg_color
		_highlight_colors[button] = style.bg_color.lerp(hover.bg_color, highlight_strength)
		button.add_theme_stylebox_override("normal", style)
		button.visibility_changed.connect(_restart)
		button.mouse_entered.connect(_stop_button.bind(button))
		button.button_down.connect(_stop_button.bind(button))
		button.focus_entered.connect(_stop_button.bind(button))
	timer.timeout.connect(_pulse)


func _exit_tree() -> void:
	_stop()
	for button in _original_styles:
		if not is_instance_valid(button):
			continue
		if _had_override[button]:
			button.add_theme_stylebox_override("normal", _original_styles[button])
		else:
			button.remove_theme_stylebox_override("normal")


func _restart() -> void:
	_stop()
	timer.start()


func _stop_button(button: BaseButton) -> void:
	if _tweens.has(button):
		_tweens[button].kill()
		_tweens.erase(button)
	if _styles.has(button):
		_styles[button].bg_color = _base_colors[button]


func _stop() -> void:
	for button in _styles:
		_stop_button(button)


func _pulse() -> void:
	_stop()
	for button in _styles:
		if not button.is_visible_in_tree() or button.disabled or button.is_hovered() or button.is_pressed():
			continue
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tweens[button] = tween
		tween.tween_property(_styles[button], "bg_color", _highlight_colors[button], fade_in_sec)
		tween.tween_property(_styles[button], "bg_color", _base_colors[button], fade_out_sec)
