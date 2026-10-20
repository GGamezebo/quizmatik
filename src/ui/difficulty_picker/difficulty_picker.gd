class_name DifficultyPicker
extends HBoxContainer

## Three exclusive cards (easy / normal / hard). `set_value` is silent; a tap emits `ev_changed`.

signal ev_changed(difficulty: StringName)

@export var easy_button: Button
@export var normal_button: Button
@export var hard_button: Button

var value: StringName = BattleDifficulty.NORMAL


## Cards sit edge to edge: opt out of the host's hover pop (on touch it sticks and overlaps neighbours).
## `_enter_tree` runs before any `HoverScaleBinder._ready` binds the subtree.
func _enter_tree() -> void:
	for button in [easy_button, normal_button, hard_button]:
		if button != null:
			button.set_meta(HoverScaleButton.META_BOUND, true)


func _ready() -> void:
	_wire(easy_button, BattleDifficulty.EASY)
	_wire(normal_button, BattleDifficulty.NORMAL)
	_wire(hard_button, BattleDifficulty.HARD)
	_refresh()


func set_value(difficulty: StringName) -> void:
	value = BattleDifficulty.sanitize(difficulty)
	_refresh()


func _wire(button: Button, id: StringName) -> void:
	if button != null:
		button.pressed.connect(_on_pick.bind(id))


func _on_pick(id: StringName) -> void:
	var changed := id != value
	value = id
	_refresh()
	if changed:
		ev_changed.emit(id)


func _refresh() -> void:
	_set_selected(easy_button, value == BattleDifficulty.EASY)
	_set_selected(normal_button, value == BattleDifficulty.NORMAL)
	_set_selected(hard_button, value == BattleDifficulty.HARD)


func _set_selected(button: Button, selected: bool) -> void:
	if button != null:
		button.set_pressed_no_signal(selected)
