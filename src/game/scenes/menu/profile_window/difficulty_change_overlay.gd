class_name DifficultyChangeOverlay
extends CanvasLayer

## Shown when a pilot with progress switches to / from EASY (grade 1 has its own examples):
## explains that difficulty = school grade and offers a fresh pilot instead (old one stays).
## Buttons only signal up; the profile window creates the pilot or applies the difficulty.

signal ev_create_pressed(difficulty: StringName)
signal ev_keep_pressed(difficulty: StringName)
signal ev_canceled

@export var screen: Control
@export var from_grade: Label
@export var from_example: MathLabel
@export var to_grade: Label
@export var to_example: MathLabel
@export var create_button: BaseButton
## Shown instead of `create_button` when all pilot slots are taken.
@export var full_note: Control
@export var keep_button: BaseButton
@export var cancel_button: BaseButton

const FADE_DURATION: float = 0.22
## Grade caption (same keys as `DifficultyPicker` hints) + a typical example per difficulty.
const GRADES: Dictionary = {
	&"easy": ["1 класс", "8 + 7"],
	&"normal": ["2–3 класс", "38 + 27"],
	&"hard": ["3–4 класс", "38 + 27"],
}

var _target: StringName = BattleDifficulty.NORMAL


func _ready() -> void:
	hide()
	if create_button:
		create_button.pressed.connect(_on_create)
	if keep_button:
		keep_button.pressed.connect(_on_keep)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel)


func open(from_difficulty: StringName, to_difficulty: StringName, can_create: bool) -> void:
	_target = BattleDifficulty.sanitize(to_difficulty)
	_fill(from_grade, from_example, BattleDifficulty.sanitize(from_difficulty))
	_fill(to_grade, to_example, _target)
	if create_button:
		create_button.visible = can_create
	if full_note:
		full_note.visible = not can_create
	screen.modulate.a = 0.0
	show()
	create_tween().tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)


func close() -> void:
	hide()


func _fill(grade: Label, example: MathLabel, difficulty: StringName) -> void:
	var row: Array = GRADES.get(difficulty, GRADES[BattleDifficulty.NORMAL])
	if grade:
		grade.text = String(row[0])
	if example:
		example.set_math_text(String(row[1]))


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_cancel()
		get_viewport().set_input_as_handled()


func _on_create() -> void:
	close()
	ev_create_pressed.emit(_target)


func _on_keep() -> void:
	close()
	ev_keep_pressed.emit(_target)


func _on_cancel() -> void:
	close()
	ev_canceled.emit()
