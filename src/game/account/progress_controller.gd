class_name ProgressController
extends Node

signal ev_container_seen(container_id: String)
signal ev_level_seen(container_id: String, level_id: int)

## Valley exams needed to open the endless battle.
const ENDLESS_UNLOCK_EXAMS := 4
## Tutorial chapter id of the endless-battle intro (shown in menu when the clock appears).
const ENDLESS_INTRO_STEP := "endless_intro"
## Tutorial chapter id of the one-time shop tour (after the plane chapter, gold for a look item).
const SHOP_TOUR_STEP := "shop_tour"
## Tutorial chapter id of the one-time weak-examples intro (hall of fame → hard facts board).
const MISTAKES_INTRO_STEP := "mistakes_intro"
## `PData.trophies` id of the magister award (survived the magister trial).
const MAGISTER_TROPHY := "magister"
## `PData.state.tutorial_steps` flag: the magister rules were read and the first trial started.
const MAGISTER_RULES_STEP := "magister_rules"
## `PData.state.tutorial_steps` flag: the endless rules were read and the first endless battle started.
const ENDLESS_RULES_STEP := "endless_rules"
## Award id of the opened endless record scroll in the hall of fame (`award_ids`).
const ENDLESS_AWARD := "endless_record"
## Tutorial chapter id of the coached first battle (= tutorial `CHAPTER_FIRST_FLIGHT`).
const FIRST_FLIGHT_STEP := "first_flight"
## HARD: first exam pass pays this per regular level that had no stars yet (levels skipped via the exam).
const HARD_SKIP_LEVEL_GOLD := 2

@export var pdata: PData
@export var levels_config: LevelsConfig
@export var conditions: Script
@export var root_events: RootEvents


static func find_in_tree(tree: SceneTree) -> ProgressController:
	if tree == null:
		return null
	return tree.root.find_child("ProgressController", true, false) as ProgressController


func save() -> void:
	root_events.ev_save_progress.emit()

## Whole tutorial done (pre-tutorial saves: set by SaveData v4 migration).
func is_tutorial_completed() -> bool:
	return pdata.state.tutorial_completed

func complete_tutorial() -> void:
	if pdata.state.tutorial_completed:
		return
	pdata.state.tutorial_completed = true
	save()

## Tutorial chapter flags; ids are owned by the tutorial context.
func is_tutorial_step_done(step_id: String) -> bool:
	return pdata.state.tutorial_steps.get(step_id, false)

func complete_tutorial_step(step_id: String) -> void:
	if is_tutorial_step_done(step_id):
		return
	pdata.state.tutorial_steps[step_id] = true
	save()

func get_last_container_id() -> String:
	return pdata.state.last_container_id

func set_last_container_id(container_id: String) -> void:
	if container_id.is_empty() or pdata.state.last_container_id == container_id:
		return
	pdata.state.last_container_id = container_id
	save()

func post_battle(battle_info: GameConfig.BattleInfo, stars: int) -> Dictionary:
	if battle_info.is_exam:
		return pass_exam(battle_info.container_id, stars)
	var level_gold := pass_level(battle_info.container_id, battle_info.level_id, stars)
	save()
	if level_gold > 0:
		return {"level_gold": level_gold}
	return {}

## HARD (grade 3-4) opens every valley while the profile stays on HARD (computed, never saved).
func is_container_unlocked(container_id: String) -> bool:
	if is_hard_difficulty() and not levels_config.find_container_in_config(container_id).is_empty():
		return true
	var progress := pdata.levels.containers.get(container_id) as PData.ContainerProgress
	if progress != null and progress.unlocked:
		return true
	var container_config = levels_config.find_container_in_config(container_id)
	if container_config:
		var unlock_condition = container_config["unlock_condition"]
		var condition_func_name = unlock_condition["name"]
		var condition_args = unlock_condition["args"]
		return conditions.call(condition_func_name, pdata, condition_args)
	return false

## Dev lab: open every valley without its unlock exam; levels inside stay sequential.
func unlock_all_containers() -> void:
	for container_data in levels_config.levels.get("containers", []):
		pdata.levels.ensure_container(str(container_data.get("container_id", ""))).unlocked = true
	save()

## Dev lab: every valley passed on max — all levels + exam with 3 stars (trophies, exam planes too).
func complete_all_containers() -> void:
	for container_data in levels_config.levels.get("containers", []):
		var container_id := str(container_data.get("container_id", ""))
		pdata.levels.ensure_container(container_id).unlocked = true
		pass_exam(container_id, 3)
	save()


## Valley exams passed (any stars), any valleys.
func passed_valley_exams_count() -> int:
	var count := 0
	for container_data in levels_config.levels.get("containers", []):
		if is_valley_exam_completed(str(container_data.get("container_id", ""))):
			count += 1
	return count

## Endless battle open (menu clock, trophy room record): `ENDLESS_UNLOCK_EXAMS` valley exams passed.
func is_endless_unlocked() -> bool:
	return passed_valley_exams_count() >= ENDLESS_UNLOCK_EXAMS

## Valley record battle (level grid clock): the valley has one (`LevelsConfig.get_record_operation`) and its exam is passed.
func is_valley_record_unlocked(container_id: String) -> bool:
	return levels_config.get_record_operation(container_id) != 0 and is_valley_exam_completed(container_id)

## Profile on EASY (grade 1): menu modes pick their `easy_*` config / rules card.
func is_easy_difficulty() -> bool:
	return pdata != null and BattleDifficulty.sanitize(StringName(pdata.difficulty)) == BattleDifficulty.EASY

## Profile on HARD (grade 3-4): all valleys open, exams first (`skip_gold_for`, `HardSkipOverlay`).
func is_hard_difficulty() -> bool:
	return pdata != null and BattleDifficulty.sanitize(StringName(pdata.difficulty)) == BattleDifficulty.HARD

## First flight coached (or whole tutorial done): menu offers may show.
func is_first_flight_done() -> bool:
	return is_tutorial_completed() or is_tutorial_step_done(FIRST_FLIGHT_STEP) or pdata.levels.has_any_stars()

## `tutorial_steps` flag: the player chose «Пройду по порядку» in this valley's exam offer.
static func hard_skip_declined_step(container_id: String) -> String:
	return "hard_skip_declined:" + container_id

## HARD only: gold for the regular levels a first exam pass would skip (no stars yet); else 0.
func skip_gold_for(container_id: String) -> int:
	if not is_hard_difficulty() or is_valley_exam_completed(container_id):
		return 0
	var container := pdata.levels.containers.get(container_id) as PData.ContainerProgress
	var skipped := 0
	for level in levels_config.find_container_in_config(container_id).get("levels", []):
		if level.get("is_exam", false):
			continue
		var level_id: int = level["level_id"]
		if container == null or not container.completed_levels.has(level_id) 				or container.completed_levels[level_id].stars < 1:
			skipped += 1
	return skipped * HARD_SKIP_LEVEL_GOLD

## Some weak example recorded (`PData.mistakes`) and its intro not shown yet.
func is_mistakes_intro_pending() -> bool:
	return not pdata.mistakes.weights.is_empty() and not is_tutorial_step_done(MISTAKES_INTRO_STEP)

## Shop tour not done yet (the tutorial context waits for it; it arms itself after a battle).
func is_shop_tour_pending() -> bool:
	return not is_tutorial_step_done(SHOP_TOUR_STEP)

## Endless open but its menu intro (tutorial chapter `ENDLESS_INTRO_STEP`) not shown yet.
func is_endless_intro_pending() -> bool:
	return is_endless_unlocked() and not is_tutorial_step_done(ENDLESS_INTRO_STEP)

## Every valley exam passed (menu magister cap → magister trial).
func are_all_valley_exams_passed() -> bool:
	var containers: Array = levels_config.levels.get("containers", [])
	return not containers.is_empty() and passed_valley_exams_count() >= containers.size()

## Every valley trophy on the shelf — the magister cup shows up (pulsing, rules on tap until earned).
func are_all_valley_trophies_unlocked() -> bool:
	var containers: Array = levels_config.levels.get("containers", [])
	if containers.is_empty():
		return false
	for container_data in containers:
		if not is_trophy_unlocked(str(container_data.get("container_id", ""))):
			return false
	return true

func is_magister() -> bool:
	return pdata.trophies.is_unlocked(MAGISTER_TROPHY)

## Magister trial survived; true only the first time (award + celebration).
func unlock_magister() -> bool:
	if not pdata.trophies.unlock(MAGISTER_TROPHY):
		return false
	save()
	return true

## Hall of fame complete: every valley trophy, the endless record scroll and the magister award (lamps on).
func is_hall_complete() -> bool:
	return is_endless_unlocked() and is_magister() and are_all_valley_trophies_unlocked()

## Hall-of-fame awards the player has: unlocked trophies (valleys, magister) + the endless record scroll.
func award_ids() -> Array[String]:
	sync_all_trophies_from_exams()
	var ids: Array[String] = []
	for trophy_id in pdata.trophies.unlocked:
		if pdata.trophies.unlocked[trophy_id]:
			ids.append(trophy_id)
	if is_endless_unlocked():
		ids.append(ENDLESS_AWARD)
	return ids

## Some award not shown in the trophy room yet → menu achievements button pulses.
func has_unseen_awards() -> bool:
	for award_id in award_ids():
		if not pdata.trophies.seen.get(award_id, false):
			return true
	return false

## Trophy room opened: every current award counts as seen.
func mark_awards_seen() -> void:
	var changed := false
	for award_id in award_ids():
		if not pdata.trophies.seen.get(award_id, false):
			pdata.trophies.seen[award_id] = true
			changed = true
	if changed:
		save()

func is_container_seen(container_id: String) -> bool:
	if not pdata.levels.containers.has(container_id):
		return false
	return pdata.levels.containers[container_id].seen

func mark_container_seen(container_id: String) -> bool:
	if is_container_seen(container_id):
		return false
	pdata.levels.ensure_container(container_id).seen = true
	print("[Progress] Container seen: %s" % container_id)
	ev_container_seen.emit(container_id)
	save()
	return true

func is_level_seen(container_id: String, level_id: int) -> bool:
	if not pdata.levels.containers.has(container_id):
		return false
	var completed: Dictionary = pdata.levels.containers[container_id].completed_levels
	if not completed.has(level_id):
		return false
	return completed[level_id].seen

func mark_level_seen(container_id: String, level_id: int) -> bool:
	if is_level_seen(container_id, level_id):
		return false
	pdata.levels.ensure_container(container_id).ensure_level(level_id).seen = true
	print("[Progress] Level seen: %s / %d" % [container_id, level_id])
	ev_level_seen.emit(container_id, level_id)
	save()
	return true

func is_level_unlocked(container_id: String, level_id: int) -> bool:
	if not is_container_unlocked(container_id):
		return false

	var container := pdata.levels.containers.get(container_id) as PData.ContainerProgress
	if container == null:
		container = PData.ContainerProgress.new()

	if container.exam_passed:
		return true

	if level_id == 1:
		return true

	if levels_config.is_level_exam(container_id, level_id):
		return true

	var prev_level_id := level_id - 1
	if container.completed_levels.has(prev_level_id):
		return container.completed_levels[prev_level_id].stars >= 1

	return false

func are_all_regular_levels_completed(container_id: String) -> bool:
	var container_config: Dictionary = levels_config.find_container_in_config(container_id)
	if container_config.is_empty():
		return false

	var container := pdata.levels.containers.get(container_id) as PData.ContainerProgress
	var completed: Dictionary = {}
	if container != null:
		completed = container.completed_levels
	for level in container_config["levels"]:
		if level.get("is_exam", false):
			continue
		var level_id: int = level["level_id"]
		if not completed.has(level_id) or completed[level_id].stars < 1:
			return false
	return true

## Levels of the valley (exam included) with at least one star (carousel «12 / 20», parents window).
func completed_levels_count(container_id: String) -> int:
	var count := 0
	for level in levels_config.find_container_in_config(container_id).get("levels", []):
		if get_level_stars(container_id, int(level["level_id"])) >= 1:
			count += 1
	return count

func get_level_stars(container_id: String, level_id: int) -> int:
	if not pdata.levels.containers.has(container_id):
		return 0
	var completed: Dictionary = pdata.levels.containers[container_id].completed_levels
	if not completed.has(level_id):
		return 0
	return completed[level_id].stars

const LEVEL_GOLD_FOR_THREE_STARS: int = 1

## Returns gold earned: first time a regular level reaches 3 stars. Caller grants it.
func pass_level(container_id: String, level_id: int, stars: int) -> int:
	var entry := pdata.levels.ensure_container(container_id).ensure_level(level_id)
	var first_three_stars: bool = entry.stars < 3 and stars >= 3
	entry.stars = max(entry.stars, stars)
	return LEVEL_GOLD_FOR_THREE_STARS if first_three_stars else 0

func is_valley_exam_completed(container_id: String) -> bool:
	if container_id.is_empty():
		return false
	var container: PData.ContainerProgress = pdata.levels.containers.get(container_id)
	if container != null and container.exam_passed:
		return true
	var exam_level_id: int = levels_config.get_exam_level_id(container_id)
	return exam_level_id > 0 and get_level_stars(container_id, exam_level_id) >= 1


func is_trophy_unlocked(container_id: String) -> bool:
	if is_valley_exam_completed(container_id):
		pdata.trophies.unlock(container_id)
	return pdata.trophies.is_unlocked(container_id)


func sync_all_trophies_from_exams() -> void:
	var changed := false
	var container_ids: Array[String] = []
	if levels_config != null and levels_config.levels.has("containers"):
		for container_data in levels_config.levels["containers"]:
			container_ids.append(str(container_data.get("container_id", "")))
	else:
		for container_id in pdata.levels.containers:
			container_ids.append(container_id)
	for container_id in container_ids:
		if is_valley_exam_completed(container_id) and pdata.trophies.unlock(container_id):
			changed = true
	if changed:
		save()


## First pass of a valley exam: coins on top of the trophy and the exam plane.
const EXAM_FIRST_PASS_GOLD: int = 5
## Exam plane already bought: this share of its price comes back instead (the purchase never feels wasted).
const PLANE_REFUND_SHARE: float = 0.5

func pass_exam(container_id: String, stars: int) -> Dictionary:
	# Before the exam stamps its stars on every level (they count as skipped only while empty).
	var skip_gold := skip_gold_for(container_id)
	# Celebrate the next valley only when this pass really opens it (HARD has them all open already).
	var next_id := levels_config.get_next_container_id(container_id)
	var opens_next := not next_id.is_empty() and not is_container_unlocked(next_id)
	var container := pdata.levels.ensure_container(container_id)
	var was_first_pass := not container.exam_passed
	container.exam_passed = true

	var config_levels = levels_config.find_container_in_config(container_id).get("levels", [])
	for config_level in config_levels:
		var level_id: int = config_level["level_id"]
		var entry := container.ensure_level(level_id)
		entry.stars = max(entry.stars, stars)

	if was_first_pass:
		pdata.trophies.unlock(container_id)

	var unlocked_plane_id := ""
	var plane_refund_gold := 0
	if was_first_pass:
		var plane_id := PlaneCatalog.plane_id_for_exam(container_id)
		if not plane_id.is_empty():
			var profiles := ProfileController.find_in_tree(get_tree())
			if profiles != null and profiles.unlock_plane(plane_id):
				unlocked_plane_id = plane_id
			elif profiles != null and profiles.is_plane_unlocked(plane_id):
				var cost := int(PlaneCatalog.get_def(plane_id).get("gold_cost", 0))
				plane_refund_gold = int(floor(cost * PLANE_REFUND_SHARE))

	save()

	if not was_first_pass:
		return {}

	var result := {
		"first_exam_pass": true,
		"container_id": container_id,
		"next_container_id": next_id if opens_next else "",
		# Next valley open already (HARD): AppRoot offers it only while the store sells it.
		"open_next_container_id": "" if opens_next else next_id,
		"all_exams_passed": are_all_valley_exams_passed(),
	}
	if not unlocked_plane_id.is_empty():
		result["unlocked_plane_id"] = unlocked_plane_id
	## Gold is granted by AppRoot (battle result), not here — the dev lab pass gives none.
	result["exam_gold"] = EXAM_FIRST_PASS_GOLD
	if plane_refund_gold > 0:
		result["plane_refund_gold"] = plane_refund_gold
	if skip_gold > 0:
		result["skip_gold"] = skip_gold
	return result
