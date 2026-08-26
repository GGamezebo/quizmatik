extends VBoxContainer
class_name TrainingOpColumn

## One operation column: title + exclusive option pills.

signal selection_changed(option_id: StringName)

@export var title_label: Label
@export var options_box: VBoxContainer
@export var option_button_scene: PackedScene
@export var column_title: String = "":
	set(value):
		column_title = value
		if title_label != null:
			title_label.text = value

var _buttons: Dictionary = {} # StringName -> TrainingOptionButton
var _selected_id: StringName = &"off"


func _ready() -> void:
	if title_label != null and not column_title.is_empty():
		title_label.text = column_title


func setup_options(options: Array) -> void:
	## options: Array of {id: StringName, caption: String}
	if options_box == null or option_button_scene == null:
		return
	for child in options_box.get_children():
		child.queue_free()
	_buttons.clear()
	for entry in options:
		var btn: TrainingOptionButton = option_button_scene.instantiate() as TrainingOptionButton
		btn.option_id = entry["id"]
		btn.caption = str(entry["caption"])
		btn.option_selected.connect(_on_option_selected)
		options_box.add_child(btn)
		_buttons[btn.option_id] = btn
	call_deferred("set_selected", _selected_id)


func set_selected(option_id: StringName) -> void:
	if not _buttons.has(option_id):
		option_id = &"off"
	_selected_id = option_id
	for id in _buttons.keys():
		(_buttons[id] as TrainingOptionButton).set_selected(id == option_id)


func get_selected_id() -> StringName:
	return _selected_id


func _on_option_selected(option_id: StringName) -> void:
	set_selected(option_id)
	selection_changed.emit(option_id)
