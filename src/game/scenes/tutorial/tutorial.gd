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

const CHAPTER_FIRST_FLIGHT := "first_flight"
const CHAPTER_DAILY_STAMP := "daily_stamp"
const CHAPTER_PLANE_SHOP := "plane_shop"
const CHAPTERS: Array[String] = [CHAPTER_FIRST_FLIGHT, CHAPTER_DAILY_STAMP, CHAPTER_PLANE_SHOP]

@export var root_events: RootEvents
@export var progress: ProgressController
@export var menu_pointer: AnchorPointer
@export var battle_coach: BattleCoach
@export var battle_tips: BattleTips

@export_group("Chapter steps")
@export var first_flight_steps: Array[AnchorPointerStep] = []
@export var daily_stamp_steps: Array[AnchorPointerStep] = []
@export var plane_shop_steps: Array[AnchorPointerStep] = []

var _listener: EventListener = EventListener.new()
var _chapter: String = ""
var _in_menu: bool = true
var _finished: bool = false


func _ready() -> void:
	battle_coach.ev_goal_reached.connect(_on_goal_reached)
	battle_coach.ev_finished.connect(_refresh)
	battle_tips.ev_tip_shown.connect(progress.complete_tutorial_step)
	menu_pointer.ev_step_confirmed.connect(_on_step_confirmed)
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
		"ev.start_game", "ev.exit_game":
			_in_menu = false
	_refresh()


func _refresh() -> void:
	if _finished:
		return
	var chapter := _pending_chapter()
	var tips := _pending_tips()
	if chapter.is_empty() and tips.is_empty():
		_finish_tutorial()
		return
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
	if progress.is_tutorial_completed():
		return ""
	for chapter in CHAPTERS:
		if not progress.is_tutorial_step_done(chapter):
			return chapter
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
	return first_flight_steps


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
	if _chapter == CHAPTER_DAILY_STAMP:
		_complete_chapter(CHAPTER_DAILY_STAMP)


func _on_celebration(kind: String, _payload: Dictionary) -> void:
	if kind == CelebrationSplash.KIND_PLANE and _chapter == CHAPTER_PLANE_SHOP:
		_complete_chapter(CHAPTER_PLANE_SHOP)
