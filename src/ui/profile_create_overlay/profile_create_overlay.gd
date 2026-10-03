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

const FADE_DURATION: float = 0.22

var _allow_cancel: bool = true


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
	configure(ProfileController.DEFAULT_NAME, BattleDifficulty.NORMAL)
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


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
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

