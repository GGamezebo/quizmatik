extends Control

## Editor-only snapshot of the full training room for development.
## Independent from `src/game/scenes/menu/training_room_window/` — safe to keep while redesigning practice.

const SAVE_PATH := "user://training_lab_settings.json"

@export var config: GameConfig
@export_group("Steppers")
@export var health_stepper: TrainingLabStepper
@export var questions_stepper: TrainingLabStepper
@export var min_number_stepper: TrainingLabStepper
@export var max_number_stepper: TrainingLabStepper
@export var answer_speed_stepper: TrainingLabStepper
@export var early_exam_questions_stepper: TrainingLabStepper
@export var early_exam_speed_stepper: TrainingLabStepper
@export var stepper_template: PackedScene
@export_group("Operations")
@export var op_addition: CheckBox
@export var op_subtraction: CheckBox
@export var op_multiplication: CheckBox
@export var op_division: CheckBox
@export_group("Round coeffs")
@export var round_coeffs_box: VBoxContainer
@export var add_round_button: Button
@export_group("Actions")
@export var reset_button: BaseButton
@export var start_battle_button: BaseButton
@export var random_button: BaseButton


func _ready() -> void:
	_load_config_from_disk()
	_bind_controls()
	_sync_ui_from_config()


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
			else:
				push_error("Training lab settings corrupt, keeping scene defaults: %s" % SAVE_PATH)


func _bind_controls() -> void:
	_connect_stepper(health_stepper, "health", 1.0, 1.0, 20.0, 0)
	_connect_stepper(questions_stepper, "questions_count", 1.0, 1.0, 50.0, 0)
	_connect_stepper(min_number_stepper, "min_generate_number", 1.0, 1.0, 999.0, 0)
	_connect_stepper(max_number_stepper, "max_generate_number", 1.0, 1.0, 999.0, 0)
	_connect_stepper(answer_speed_stepper, "answer_speed", 1.0, 5.0, 300.0, 1)
	_connect_stepper(early_exam_questions_stepper, "early_exam_questions_multiplier", 0.1, 1.0, 5.0, 1)
	_connect_stepper(early_exam_speed_stepper, "early_exam_answer_speed_multiplier", 0.1, 1.0, 5.0, 1)

	_bind_operation_checkbox(op_addition, GameConfig.Operations.ADDITION)
	_bind_operation_checkbox(op_subtraction, GameConfig.Operations.SUBTRACTION)
	_bind_operation_checkbox(op_multiplication, GameConfig.Operations.MULTIPLICATION)
	_bind_operation_checkbox(op_division, GameConfig.Operations.DIVISION)

	if add_round_button != null:
		add_round_button.pressed.connect(_on_add_round_pressed)
	if reset_button != null:
		reset_button.pressed.connect(_on_reset_setting_pressed)
	if random_button != null:
		random_button.pressed.connect(_on_random_settings_pressed)


func _connect_stepper(
	stepper: TrainingLabStepper,
	prop_name: String,
	step: float,
	min_value: float,
	max_value: float,
	decimals: int
) -> void:
	if stepper == null:
		return
	stepper.step = step
	stepper.min_value = min_value
	stepper.max_value = max_value
	stepper.decimals = decimals
	stepper.value_changed.connect(func(value: float):
		if decimals == 0:
			config.set(prop_name, int(value))
		else:
			config.set(prop_name, value)
		_save_config_to_disk()
	)


func _bind_operation_checkbox(check_box: CheckBox, op_value: int) -> void:
	if check_box == null:
		return
	check_box.toggled.connect(func(is_checked: bool):
		var flags: int = config.allowed_operations
		if is_checked:
			flags |= op_value
		else:
			flags &= ~op_value
		config.allowed_operations = flags
		_save_config_to_disk()
	)


func _sync_ui_from_config() -> void:
	if config == null:
		return
	_set_stepper_value(health_stepper, config.health)
	_set_stepper_value(questions_stepper, config.questions_count)
	_set_stepper_value(min_number_stepper, config.min_generate_number)
	_set_stepper_value(max_number_stepper, config.max_generate_number)
	_set_stepper_value(answer_speed_stepper, config.answer_speed)
	_set_stepper_value(early_exam_questions_stepper, config.early_exam_questions_multiplier)
	_set_stepper_value(early_exam_speed_stepper, config.early_exam_answer_speed_multiplier)

	var flags: int = config.allowed_operations
	if op_addition != null:
		op_addition.button_pressed = (flags & GameConfig.Operations.ADDITION) != 0
	if op_subtraction != null:
		op_subtraction.button_pressed = (flags & GameConfig.Operations.SUBTRACTION) != 0
	if op_multiplication != null:
		op_multiplication.button_pressed = (flags & GameConfig.Operations.MULTIPLICATION) != 0
	if op_division != null:
		op_division.button_pressed = (flags & GameConfig.Operations.DIVISION) != 0

	_rebuild_round_coeff_rows()


func _set_stepper_value(stepper: TrainingLabStepper, value: float) -> void:
	if stepper != null:
		stepper.set_value(value)


func _rebuild_round_coeff_rows() -> void:
	if round_coeffs_box == null:
		return
	for child in round_coeffs_box.get_children():
		child.queue_free()

	var coeffs: Dictionary = config.answer_speed_round_coeffs
	var sorted_rounds: Array = coeffs.keys()
	sorted_rounds.sort()
	for round_key in sorted_rounds:
		_add_round_coeff_row(int(round_key), float(coeffs[round_key]))


func _on_add_round_pressed() -> void:
	var coeffs: Dictionary = config.answer_speed_round_coeffs.duplicate()
	var next_round: int = 1
	while coeffs.has(next_round):
		next_round += 1
	coeffs[next_round] = 1.0
	config.answer_speed_round_coeffs = coeffs
	_save_config_to_disk()
	_add_round_coeff_row(next_round, 1.0)


func _add_round_coeff_row(round_num: int, coeff: float) -> void:
	if round_coeffs_box == null or stepper_template == null:
		return

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var round_label := Label.new()
	round_label.text = "После раунда:"
	round_label.add_theme_font_size_override("font_size", 15)
	row.add_child(round_label)

	var round_stepper: TrainingLabStepper = stepper_template.instantiate() as TrainingLabStepper
	round_stepper.min_value = 1.0
	round_stepper.max_value = 99.0
	round_stepper.step = 1.0
	round_stepper.decimals = 0
	round_stepper.set_value(round_num)
	row.add_child(round_stepper)

	var coeff_label := Label.new()
	coeff_label.text = "Коэф.:"
	coeff_label.add_theme_font_size_override("font_size", 15)
	row.add_child(coeff_label)

	var coeff_stepper: TrainingLabStepper = stepper_template.instantiate() as TrainingLabStepper
	coeff_stepper.min_value = 0.1
	coeff_stepper.max_value = 5.0
	coeff_stepper.step = 0.1
	coeff_stepper.decimals = 1
	coeff_stepper.set_value(coeff)
	row.add_child(coeff_stepper)

	var remove_button := Button.new()
	remove_button.text = "×"
	remove_button.custom_minimum_size = Vector2(28, 34)
	remove_button.pressed.connect(func():
		row.queue_free()
		_sync_round_coeffs_from_ui.call_deferred()
	)
	row.add_child(remove_button)

	round_stepper.value_changed.connect(func(_v): _sync_round_coeffs_from_ui())
	coeff_stepper.value_changed.connect(func(_v): _sync_round_coeffs_from_ui())
	round_coeffs_box.add_child(row)


func _sync_round_coeffs_from_ui() -> void:
	if round_coeffs_box == null:
		return
	var new_dict: Dictionary = {}
	for row in round_coeffs_box.get_children():
		if not row is HBoxContainer or row.get_child_count() < 4:
			continue
		var round_stepper: TrainingLabStepper = row.get_child(1)
		var coeff_stepper: TrainingLabStepper = row.get_child(3)
		var round_num: int = int(round_stepper.get_value())
		if round_num > 0:
			new_dict[round_num] = coeff_stepper.get_value()
	config.answer_speed_round_coeffs = new_dict
	_save_config_to_disk()


func _save_config_to_disk() -> void:
	if config != null:
		ResourceUtils.save_json(SAVE_PATH, ResourceUtils.resource_to_dict(config))


func _on_reset_setting_pressed() -> void:
	ResourceUtils.update_resource(config, GameConfig.new())
	_save_config_to_disk()
	_sync_ui_from_config()


func _on_random_settings_pressed() -> void:
	config.health = randi_range(1, 5)
	config.questions_count = randi_range(3, 12)
	config.min_generate_number = randi_range(1, 9)
	config.max_generate_number = randi_range(config.min_generate_number, 20)
	config.answer_speed = randi_range(20, 120)
	config.allowed_operations = _random_operations_flags()
	config.early_exam_questions_multiplier = snapped(randf_range(1.0, 2.0), 0.1)
	config.early_exam_answer_speed_multiplier = snapped(randf_range(1.0, 2.0), 0.1)
	config.answer_speed_round_coeffs = {}
	_save_config_to_disk()
	_sync_ui_from_config()


func _random_operations_flags() -> int:
	var flags: int = 0
	for op in [
		GameConfig.Operations.ADDITION,
		GameConfig.Operations.SUBTRACTION,
		GameConfig.Operations.MULTIPLICATION,
		GameConfig.Operations.DIVISION,
	]:
		if randf() > 0.35:
			flags |= op
	if flags == 0:
		flags = GameConfig.Operations.ADDITION
	return flags
