extends Control

## «Для родителей»: the active pilot's report behind a parental gate — examples solved, first-try accuracy,
## time, exams, valley progress, weak examples — plus the store offer (`PurchaseOfferButton` placement
## `parents`: Monetization skips its own gate for it) and store rating (`PlatformServices.can_rate`): button
## «Оценить игру» → store page; once per app session, when the pilot has real progress, the store's in-app
## review sheet a moment after the report shows (the parent holds the phone here, not the child).
## Opened from Settings via the window stack; the gate runs on every entry, content hidden until passed.

@export var pdata: PData
@export var progress: ProgressController
@export var levels_config: LevelsConfig
@export var offer_board: OfferBoard
@export var platform_services: PlatformServices
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
@export_group("Rating")
@export var rate_button: Button
## Ask the store's review sheet only after this much: an exam passed or this many problems solved.
@export var review_min_solved: int = 100
@export var review_delay_sec: float = 1.5

const FACTS_SHOWN: int = 5

var _listener: EventListener = EventListener.new()
## In-app review asked this app session (the store also keeps its own quota).
static var _review_asked: bool = false
## Profile difficulty → grade line (same captions as `DifficultyPicker`).
const GRADE_TEXTS: Dictionary = {
	BattleDifficulty.EASY: "1 класс",
	BattleDifficulty.NORMAL: "2–3 класс",
	BattleDifficulty.HARD: "3–4 класс",
}


func _ready() -> void:
	parental_gate.ev_passed.connect(_on_gate_passed)
	parental_gate.ev_canceled.connect(_on_gate_canceled)
	if offer_board != null:
		_listener.add(offer_board.ev_changed, _on_offers_changed)
	if platform_services != null:
		_listener.add(platform_services.ev_caps_changed, _refresh_rate_button)
	rate_button.pressed.connect(_on_rate_pressed)
	_refresh_rate_button()
	content.hide()


func _exit_tree() -> void:
	_listener.deinit()


func on_window_enter() -> void:
	content.hide()
	parental_gate.open()


func on_window_exit() -> void:
	parental_gate.close()
	content.hide()


func _on_gate_passed() -> void:
	_rebuild()
	content.show()
	_maybe_request_review()


## Bought here (or the store answered late) → paid tags off without leaving the report.
func _on_offers_changed() -> void:
	if content.visible:
		_rebuild()


func _refresh_rate_button() -> void:
	rate_button.visible = platform_services != null and platform_services.can_rate


func _on_rate_pressed() -> void:
	platform_services.ev_request_rate_page.emit()


func _maybe_request_review() -> void:
	if _review_asked or platform_services == null or not platform_services.can_rate:
		return
	var exams := progress.passed_valley_exams_count() if progress != null else 0
	if exams < 1 and _live_pdata().statistics.total_answers < review_min_solved:
		return
	_review_asked = true
	await get_tree().create_timer(review_delay_sec).timeout
	if content.visible and is_visible_in_tree():
		platform_services.ev_request_review.emit()
	else:
		_review_asked = false


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
