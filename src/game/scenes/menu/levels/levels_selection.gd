extends Control

@export var root_events: RootEvents
@export var grid_container: GridContainer
@export var level_button: PackedScene
@export var levels: LevelsConfig
@export var container_id: String
@export var progress: ProgressController
@export var back_button: BaseButton
@export var early_exam_dialog: ConfirmDialog
@export var background_host: BackgroundHost
## Marks the next level tile for overlays (tutorial) — target set on each populate.
@export var next_level_anchor: UiAnchor
## Wrapper around the exam tile; pulses on HARD until the exam is passed.
@export var exam_slot_scene: PackedScene
## HARD: «you already know this — take the exam» offer on entering these valleys.
@export var hard_skip_overlay: HardSkipOverlay
@export var skip_offer_container_ids: Array[String] = ["addition", "subtraction"]
## Valley record clock left of the grid (shown once the valley exam is passed).
@export var record_entry: ValleyEndlessEntry
## Valley expert badge right of the grid, mirroring the clock (shown once the valley exam is passed).
@export var expert_entry: ExpertEntry

var _pending_battle_info: GameConfig.BattleInfo = null


func initialize(_container_id: String) -> void:
	container_id = _container_id
	_sync_local_background()
	_populate_levels_grid()
	if record_entry != null:
		record_entry.set_valley(container_id)
	if expert_entry != null:
		expert_entry.set_valley(container_id)
	_offer_hard_skip()


func _ready() -> void:
	early_exam_dialog.ev_confirmed.connect(_on_early_exam_confirmed)
	early_exam_dialog.ev_canceled.connect(_on_early_exam_canceled)
	if hard_skip_overlay:
		hard_skip_overlay.ev_exam_pressed.connect(_on_skip_exam_pressed)
		hard_skip_overlay.ev_in_order_pressed.connect(_on_skip_in_order_pressed)
	_sync_local_background()


func _sync_local_background() -> void:
	if background_host == null:
		return
	var shared := _shared_parent_background()
	var nested := shared != null
	background_host.visible = not nested
	background_host.process_mode = (
		Node.PROCESS_MODE_DISABLED if nested else Node.PROCESS_MODE_INHERIT
	)
	if nested:
		return
	var packed: PackedScene = ValleyBackgroundArt.get_scene(container_id)
	if packed == null:
		packed = ValleyBackgroundArt.pick_random_scene()
	background_host.force_variant(packed)


func _shared_parent_background() -> BackgroundHost:
	var parent := get_parent()
	if parent == null:
		return null
	for child in parent.get_children():
		if child is BackgroundHost and child != background_host:
			return child as BackgroundHost
	return null


func _populate_levels_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	var container = levels.find_container_in_config(container_id)
	var next_id := _find_next_level_id(container)
	var next_button: Control = null

	for level in container["levels"]:
		var lvl_id: int = level["level_id"]
		var is_exam: bool = level.get("is_exam", false)
		var btn = level_button.instantiate()
		btn.initialize(lvl_id, false, 0, is_exam)
		if is_exam and exam_slot_scene != null:
			var slot := exam_slot_scene.instantiate() as ExamSlot
			slot.hold(btn)
			grid_container.add_child(slot)
			slot.set_pulsing(progress.is_hard_difficulty() and not progress.is_valley_exam_completed(container_id))
		else:
			grid_container.add_child(btn)

		var is_unlocked: bool = progress.is_level_unlocked(container_id, lvl_id)
		var stars: int = progress.get_level_stars(container_id, lvl_id)
		btn.set_params(is_unlocked, stars)
		var level_config := level.get("config") as GameConfig
		btn.set_timed(level_config != null and level_config.is_timed())
		if btn.has_method("set_as_next"):
			btn.set_as_next(lvl_id == next_id and not is_exam)
		if lvl_id == next_id:
			next_button = btn
		if is_unlocked or is_exam:
			if is_unlocked:
				progress.mark_level_seen(container_id, lvl_id)
			var battle_info = GameConfig.BattleInfo.new(container_id, lvl_id, is_exam)
			btn.pressed.connect(_on_level_selected.bind(battle_info))

	if next_level_anchor != null:
		next_level_anchor.set_target(next_button)


func _find_next_level_id(container: Dictionary) -> int:
	if container.is_empty():
		return -1
	for level in container["levels"]:
		if level.get("is_exam", false):
			continue
		var lvl_id: int = level["level_id"]
		if progress.is_level_unlocked(container_id, lvl_id) and progress.get_level_stars(container_id, lvl_id) < 1:
			return lvl_id
	for level in container["levels"]:
		if level.get("is_exam", false):
			return int(level["level_id"])
	return -1


func _on_level_selected(battle_info: GameConfig.BattleInfo) -> void:
	# HARD: exams first by design — no «harder early exam» on top of the HARD pace.
	if battle_info.is_exam and not progress.is_hard_difficulty() 			and not progress.are_all_regular_levels_completed(battle_info.container_id):
		_pending_battle_info = battle_info
		early_exam_dialog.open(
			"Усложнённый экзамен",
			"Вы не прошли все уровни в этом блоке. Экзамен будет усложнённым.",
			"Начать",
			"Отмена",
		)
		return
	_start_game(battle_info)


func _on_early_exam_confirmed() -> void:
	if _pending_battle_info == null:
		return
	var battle_info := GameConfig.BattleInfo.new(
		_pending_battle_info.container_id,
		_pending_battle_info.level_id,
		true,
		true,
	)
	_pending_battle_info = null
	_start_game(battle_info)


func _on_early_exam_canceled() -> void:
	_pending_battle_info = null


func _start_game(battle_info: GameConfig.BattleInfo) -> void:
	root_events.ev_start_game.emit({
		"battle_info": battle_info
	})


func _offer_hard_skip() -> void:
	if hard_skip_overlay == null or progress == null or not progress.is_hard_difficulty():
		return
	if not container_id in skip_offer_container_ids or progress.is_valley_exam_completed(container_id):
		return
	if not progress.is_first_flight_done() 			or progress.is_tutorial_step_done(ProgressController.hard_skip_declined_step(container_id)):
		return
	hard_skip_overlay.open(progress.skip_gold_for(container_id) + ProgressController.EXAM_FIRST_PASS_GOLD)


func _on_skip_exam_pressed() -> void:
	var exam_id: int = levels.get_exam_level_id(container_id)
	if exam_id > 0:
		_start_game(GameConfig.BattleInfo.new(container_id, exam_id, true))


func _on_skip_in_order_pressed() -> void:
	progress.complete_tutorial_step(ProgressController.hard_skip_declined_step(container_id))
