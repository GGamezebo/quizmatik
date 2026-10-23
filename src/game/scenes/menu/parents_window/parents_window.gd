extends Control

## «Для родителей»: the active pilot's report behind a parental gate — examples solved, first-try accuracy,
## time, exams, valley progress, weak examples — plus the store offer (`PurchaseOfferButton` placement
## `parents`: Monetization skips its own gate for it). Opened from Settings via the window stack; the gate
## runs on every entry, content stays hidden until it is passed.

@export var pdata: PData
@export var progress: ProgressController
@export var levels_config: LevelsConfig
@export var offer_board: OfferBoard
@export var windows_stack_manager: WindowStackManager
@export var parental_gate: ParentalGate
## Everything behind the gate (frame, report, offer, back).
@export var content: Control
@export var pilot_label: Label
@export_group("Stats")
@export var solved_tile: ParentsStatTile
@export var accuracy_tile: ParentsStatTile
@export var time_tile: ParentsStatTile
@export var exams_tile: ParentsStatTile
@export_group("Valleys")
@export var valley_rows: VBoxContainer
@export var valley_row_scene: PackedScene
@export_group("Weak examples")
@export var fact_rows: VBoxContainer
@export var fact_row_scene: PackedScene
@export var facts_hint: Label
@export var facts_empty: Label

const FACTS_SHOWN: int = 5
## Profile difficulty → grade line (same captions as `DifficultyPicker`).
const GRADE_TEXTS: Dictionary = {
	BattleDifficulty.EASY: "1 класс",
	BattleDifficulty.NORMAL: "2–3 класс",
	BattleDifficulty.HARD: "3–4 класс",
}


func _ready() -> void:
	parental_gate.ev_passed.connect(_on_gate_passed)
	parental_gate.ev_canceled.connect(_on_gate_canceled)
	content.hide()


func on_window_enter() -> void:
	content.hide()
	parental_gate.open()


func on_window_exit() -> void:
	parental_gate.close()
	content.hide()


func _on_gate_passed() -> void:
	_rebuild()
	content.show()


func _on_gate_canceled() -> void:
	if windows_stack_manager != null:
		windows_stack_manager.close_stacked_window()


func _live_pdata() -> PData:
	if progress != null and progress.pdata != null:
		return progress.pdata
	return pdata


func _rebuild() -> void:
	var live := _live_pdata()
	var difficulty := BattleDifficulty.sanitize(StringName(live.difficulty))
	pilot_label.text = "%s · %s" % [
		ProfileController.display_name_or_default(live.display_name), tr(GRADE_TEXTS[difficulty])]
	_rebuild_stats(live)
	_rebuild_valleys(difficulty)
	_rebuild_facts(live)


func _rebuild_stats(live: PData) -> void:
	var stats := live.statistics
	solved_tile.set_value(str(stats.total_answers))
	var answered := stats.facts_correct + stats.facts_wrong
	accuracy_tile.set_value("%d%%" % roundi(100.0 * stats.facts_correct / answered) if answered > 0 else "—")
	time_tile.set_value(_format_hours_minutes(stats.battle_total_time))
	var exams := progress.passed_valley_exams_count() if progress != null else 0
	exams_tile.set_value(tr("%d из %d") % [exams, levels_config.levels.get("containers", []).size()])


func _rebuild_valleys(difficulty: StringName) -> void:
	for child in valley_rows.get_children():
		valley_rows.remove_child(child)
		child.free()
	for container_data in levels_config.levels.get("containers", []):
		var container_id := String(container_data.get("container_id", ""))
		var row: ParentsValleyRow = valley_row_scene.instantiate()
		valley_rows.add_child(row)
		var exam_stars := 0
		var exam_id := levels_config.get_exam_level_id(container_id)
		if progress != null and exam_id > 0:
			exam_stars = progress.get_level_stars(container_id, exam_id)
		row.setup(
			container_id,
			String(container_data.get("name", container_id)),
			progress.completed_levels_count(container_id) if progress != null else 0,
			(container_data.get("levels", []) as Array).size(),
			exam_stars,
			offer_board != null and offer_board.is_container_paywalled(container_id, difficulty),
		)


func _rebuild_facts(live: PData) -> void:
	for child in fact_rows.get_children():
		fact_rows.remove_child(child)
		child.free()
	var keys := live.mistakes.top_keys(FACTS_SHOWN)
	for index in keys.size():
		var row: Control = fact_row_scene.instantiate()
		row.initialize(index + 1, MathFact.display_with_answer(keys[index]), live.mistakes.misses.get(keys[index], 1))
		fact_rows.add_child(row)
	facts_hint.visible = not keys.is_empty()
	facts_empty.visible = keys.is_empty()


## Whole minutes: «1 ч 05 мин» / «12 мин» (seconds mean nothing in a parent's report).
func _format_hours_minutes(seconds: float) -> String:
	var minutes: int = int(seconds / 60.0)
	@warning_ignore("integer_division")
	var hours: int = minutes / 60
	if hours > 0:
		return tr("%d ч %02d мин") % [hours, minutes % 60]
	return tr("%d мин") % minutes
