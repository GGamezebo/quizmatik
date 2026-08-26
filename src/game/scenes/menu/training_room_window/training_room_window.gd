extends Control

## Simplified practice setup: per-op range columns + difficulty presets → GameConfig.

const SAVE_PATH := "user://training_settings.json"
const UI_SAVE_PATH := "user://training_ui_presets.json"

const ADD_SUB_OPTIONS: Array = [
	{"id": &"off", "caption": "Выключено", "min": 0, "max": 0},
	{"id": &"r10", "caption": "1 - 10", "min": 1, "max": 10},
	{"id": &"r20", "caption": "1 - 20", "min": 1, "max": 20},
	{"id": &"r100", "caption": "1 - 100", "min": 1, "max": 100},
	{"id": &"r1000", "caption": "1 - 1000", "min": 1, "max": 1000},
]

const MUL_DIV_OPTIONS: Array = [
	{"id": &"off", "caption": "Выключено", "min": 0, "max": 0},
	{"id": &"t10", "caption": "×1 - ×10", "min": 1, "max": 10},
	{"id": &"t12", "caption": "×1 - ×12", "min": 1, "max": 12},
	{"id": &"custom", "caption": "Выбери сам", "min": -1, "max": -1},
]

const DIFFICULTY_COPY: Dictionary = {
	&"easy": "Спокойный темп, больше времени на пример",
	&"normal": "Средний темп, стандартное время на пример",
	&"hard": "Быстрый темп, меньше времени на пример",
}

@export var config: GameConfig
@export_group("Columns")
@export var col_addition: TrainingOpColumn
@export var col_subtraction: TrainingOpColumn
@export var col_multiplication: TrainingOpColumn
@export var col_division: TrainingOpColumn
@export_group("Difficulty")
@export var difficulty_hint: Label
@export var difficulty_easy: TrainingOptionButton
@export var difficulty_normal: TrainingOptionButton
@export var difficulty_hard: TrainingOptionButton
@export_group("Custom range")
@export var custom_range_row: Control
@export var custom_min_stepper: TrainingStepper
@export var custom_max_stepper: TrainingStepper
@export_group("Actions")
@export var reset_button: BaseButton
@export var start_battle_button: BaseButton

var _op_ids: Dictionary = {
	&"addition": &"r10",
	&"subtraction": &"off",
	&"multiplication": &"off",
	&"division": &"off",
}
var _difficulty: StringName = &"normal"
var _custom_min: int = 1
var _custom_max: int = 15
var _syncing: bool = false


func _ready() -> void:
	_setup_columns()
	_bind_difficulty()
	_bind_custom_range()
	if reset_button != null:
		reset_button.pressed.connect(_on_reset_setting_pressed)
	_load_all()
	_sync_ui()
	_apply_to_config()


func _setup_columns() -> void:
	_setup_column(col_addition, "СЛОЖЕНИЕ  +", ADD_SUB_OPTIONS, &"addition")
	_setup_column(col_subtraction, "ВЫЧИТАНИЕ  −", ADD_SUB_OPTIONS, &"subtraction")
	_setup_column(col_multiplication, "УМНОЖЕНИЕ  ×", _mul_options_captions(), &"multiplication")
	_setup_column(col_division, "ДЕЛЕНИЕ  ÷", _div_options_captions(), &"division")


func _mul_options_captions() -> Array:
	return [
		{"id": &"off", "caption": "Выключено"},
		{"id": &"t10", "caption": "×1 - ×10"},
		{"id": &"t12", "caption": "×1 - ×12"},
		{"id": &"custom", "caption": "Выбери сам"},
	]


func _div_options_captions() -> Array:
	return [
		{"id": &"off", "caption": "Выключено"},
		{"id": &"t10", "caption": "÷1 - ÷10"},
		{"id": &"t12", "caption": "÷1 - ÷12"},
		{"id": &"custom", "caption": "Выбери сам"},
	]


func _setup_column(column: TrainingOpColumn, title: String, options: Array, key: StringName) -> void:
	if column == null:
		return
	column.column_title = title
	column.setup_options(options)
	column.selection_changed.connect(func(option_id: StringName):
		if _syncing:
			return
		_op_ids[key] = option_id
		_on_ui_changed()
	)


func _bind_difficulty() -> void:
	_wire_difficulty_btn(difficulty_easy, &"easy")
	_wire_difficulty_btn(difficulty_normal, &"normal")
	_wire_difficulty_btn(difficulty_hard, &"hard")


func _wire_difficulty_btn(btn: TrainingOptionButton, id: StringName) -> void:
	if btn == null:
		return
	btn.option_id = id
	btn.option_selected.connect(func(option_id: StringName):
		if _syncing:
			return
		_difficulty = option_id
		_on_ui_changed()
	)


func _bind_custom_range() -> void:
	if custom_min_stepper != null:
		custom_min_stepper.step = 1.0
		custom_min_stepper.min_value = 1.0
		custom_min_stepper.max_value = 100.0
		custom_min_stepper.decimals = 0
		custom_min_stepper.value_changed.connect(func(v: float):
			if _syncing:
				return
			_custom_min = int(v)
			if _custom_max < _custom_min:
				_custom_max = _custom_min
				if custom_max_stepper != null:
					custom_max_stepper.set_value(_custom_max)
			_on_ui_changed()
		)
	if custom_max_stepper != null:
		custom_max_stepper.step = 1.0
		custom_max_stepper.min_value = 1.0
		custom_max_stepper.max_value = 100.0
		custom_max_stepper.decimals = 0
		custom_max_stepper.value_changed.connect(func(v: float):
			if _syncing:
				return
			_custom_max = int(v)
			if _custom_min > _custom_max:
				_custom_min = _custom_max
				if custom_min_stepper != null:
					custom_min_stepper.set_value(_custom_min)
			_on_ui_changed()
		)


func _on_ui_changed() -> void:
	_set_difficulty_buttons(_difficulty)
	_refresh_custom_range_visibility()
	_refresh_difficulty_hint()
	_apply_to_config()
	_save_all()


func _sync_ui() -> void:
	_syncing = true
	if col_addition != null:
		col_addition.set_selected(_op_ids[&"addition"])
	if col_subtraction != null:
		col_subtraction.set_selected(_op_ids[&"subtraction"])
	if col_multiplication != null:
		col_multiplication.set_selected(_op_ids[&"multiplication"])
	if col_division != null:
		col_division.set_selected(_op_ids[&"division"])
	_set_difficulty_buttons(_difficulty)
	if custom_min_stepper != null:
		custom_min_stepper.set_value(_custom_min)
	if custom_max_stepper != null:
		custom_max_stepper.set_value(_custom_max)
	_refresh_custom_range_visibility()
	_refresh_difficulty_hint()
	_syncing = false


func _set_difficulty_buttons(id: StringName) -> void:
	if difficulty_easy != null:
		difficulty_easy.set_selected(id == &"easy")
	if difficulty_normal != null:
		difficulty_normal.set_selected(id == &"normal")
	if difficulty_hard != null:
		difficulty_hard.set_selected(id == &"hard")


func _refresh_difficulty_hint() -> void:
	if difficulty_hint != null:
		difficulty_hint.text = str(DIFFICULTY_COPY.get(_difficulty, DIFFICULTY_COPY[&"normal"]))


func _refresh_custom_range_visibility() -> void:
	var need_custom: bool = (
		_op_ids[&"multiplication"] == &"custom"
		or _op_ids[&"division"] == &"custom"
	)
	if custom_range_row != null:
		custom_range_row.visible = need_custom


func _range_for_op(key: StringName) -> Vector2i:
	var id: StringName = _op_ids[key]
	if id == &"off":
		return Vector2i(0, 0)
	if id == &"custom":
		return Vector2i(_custom_min, maxi(_custom_min, _custom_max))
	var table: Array = ADD_SUB_OPTIONS if key == &"addition" or key == &"subtraction" else MUL_DIV_OPTIONS
	for entry in table:
		if entry["id"] == id:
			return Vector2i(int(entry["min"]), int(entry["max"]))
	return Vector2i(1, 10)


func _apply_to_config() -> void:
	if config == null:
		return

	var flags: int = 0
	var min_n: int = 9999
	var max_n: int = 1
	var any_on: bool = false

	var pairs: Array = [
		[&"addition", GameConfig.Operations.ADDITION],
		[&"subtraction", GameConfig.Operations.SUBTRACTION],
		[&"multiplication", GameConfig.Operations.MULTIPLICATION],
		[&"division", GameConfig.Operations.DIVISION],
	]
	for pair in pairs:
		var key: StringName = pair[0]
		var op_flag: int = pair[1]
		var rng: Vector2i = _range_for_op(key)
		if rng.x <= 0 or rng.y <= 0 or _op_ids[key] == &"off":
			continue
		flags |= op_flag
		any_on = true
		min_n = mini(min_n, rng.x)
		max_n = maxi(max_n, rng.y)

	if not any_on:
		flags = GameConfig.Operations.ADDITION
		min_n = 1
		max_n = 10
		_op_ids[&"addition"] = &"r10"
		if col_addition != null and not _syncing:
			_syncing = true
			col_addition.set_selected(&"r10")
			_syncing = false

	config.allowed_operations = flags
	config.min_generate_number = mini(min_n, max_n)
	config.max_generate_number = maxi(min_n, max_n)
	_apply_difficulty_to_config()
	_save_config_to_disk()


func _apply_difficulty_to_config() -> void:
	match _difficulty:
		&"easy":
			config.health = 5
			config.questions_count = 5
			config.answer_speed = 45.0
			config.answer_speed_round_coeffs = {}
		&"hard":
			config.health = 2
			config.questions_count = 12
			config.answer_speed = 120.0
			config.answer_speed_round_coeffs = {4: 1.25, 8: 1.5}
		_:
			config.health = 3
			config.questions_count = 8
			config.answer_speed = 80.0
			config.answer_speed_round_coeffs = {5: 1.2}
	config.early_exam_questions_multiplier = 1.0
	config.early_exam_answer_speed_multiplier = 1.0


func _on_reset_setting_pressed() -> void:
	_op_ids = {
		&"addition": &"r10",
		&"subtraction": &"off",
		&"multiplication": &"off",
		&"division": &"off",
	}
	_difficulty = &"normal"
	_custom_min = 1
	_custom_max = 15
	_sync_ui()
	_apply_to_config()
	_save_all()


func _load_all() -> void:
	_load_ui_presets()
	_load_config_from_disk()


func _load_config_from_disk() -> void:
	if config == null:
		return
	var result: Dictionary = ResourceUtils.load_json(SAVE_PATH)
	match int(result["status"]):
		ResourceUtils.JsonLoadStatus.OK:
			ResourceUtils.apply_dict(config, result["data"])
		ResourceUtils.JsonLoadStatus.CORRUPT:
			var bak: Dictionary = ResourceUtils.load_json(ResourceUtils.bak_path(SAVE_PATH))
			if int(bak["status"]) == ResourceUtils.JsonLoadStatus.OK:
				ResourceUtils.apply_dict(config, bak["data"])
				ResourceUtils.save_json(SAVE_PATH, ResourceUtils.resource_to_dict(config), false)


func _save_config_to_disk() -> void:
	if config != null:
		ResourceUtils.save_json(SAVE_PATH, ResourceUtils.resource_to_dict(config))


func _load_ui_presets() -> void:
	var result: Dictionary = ResourceUtils.load_json(UI_SAVE_PATH)
	if int(result["status"]) != ResourceUtils.JsonLoadStatus.OK:
		return
	var data: Dictionary = result["data"]
	_op_ids[&"addition"] = StringName(str(data.get("addition", "r10")))
	_op_ids[&"subtraction"] = StringName(str(data.get("subtraction", "off")))
	_op_ids[&"multiplication"] = StringName(str(data.get("multiplication", "off")))
	_op_ids[&"division"] = StringName(str(data.get("division", "off")))
	_difficulty = StringName(str(data.get("difficulty", "normal")))
	_custom_min = int(data.get("custom_min", 1))
	_custom_max = int(data.get("custom_max", 15))


func _save_all() -> void:
	_save_config_to_disk()
	ResourceUtils.save_json(UI_SAVE_PATH, {
		"addition": String(_op_ids[&"addition"]),
		"subtraction": String(_op_ids[&"subtraction"]),
		"multiplication": String(_op_ids[&"multiplication"]),
		"division": String(_op_ids[&"division"]),
		"difficulty": String(_difficulty),
		"custom_min": _custom_min,
		"custom_max": _custom_max,
	})
