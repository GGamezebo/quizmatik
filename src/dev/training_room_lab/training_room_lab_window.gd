extends Control

## Editor-only snapshot of the full training room for development.
## Independent from `src/game/scenes/menu/training_room_window/` — safe to keep while redesigning practice.

const SAVE_PATH := "user://training_lab_settings.json"
const GRANT_GOLD := 1
## Bigger grant for testing cosmetics purchases.
const GRANT_GOLD_BIG := 10
## «Подсказки» id of the three in-battle tips (`BattleTips.TIPS`); other ids = tutorial flags.
const HINT_BATTLE_TIPS := "battle_tips"
## Must match `FlightModeCoach.level_id` in `tutorial.tscn`.
const FLIGHT_HINT_LEVEL := 4

@export var config: GameConfig
@export_group("Steppers")
@export var health_stepper: TrainingLabStepper
@export var questions_stepper: TrainingLabStepper
@export var min_number_stepper: TrainingLabStepper
@export var max_number_stepper: TrainingLabStepper
@export var answer_speed_stepper: TrainingLabStepper
@export var early_exam_questions_stepper: TrainingLabStepper
@export var early_exam_speed_stepper: TrainingLabStepper
@export var bonus_gold_chance_stepper: TrainingLabStepper
@export var time_limit_stepper: TrainingLabStepper
@export var boss_chance_stepper: TrainingLabStepper
@export var boss_armor_stepper: TrainingLabStepper
@export var boss_rage_stepper: TrainingLabStepper
@export var boss_royal_check: CheckBox
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
@export var wipe_progress_button: BaseButton
@export var wipe_dialog: ConfirmDialog
@export var grant_gold_button: BaseButton
@export var grant_gold_big_button: BaseButton
## One daily stamp. The card is under the lab, so the slam plays after it closes.
@export var grant_stamp_button: BaseButton
@export var unlock_valleys_button: BaseButton
@export var complete_valleys_button: BaseButton
## Wipes progress like «СБРОСИТЬ ПРОГРЕСС» but keeps the active pilot and its tutorial flags.
@export var wipe_keep_tutorial_button: BaseButton
## «Экзамен:» row — one button per valley (same order as `exam_container_ids`) passes that exam at once.
@export var exam_buttons: Array[BaseButton] = []
@export var exam_container_ids: Array[String] = []
## «Эксперт:» row — one button per valley (same order as `expert_container_ids`) passes that expert trial at once.
@export var expert_buttons: Array[BaseButton] = []
@export var expert_container_ids: Array[String] = []
@export var root_events: RootEvents
@export_group("Tutorial hints")
## «Подсказки» panel — one button per hint (same order as `hint_ids`; ids in `_on_hint_pressed`).
@export var hint_buttons: Array[BaseButton] = []
@export var hint_ids: Array[String] = []
## Look items: the shop tour needs gold for the cheapest one not owned.
@export var cosmetic_catalog: CosmeticCatalog
## The flight-mode hint needs free flight on.
@export var user_settings: UserSettings


var _wipe_keep_tutorial: bool = false

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
	_connect_stepper(bonus_gold_chance_stepper, "bonus_gold_chance", 0.05, 0.0, 1.0, 2)
	_connect_stepper(time_limit_stepper, "time_limit_sec", 15.0, 0.0, 300.0, 0)
	_connect_stepper(boss_chance_stepper, "boss_chance", 0.05, 0.0, 1.0, 2)
	_connect_stepper(boss_armor_stepper, "boss_armor", 1.0, 1.0, 12.0, 0)
	_connect_stepper(boss_rage_stepper, "boss_rage_hits", 1.0, 1.0, 60.0, 0)
	if boss_royal_check != null:
		boss_royal_check.toggled.connect(func(is_checked: bool) -> void: config.boss_royal = is_checked)

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
	if wipe_progress_button != null:
		wipe_progress_button.pressed.connect(_on_wipe_progress_pressed.bind(false))
	if wipe_dialog != null:
		wipe_dialog.ev_confirmed.connect(_on_wipe_progress_confirmed)
	if unlock_valleys_button != null:
		unlock_valleys_button.pressed.connect(_on_unlock_valleys_pressed)
	if complete_valleys_button != null:
		complete_valleys_button.pressed.connect(_on_complete_valleys_pressed)
	if wipe_keep_tutorial_button != null:
		wipe_keep_tutorial_button.pressed.connect(_on_wipe_progress_pressed.bind(true))
	for index in mini(exam_buttons.size(), exam_container_ids.size()):
		exam_buttons[index].pressed.connect(_on_exam_pressed.bind(exam_container_ids[index]))
	for index in mini(expert_buttons.size(), expert_container_ids.size()):
		expert_buttons[index].pressed.connect(_on_expert_pressed.bind(expert_container_ids[index]))
	for index in mini(hint_buttons.size(), hint_ids.size()):
		hint_buttons[index].pressed.connect(_on_hint_pressed.bind(hint_ids[index]))
	if grant_gold_button != null:
		grant_gold_button.pressed.connect(_on_grant_gold_pressed.bind(GRANT_GOLD))
	if grant_gold_big_button != null:
		grant_gold_big_button.pressed.connect(_on_grant_gold_pressed.bind(GRANT_GOLD_BIG))
	if grant_stamp_button != null:
		grant_stamp_button.pressed.connect(_on_grant_stamp_pressed)


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
	_set_stepper_value(bonus_gold_chance_stepper, config.bonus_gold_chance)
	_set_stepper_value(time_limit_stepper, config.time_limit_sec)
	_set_stepper_value(boss_chance_stepper, config.boss_chance)
	_set_stepper_value(boss_armor_stepper, config.boss_armor)
	_set_stepper_value(boss_rage_stepper, config.boss_rage_hits)
	if boss_royal_check != null:
		boss_royal_check.set_pressed_no_signal(config.boss_royal)

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


func _on_grant_gold_pressed(amount: int) -> void:
	var profiles := ProfileController.find_in_tree(get_tree())
	if profiles == null or not profiles.has_profiles():
		return
	profiles.add_gold(amount)
	_notify_progress_changed()


## One daily win-slot. Five presses open the golden flight; the slam plays when the lab closes.
func _on_grant_stamp_pressed() -> void:
	var daily := DailyChallengesController.find_in_tree(get_tree())
	if daily == null:
		return
	daily.register_win()
	_notify_progress_changed()


func _on_unlock_valleys_pressed() -> void:
	var progress := ProgressController.find_in_tree(get_tree())
	if progress == null:
		return
	progress.unlock_all_containers()
	_notify_progress_changed()


func _on_complete_valleys_pressed() -> void:
	var progress := ProgressController.find_in_tree(get_tree())
	if progress == null:
		return
	progress.complete_all_containers()
	_notify_progress_changed()


## Marks the exam of `container_id` passed at once (3 stars, like a won exam: trophy, plane, next valley).
func _on_exam_pressed(container_id: String) -> void:
	var progress := ProgressController.find_in_tree(get_tree())
	if progress == null:
		return
	progress.pass_exam(container_id, 3)
	_notify_progress_changed()


## Marks the expert trial of `container_id` survived at once (valley opened, exam passed first if needed;
## trophy and badges, no gold / celebration).
func _on_expert_pressed(container_id: String) -> void:
	var progress := ProgressController.find_in_tree(get_tree())
	if progress == null:
		return
	progress.complete_expert(container_id)
	_notify_progress_changed()


## Shows tutorial hint `hint_id` again: forgets it was shown and makes its trigger true at once
## (a daily stamp, gold, a weak example, passed exams / experts). Close the lab to see it.
func _on_hint_pressed(hint_id: String) -> void:
	var progress := ProgressController.find_in_tree(get_tree())
	var profiles := ProfileController.find_in_tree(get_tree())
	if progress == null or profiles == null or not profiles.has_profiles():
		return
	var pdata := progress.pdata
	match hint_id:
		TutorialContext.CHAPTER_DAILY_STAMP:
			_replay_base_hints(progress, [hint_id])
			var daily := DailyChallengesController.find_in_tree(get_tree())
			if daily != null and daily.get_completed_count() == 0:
				daily.register_win()
		TutorialContext.CHAPTER_PLANE_SHOP:
			_replay_base_hints(progress, [hint_id])
			_top_up_gold(profiles, pdata, _cheapest_locked_plane_cost(pdata))
		HINT_BATTLE_TIPS:
			_replay_base_hints(progress, BattleTips.TIPS)
		ProgressController.SHOP_TOUR_STEP:
			progress.reset_tutorial_steps([hint_id])
			progress.complete_tutorial_step(TutorialContext.SHOP_TOUR_ARMED)
			_top_up_gold(profiles, pdata, _cheapest_cosmetic_cost(pdata))
		ProgressController.MISTAKES_INTRO_STEP:
			progress.reset_tutorial_steps([hint_id])
			var mistakes := MistakesController.find_in_tree(get_tree())
			if mistakes != null and pdata.mistakes.weights.is_empty():
				mistakes.add_miss(MathFact.make_key(MathFact.FAMILY_MUL, 7, 8))
		ProgressController.ENDLESS_INTRO_STEP:
			progress.reset_tutorial_steps([hint_id, ProgressController.ENDLESS_RULES_STEP])
			for container_id in exam_container_ids:
				if progress.is_endless_unlocked():
					break
				if not progress.is_valley_exam_completed(container_id):
					progress.pass_exam(container_id, 3)
		ProgressController.EXPERT_INTRO_STEP:
			progress.reset_tutorial_steps([hint_id, ProgressController.EXPERT_RULES_STEP])
			if not progress.is_expert_intro_pending() and not exam_container_ids.is_empty():
				progress.pass_exam(exam_container_ids[0], 3)
		ProgressController.MAGISTER_RULES_STEP:
			progress.reset_tutorial_steps([hint_id])
			if not progress.is_magister_unlocked():
				for container_id in expert_container_ids:
					progress.complete_expert(container_id)
		ProgressController.FLIGHT_MODE_INTRO_STEP:
			progress.reset_tutorial_steps([hint_id])
			if user_settings != null and user_settings.movement_mode != AirPlane.MovementMode.DIRECT:
				user_settings.movement_mode = AirPlane.MovementMode.DIRECT
				user_settings.save()
			_open_first_valley_level(progress, FLIGHT_HINT_LEVEL)
		_:
			push_warning("Training lab: unknown hint id %s" % hint_id)
			return
	_notify_progress_changed()


## Base chapters and battle tips run only while the tutorial is open: reopen it with every other one
## marked done, so only `step_ids` show.
func _replay_base_hints(progress: ProgressController, step_ids: Array[String]) -> void:
	for step_id: String in TutorialContext.CHAPTERS + BattleTips.TIPS:
		progress.complete_tutorial_step(step_id)
	progress.reset_tutorial_steps(step_ids, true)


## Locked → every earlier level of the first valley gets one star.
func _open_first_valley_level(progress: ProgressController, level_id: int) -> void:
	if exam_container_ids.is_empty():
		return
	var container_id := exam_container_ids[0]
	if progress.is_level_unlocked(container_id, level_id):
		return
	for earlier_level in range(1, level_id):
		if progress.get_level_stars(container_id, earlier_level) < 1:
			progress.pass_level(container_id, earlier_level, 1)


func _top_up_gold(profiles: ProfileController, pdata: PData, cost: int) -> void:
	if cost > pdata.gold:
		profiles.add_gold(cost - pdata.gold)


## Cheapest plane the pilot doesn't own (0 = all owned).
func _cheapest_locked_plane_cost(pdata: PData) -> int:
	var best := 0
	for plane_id in PlaneCatalog.ORDER:
		var cost := int(PlaneCatalog.get_def(plane_id).get("gold_cost", 0))
		if cost > 0 and not pdata.unlocked_planes.has(plane_id) and (best == 0 or cost < best):
			best = cost
	return best


## Cheapest paid look item the pilot doesn't own (0 = none).
func _cheapest_cosmetic_cost(pdata: PData) -> int:
	var best := 0
	if cosmetic_catalog == null:
		return best
	for item in cosmetic_catalog.items:
		if item != null and item.gold_cost > 0 and not pdata.cosmetics.owned.has(item.id) and (best == 0 or item.gold_cost < best):
			best = item.gold_cost
	return best


## Lab edits bypass battles: the same signal a profile switch sends makes AppRoot / tutorial / menu
## re-check what is due (hints like the endless clock intro or the plane shop, menu entries).
func _notify_progress_changed() -> void:
	if root_events != null:
		root_events.ev_profiles_changed.emit()


func _on_wipe_progress_pressed(keep_tutorial: bool) -> void:
	_wipe_keep_tutorial = keep_tutorial
	if wipe_dialog == null:
		_on_wipe_progress_confirmed()
		return
	if keep_tutorial:
		wipe_dialog.open(
			"Сбросить без обучения?",
			"Прогресс, золото и другие пилоты удалятся. Текущий пилот и пройденное обучение останутся.",
			"Сбросить",
			"Отмена",
		)
		return
	wipe_dialog.open(
		"Сбросить всё?",
		"Все профили и прогресс будут удалены. Игра начнётся как в первый раз.",
		"Сбросить",
		"Отмена",
	)


func _on_wipe_progress_confirmed() -> void:
	_close_lab_window()
	var profiles := ProfileController.find_in_tree(get_tree())
	if profiles == null:
		return
	if _wipe_keep_tutorial:
		profiles.reset_progress_keep_tutorial()
	else:
		profiles.wipe_all_profiles()


func _close_lab_window() -> void:
	var host := get_parent()
	if host == null:
		return
	for child in host.get_children():
		if child is WindowStackManager:
			(child as WindowStackManager).close_stacked_window()
			return


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
