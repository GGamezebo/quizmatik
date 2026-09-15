class_name ProfileCreateOverlay
extends CanvasLayer

signal ev_submitted(display_name: String, gender: String, age: int)
signal ev_canceled

@export var screen: Control
@export var title_label: Label
@export var name_edit: LineEdit
@export var boy_button: Button
@export var girl_button: Button
@export var age_label: Label
@export var age_minus: Button
@export var age_plus: Button
@export var confirm_button: BaseButton
@export var cancel_button: BaseButton

const FADE_DURATION: float = 0.22

var _gender: String = "boy"
var _age: int = ProfileController.DEFAULT_AGE
var _allow_cancel: bool = true


func _ready() -> void:
	hide()
	layer = 40
	if boy_button:
		boy_button.pressed.connect(_on_boy)
	if girl_button:
		girl_button.pressed.connect(_on_girl)
	if age_minus:
		age_minus.pressed.connect(_on_age_minus)
	if age_plus:
		age_plus.pressed.connect(_on_age_plus)
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel)
	_refresh_identity()


func open(allow_cancel: bool = true, title: String = "Кто будет пилотом?") -> void:
	_allow_cancel = allow_cancel
	if title_label:
		title_label.text = title
	if cancel_button:
		cancel_button.visible = allow_cancel
	configure("", "boy", ProfileController.DEFAULT_AGE)
	screen.modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)
	if name_edit:
		name_edit.grab_focus()


func configure(display_name: String, gender: String, age: int) -> void:
	if name_edit:
		name_edit.text = display_name
	_gender = "girl" if gender == "girl" else "boy"
	_age = clampi(age, ProfileController.MIN_AGE, ProfileController.MAX_AGE)
	_refresh_identity()


func close() -> void:
	hide()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _allow_cancel:
			_on_cancel()
		get_viewport().set_input_as_handled()


func _on_boy() -> void:
	_gender = "boy"
	_refresh_identity()


func _on_girl() -> void:
	_gender = "girl"
	_refresh_identity()


func _on_age_minus() -> void:
	_age = maxi(ProfileController.MIN_AGE, _age - 1)
	_refresh_identity()


func _on_age_plus() -> void:
	_age = mini(ProfileController.MAX_AGE, _age + 1)
	_refresh_identity()


func _refresh_identity() -> void:
	if boy_button:
		boy_button.button_pressed = _gender == "boy"
	if girl_button:
		girl_button.button_pressed = _gender == "girl"
	if age_label:
		age_label.text = str(_age)


func _on_confirm() -> void:
	var display_name := ""
	if name_edit:
		display_name = name_edit.text.strip_edges()
	close()
	ev_submitted.emit(display_name, _gender, _age)


func _on_cancel() -> void:
	if not _allow_cancel:
		return
	close()
	ev_canceled.emit()
