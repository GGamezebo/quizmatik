extends Control

@export var pdata: PData
@export var progress: ProgressController
@export var levels_config: LevelsConfig
@export var stats_list: VBoxContainer
@export var trophies_list: HBoxContainer
@export var stat_row_scene: PackedScene
@export var trophy_slot_scene: PackedScene
## Magister award (last shelf slot) — survived the magister trial.
@export var magister_trophy: Texture2D
@export var magister_name: String = "Магистр"
## Garland bulbs: lit once everything here is unlocked (`ProgressController.is_hall_complete`).
@export var hall_lamps: HallLamps
## Rules shown when the not-yet-earned magister cup is tapped.
@export var magister_rules: MagisterRulesOverlay
@export var hard_facts_label: Label
@export var hard_facts_empty_text: String = ""
@export var hard_facts_button: BaseButton
@export var hard_facts_overlay: HardFactsOverlay
@export_group("Endless record scroll")
## Open scroll with the best endless time — once `ProgressController.is_endless_unlocked`.
@export var record_open_nodes: Array[Control] = []
## Rolled-up sealed scroll + hint while the endless battle is locked.
@export var record_closed_nodes: Array[Control] = []
@export var record_value: Label
@export var record_hint: Label
@export var record_hint_text: String = "Бесконечный полёт"
@export var record_empty_hint: String = "Нажми часы в меню и лети!"

const HARD_FACTS_SHOWN: int = 3


func _ready() -> void:
	if hard_facts_button != null:
		hard_facts_button.pressed.connect(_on_hard_facts_pressed)
	if hard_facts_overlay != null:
		hard_facts_overlay.ev_closed.connect(_on_hard_facts_closed)


func on_window_enter() -> void:
	if progress != null:
		progress.sync_all_trophies_from_exams()
	_rebuild_trophies()
	_rebuild_stats()
	_rebuild_record()
	_rebuild_hard_facts()
	if hall_lamps != null:
		hall_lamps.set_lit(progress != null and progress.is_hall_complete())


func _live_pdata() -> PData:
	if progress != null and progress.pdata != null:
		return progress.pdata
	return pdata


func _rebuild_trophies() -> void:
	if trophies_list == null or trophy_slot_scene == null:
		return

	for child in trophies_list.get_children():
		trophies_list.remove_child(child)
		child.free()

	for container_id in ValleyTrophyArt.get_container_ids():
		var is_unlocked := false
		if progress != null:
			is_unlocked = progress.is_trophy_unlocked(container_id)
		else:
			is_unlocked = _is_exam_completed_fallback(container_id)
		var slot: TrophySlot = trophy_slot_scene.instantiate() as TrophySlot
		slot.initialize(
			container_id,
			is_unlocked,
			_count_completed_levels(container_id),
			_total_levels(container_id),
		)
		trophies_list.add_child(slot)
	# Magister cup: hidden until every valley trophy is on the shelf; pulses with rules on tap until earned.
	if magister_trophy != null and progress != null and progress.are_all_valley_trophies_unlocked():
		var earned: bool = progress.is_magister()
		var magister_slot: TrophySlot = trophy_slot_scene.instantiate() as TrophySlot
		magister_slot.initialize_award(magister_name, magister_trophy, earned, not earned and magister_rules != null)
		magister_slot.ev_hint_pressed.connect(_on_magister_hint_pressed)
		trophies_list.add_child(magister_slot)


func _is_exam_completed_fallback(container_id: String) -> bool:
	var live := _live_pdata()
	if live == null:
		return false
	var container: PData.ContainerProgress = live.levels.containers.get(container_id)
	if container != null and container.exam_passed:
		return true
	if container != null and container.completed_levels.has(17):
		return container.completed_levels[17].stars >= 1
	return false


func _rebuild_stats() -> void:
	var live := _live_pdata()
	if live == null or stats_list == null or stat_row_scene == null:
		return

	for child in stats_list.get_children():
		stats_list.remove_child(child)
		child.free()

	var stats: Dictionary = live.statistics.to_dict()
	for row_data in ProgressStatistics.DISPLAY_ROWS:
		var key: String = row_data[0]
		var title: String = row_data[1]
		var row: Control = stat_row_scene.instantiate()
		row.initialize(
			key,
			title,
			ProgressStatistics.format_stat_value(key, stats.get(key, 0), stats),
		)
		stats_list.add_child(row)


func _rebuild_record() -> void:
	var unlocked: bool = progress != null and progress.is_endless_unlocked()
	for node in record_open_nodes:
		node.visible = unlocked
	for node in record_closed_nodes:
		node.visible = not unlocked
	if not unlocked or record_value == null:
		return
	var live := _live_pdata()
	var best: int = live.statistics.endless_best_sec if live != null else 0
	record_value.text = ProgressStatistics.format_clock(best) if best > 0 else "—"
	if record_hint:
		record_hint.text = record_hint_text if best > 0 else record_empty_hint


func _rebuild_hard_facts() -> void:
	var live := _live_pdata()
	if live == null or hard_facts_label == null:
		return
	var parts: PackedStringArray = []
	for fact_key in live.mistakes.top_keys(HARD_FACTS_SHOWN):
		parts.append(MathFact.display(fact_key))
	hard_facts_label.text = "    ".join(parts) if not parts.is_empty() else hard_facts_empty_text
	if hard_facts_button != null:
		hard_facts_button.disabled = parts.is_empty()


func _on_hard_facts_pressed() -> void:
	var live := _live_pdata()
	if live == null or hard_facts_overlay == null:
		return
	var rows: Array = []
	for fact_key in live.mistakes.top_keys(MistakesController.MAX_FACTS):
		rows.append({
			"text": MathFact.display_with_answer(fact_key),
			"misses": live.mistakes.misses.get(fact_key, 1),
		})
	hard_facts_overlay.open(rows)


func _on_magister_hint_pressed() -> void:
	magister_rules.open(false)


func _on_hard_facts_closed() -> void:
	if hard_facts_button != null and is_visible_in_tree():
		hard_facts_button.grab_focus()


func _count_completed_levels(container_id: String) -> int:
	if levels_config == null:
		return 0
	var container_config: Dictionary = levels_config.find_container_in_config(container_id)
	if container_config.is_empty():
		return 0

	var completed: Dictionary = {}
	var live := _live_pdata()
	if live != null and live.levels.containers.has(container_id):
		completed = live.levels.containers[container_id].completed_levels

	var count := 0
	for level in container_config["levels"]:
		var level_id: int = level["level_id"]
		if completed.has(level_id) and completed[level_id].stars >= 1:
			count += 1
	return count


func _total_levels(container_id: String) -> int:
	if levels_config == null:
		return 0
	var container_config: Dictionary = levels_config.find_container_in_config(container_id)
	var levels_list: Variant = container_config.get("levels", [])
	if levels_list is Array:
		return levels_list.size()
	return 0
