class_name ProfileCreateOverlay
extends CanvasLayer

signal ev_submitted(display_name: String, difficulty: StringName)
signal ev_canceled

@export var screen: Control
@export var title_label: Label
@export var name_edit: LineEdit
@export var difficulty_header: Control
@export var difficulty_picker: DifficultyPicker
@export var confirm_button: BaseButton
@export var cancel_button: BaseButton
## Slid up while the name is typed on touch so the virtual keyboard doesn't cover the field.
@export var keyboard_lift_target: Control

const FADE_DURATION: float = 0.22
const KEYBOARD_GAP: float = 16.0
const SCREEN_TOP_MARGIN: float = 8.0
## Keyboard top (share of screen height) when the platform can't report its height (web).
const FALLBACK_KEYBOARD_TOP: float = 0.45
const LIFT_SPEED: float = 14.0

var _allow_cancel: bool = true
## Current upward shift of `keyboard_lift_target` (applied via offsets, never `position`:
## an anchored Control converts `position` with a possibly stale size and grows off screen).
var _lift: float = 0.0


func _ready() -> void:
	hide()
	layer = 40
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel)
	if name_edit:
		name_edit.text_submitted.connect(_on_name_submitted)


## `show_difficulty = false` for rename: difficulty is changed on the profile card itself.
func open(allow_cancel: bool = true, title: String = "Кто будет пилотом?", show_difficulty: bool = true) -> void:
	_allow_cancel = allow_cancel
	if title_label:
		title_label.text = title
	if cancel_button:
		cancel_button.visible = allow_cancel
	if difficulty_header:
		difficulty_header.visible = show_difficulty
	if difficulty_picker:
		difficulty_picker.visible = show_difficulty
	configure("", BattleDifficulty.NORMAL)
	screen.modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)
	# Touch: the name is prefilled, so don't pop the virtual keyboard over the form.
	if name_edit and not DisplayServer.is_touchscreen_available():
		name_edit.grab_focus()


func configure(display_name: String, difficulty: StringName) -> void:
	if name_edit:
		name_edit.text = ProfileController.display_name_or_default(display_name)
	if difficulty_picker:
		difficulty_picker.set_value(difficulty)


func close() -> void:
	hide()
	_apply_lift(0.0)


func _process(delta: float) -> void:
	if not visible or keyboard_lift_target == null:
		return
	var target := _keyboard_lift()
	if is_equal_approx(_lift, target):
		return
	_apply_lift(lerpf(_lift, target, minf(1.0, delta * LIFT_SPEED)))


func _apply_lift(value: float) -> void:
	_lift = 0.0 if absf(value) < 0.5 else value
	if keyboard_lift_target:
		keyboard_lift_target.offset_top = -_lift
		keyboard_lift_target.offset_bottom = -_lift


## How far to lift the form so the name field sits above the virtual keyboard.
func _keyboard_lift() -> float:
	if name_edit == null or not name_edit.is_editing() or not DisplayServer.is_touchscreen_available():
		return 0.0
	var view_h := get_viewport().get_visible_rect().size.y
	var keyboard_top := view_h * FALLBACK_KEYBOARD_TOP
	var keyboard_px := DisplayServer.virtual_keyboard_get_height()
	var window_h := DisplayServer.window_get_size().y
	if keyboard_px > 0 and window_h > 0:
		keyboard_top = view_h - keyboard_px * view_h / float(window_h)
	var field := name_edit.get_global_rect()
	var field_top := field.position.y + _lift
	var field_bottom := field.end.y + _lift
	var lift := field_bottom + KEYBOARD_GAP - keyboard_top
	return clampf(lift, 0.0, maxf(0.0, field_top - SCREEN_TOP_MARGIN))


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# Android back while typing only hides the keyboard; it must not drop the form.
		if name_edit and name_edit.is_editing():
			name_edit.unedit()
			get_viewport().set_input_as_handled()
			return
		if _allow_cancel:
			_on_cancel()
		get_viewport().set_input_as_handled()


func _on_name_submitted(_text: String) -> void:
	_on_confirm()


func _on_confirm() -> void:
	var display_name := ""
	if name_edit:
		display_name = name_edit.text.strip_edges()
	var difficulty: StringName = BattleDifficulty.NORMAL
	if difficulty_picker:
		difficulty = difficulty_picker.value
	close()
	ev_submitted.emit(display_name, difficulty)


func _on_cancel() -> void:
	if not _allow_cancel:
		return
	close()
	ev_canceled.emit()

