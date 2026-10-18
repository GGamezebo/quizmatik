extends IScene

## First-run tutorial context — HFSM state `App/Tutorial` (parallel to Menu/Battle).
## Entered on `ev.open_tutorial` (AppRoot, while the active profile hasn't finished it); leaves itself via
## `ev.close_tutorial` once every chapter is done. Other scenes only mark UI with `UiAnchor`
## (`tutorial_anchors.tres`); chapter rules, texts and persistence live here.
##
## Chapters (in order, flags in `PData.state.tutorial_steps`):
## - first_flight: menu → valley → level 1 → coached first hit (`BattleCoach`)
## - daily_stamp: after the first daily stamp — explain 5 wins a day = a coin (confirm button)
## - plane_shop: first time a new plane is affordable — lead to profile → hangar → buy
## Battle tips (`BattleTips.TIPS`, same flags, after first_flight, any order): first `? + 3 = 7`,
## first boss, first angry boss. Tutorial closes only when chapters and tips are all done.
## Late chapter (not gated by `tutorial_completed`; AppRoot reopens the context for it):
## - endless_intro: menu clock appeared (`ProgressController.is_endless_intro_pending`) — explain the
##   record battle (confirm button or pressing the clock).
## - shop_tour: after plane_shop (or a finished tutorial), the first battle that ends with gold for a look
##   item arms it (`SHOP_TOUR_ARMED`); back in menu → shop button → tap through `shop_tour_steps`
##   (cards / slot chips, each advances on press; last = buy button, confirm or press). Buying optional.
##   While it waits to arm, the context stays open idle (AppRoot: `is_shop_tour_pending`).

const CHAPTER_FIRST_FLIGHT := "first_flight"
const CHAPTER_DAILY_STAMP := "daily_stamp"
const CHAPTER_PLANE_SHOP := "plane_shop"
const CHAPTERS: Array[String] = [CHAPTER_FIRST_FLIGHT, CHAPTER_DAILY_STAMP, CHAPTER_PLANE_SHOP]
const CHAPTER_ENDLESS_INTRO := ProgressController.ENDLESS_INTRO_STEP
const CHAPTER_SHOP_TOUR := ProgressController.SHOP_TOUR_STEP
const SHOP_TOUR_ARMED := "shop_tour_armed"

@export var root_events: RootEvents
@export var progress: ProgressController
@export var menu_pointer: AnchorPointer
@export var battle_coach: BattleCoach
@export var battle_tips: BattleTips

@export_group("Chapter steps")
@export var first_flight_steps: Array[AnchorPointerStep] = []
@export var daily_stamp_steps: Array[AnchorPointerStep] = []
@export var plane_shop_steps: Array[AnchorPointerStep] = []
@export var endless_intro_steps: Array[AnchorPointerStep] = []
## Main-menu shop button (shown while the hangar is closed).
@export var shop_entry_step: AnchorPointerStep
## Inside the shop, in order; one shown at a time.
@export var shop_tour_steps: Array[AnchorPointerStep] = []
## Look items for sale — arms the shop tour when one is affordable after a battle.
@export var cosmetic_catalog: CosmeticCatalog

var _listener: EventListener = EventListener.new()
var _chapter: String = ""
var _in_menu: bool = true
var _finished: bool = false
var _tour_index: int = 0


func _ready() -> void:
	battle_coach.ev_goal_reached.connect(_on_goal_reached)
	battle_coach.ev_finished.connect(_refresh)
	battle_tips.ev_tip_shown.connect(progress.complete_tutorial_step)
	menu_pointer.ev_step_confirmed.connect(_on_step_confirmed)
	menu_pointer.ev_target_pressed.connect(_on_target_pressed)
	super._ready()


func initialize(_data: Dictionary) -> void:
	_listener.add(root_events.ev_profiles_changed, _refresh)
	_listener.add(root_events.ev_show_celebration, _on_celebration)
	_refresh()


func deinit() -> void:
	_listener.deinit()
	menu_pointer.set_enabled(false)
	battle_coach.arm(false)
	battle_tips.stop()
	super.deinit()


func on_event(event_name: String, _data: Dictionary) -> void:
	match event_name:
		"ev.open_menu":
			_in_menu = true
		"ev.start_game":
			## Only the clock is clickable under the endless hint → pressing it = got it.
			if _chapter == CHAPTER_ENDLESS_INTRO and menu_pointer.current_step() != null:
				progress.complete_tutorial_step(CHAPTER_ENDLESS_INTRO)
			_in_menu = false
		"ev.exit_game":
			_in_menu = false
			_maybe_arm_shop_tour()
	_refresh()


func _refresh() -> void:
	if _finished:
		return
	var chapter := _pending_chapter()
	var tips := _pending_tips()
	if chapter.is_empty() and tips.is_empty():
		if not progress.is_shop_tour_pending():
			_finish_tutorial()
			return
		## Only the shop tour is left and it isn't armed yet — stay open, show nothing.
		progress.complete_tutorial()
	_chapter = chapter
	battle_coach.arm(chapter == CHAPTER_FIRST_FLIGHT)
	battle_tips.set_pending(tips)
	if chapter.is_empty():
		menu_pointer.set_enabled(false)
		return
	var steps: Array[AnchorPointerStep] = []
	if _is_chapter_ready(chapter):
		steps = _steps_for(chapter)
	if menu_pointer.steps != steps:
		menu_pointer.set_steps(steps)
	menu_pointer.set_enabled(_in_menu and not steps.is_empty())


func _pending_chapter() -> String:
	if not progress.is_tutorial_completed():
		for chapter in CHAPTERS:
			if not progress.is_tutorial_step_done(chapter):
				return chapter
	if progress.is_endless_intro_pending():
		return CHAPTER_ENDLESS_INTRO
	if progress.is_shop_tour_pending() and progress.is_tutorial_step_done(SHOP_TOUR_ARMED):
		return CHAPTER_SHOP_TOUR
	return ""


## Unseen battle tips — only after the coached first flight.
func _pending_tips() -> Array[String]:
	var tips: Array[String] = []
	if progress.is_tutorial_completed() or not progress.is_tutorial_step_done(CHAPTER_FIRST_FLIGHT):
		return tips
	for tip_id in BattleTips.TIPS:
		if not progress.is_tutorial_step_done(tip_id):
			tips.append(tip_id)
	return tips


func _is_chapter_ready(chapter: String) -> bool:
	match chapter:
		CHAPTER_DAILY_STAMP:
			return progress.pdata.daily.completed_count() > 0
		CHAPTER_PLANE_SHOP:
			return _can_buy_new_plane()
	return true


func _steps_for(chapter: String) -> Array[AnchorPointerStep]:
	match chapter:
		CHAPTER_DAILY_STAMP:
			return daily_stamp_steps
		CHAPTER_PLANE_SHOP:
			return plane_shop_steps
		CHAPTER_ENDLESS_INTRO:
			return endless_intro_steps
		CHAPTER_SHOP_TOUR:
			return _shop_tour_current_steps()
	return first_flight_steps


## Current tour step first (deeper screen), shop button as the way back in.
func _shop_tour_current_steps() -> Array[AnchorPointerStep]:
	var steps: Array[AnchorPointerStep] = []
	if _tour_index < shop_tour_steps.size():
		steps.append(shop_tour_steps[_tour_index])
	if shop_entry_step != null:
		steps.append(shop_entry_step)
	return steps


## Battle just ended (reward already applied): after the plane chapter, gold for a look item → arm.
func _maybe_arm_shop_tour() -> void:
	if not progress.is_shop_tour_pending() or progress.is_tutorial_step_done(SHOP_TOUR_ARMED):
		return
	if not (progress.is_tutorial_completed() or progress.is_tutorial_step_done(CHAPTER_PLANE_SHOP)):
		return
	var pdata := progress.pdata
	if cosmetic_catalog != null and cosmetic_catalog.has_affordable(pdata.gold, pdata.cosmetics.owned):
		progress.complete_tutorial_step(SHOP_TOUR_ARMED)


func _can_buy_new_plane() -> bool:
	var pdata := progress.pdata
	for plane_id in PlaneCatalog.ORDER:
		var cost := int(PlaneCatalog.get_def(plane_id).get("gold_cost", 0))
		if cost > 0 and cost <= pdata.gold and not pdata.unlocked_planes.has(plane_id):
			return true
	return false


func _complete_chapter(chapter: String) -> void:
	progress.complete_tutorial_step(chapter)
	_refresh()


func _finish_tutorial() -> void:
	_finished = true
	menu_pointer.set_enabled(false)
	battle_coach.arm(false)
	battle_tips.stop()
	progress.complete_tutorial()
	add_event("ev.close_tutorial")


func _on_goal_reached() -> void:
	## Persist right away; UI moves on after the praise (`ev_finished` → `_refresh`).
	progress.complete_tutorial_step(CHAPTER_FIRST_FLIGHT)


func _on_step_confirmed(_step: AnchorPointerStep) -> void:
	if _chapter in [CHAPTER_DAILY_STAMP, CHAPTER_ENDLESS_INTRO, CHAPTER_SHOP_TOUR]:
		_complete_chapter(_chapter)


func _on_target_pressed(step: AnchorPointerStep) -> void:
	if _chapter != CHAPTER_SHOP_TOUR or _tour_index >= shop_tour_steps.size():
		return
	if step != shop_tour_steps[_tour_index]:
		return
	## Deferred: the pressed button is still emitting; the page reacts to the press first.
	_advance_shop_tour.call_deferred()


func _advance_shop_tour() -> void:
	_tour_index += 1
	if _tour_index >= shop_tour_steps.size():
		_complete_chapter(CHAPTER_SHOP_TOUR)
	else:
		_refresh()


func _on_celebration(kind: String, _payload: Dictionary) -> void:
	if kind == CelebrationSplash.KIND_PLANE and _chapter == CHAPTER_PLANE_SHOP:
		_complete_chapter(CHAPTER_PLANE_SHOP)
