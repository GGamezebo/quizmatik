class_name DailyChallengesPanel
extends Control

## Daily streak card for the main menu: today's 5 stamps and the 5-set cycle strip in the header.
## New stamps since the card was last shown slam in (sound / vibration via `RootEvents`). 5/5 → the stamps
## glow and melt, «ЗОЛОТОЙ ПОЛЁТ» takes their place and the whole scroll breathes = one big button
## (the cycle's 5th set = the long flight). Battle = `GoldenFlightScenario`.
## After that flight, stamps lift off (reverse slam), a cycle pip pops, a short congrats shows,
## then the empty outlines return — and another set can start. The 5th pip clears the whole strip.
## New stamps and that reset wait while the card is hidden (menu remounted straight into the level grid):
## they play only when the main menu window shows again.

@export var daily_controller: DailyChallengesController
@export var slots_row: HBoxContainer
@export var slot_scene: PackedScene
@export var title_label: Label
## Filled ink stamps assigned by slot index (cycles if fewer than slot count).
@export var stamp_filled_variants: Array[Texture2D] = []
@export var slot_size_max: float = 84.0
@export var slot_size_min: float = 64.0
## Scroll art is 660 wide. The stamp row stays this far in from each side, clear of the rolls.
const SCROLL_ART_WIDTH := 660.0
const PARCHMENT_INSET := 98.0
@export var stamp_step_sec: float = 0.35
@export_group("Streak")
## Cycle sets before the goal (the goal icon = the long flight).
@export var cycle_pips: Array[Panel] = []
@export var cycle_goal: Control
@export var pip_empty: StyleBox
@export var pip_filled: StyleBox
@export_group("Golden flight")
@export var root_events: RootEvents
@export var progress: ProgressController
@export var golden_flight_config: GameConfig
@export var golden_state: Control
@export var golden_title: Label
@export var golden_subtitle: Label
## Covers the whole scroll; shown only while today's flight waits.
@export var scroll_button: BaseButton
@export var flight_sec: float = 60.0
@export var big_flight_sec: float = 120.0
@export var pulse_scale: float = 1.035
## Gap between stamps lifting off after a finished flight.
@export var lift_step_sec: float = 0.22
## How long the «Молодец!» line stays before the empty outlines return.
@export var congrats_hold_sec: float = 1.15

## Stamps on the card when it was last shown (session-wide: survives menu remounts); -1 = never.
static var _seen_completed: int = -1

var _slots: Array[DailySlot] = []
var _event_listener = EventListener.new()
var _pulse_tween: Tween
## Series animation running: refreshes (language switch, signals) must not cut it.
var _celebrating: bool = false
## First frame after mount: the menu may still open the level grid over this window (deferred).
var _mounting: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_event_listener.add(resized, _on_resized)
	_build_slots()
	if daily_controller != null:
		_event_listener.add(daily_controller.ev_daily_changed, refresh)
	if scroll_button != null:
		_event_listener.add(scroll_button.pressed, _on_flight_pressed)
	_event_listener.add(visibility_changed, _on_visibility_changed)
	refresh()
	call_deferred("_fit_slot_sizes")
	# Next frame, after the menu's deferred level-grid open (`menu.gd` `_open_level_select`).
	get_tree().process_frame.connect(_on_first_frame, CONNECT_ONE_SHOT)


func _on_first_frame() -> void:
	call_deferred("_on_mounted")


func _on_mounted() -> void:
	_mounting = false
	refresh()


func refresh() -> void:
	if _celebrating:
		return
	var reveal: int = daily_controller.get_pending_set_reveal()
	if reveal >= 0:
		_seen_completed = 0
		_present_set_reset(reveal)
		return
	var filled: Array = daily_controller.get_slots()
	for index in range(_slots.size()):
		var is_filled: bool = index < filled.size() and bool(filled[index])
		_slots[index].set_filled(is_filled)
	_refresh_streak()
	_fit_slot_sizes()
	var completed: int = daily_controller.get_completed_count()
	var animate_from: int = _seen_completed if _seen_completed >= 0 and completed > _seen_completed else completed
	if animate_from < completed and (_mounting or not is_visible_in_tree()):
		_hold_new_stamps(animate_from, completed)
		return
	_seen_completed = completed
	var can_fly: bool = daily_controller.can_start_bonus_flight() and golden_flight_config != null
	if animate_from < completed:
		_play_new_stamps(animate_from, completed, can_fly)
	else:
		_show_state(can_fly)


## Not seen yet: keep the new stamps off the paper until the card is on screen.
func _hold_new_stamps(from: int, to: int) -> void:
	_show_state(false)
	for index in range(from, mini(to, _slots.size())):
		_slots[index].set_shown(false)


func _on_visibility_changed() -> void:
	if is_visible_in_tree() and not _mounting:
		refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh()


func _exit_tree() -> void:
	_event_listener.deinit()


func _refresh_streak() -> void:
	var cycle_filled: int = daily_controller.get_cycle_filled()
	# 4 pips filled → the coin (5th mark) is the long flight waiting ahead.
	_apply_cycle(cycle_filled, cycle_filled >= DailyChallengesController.STREAK_CYCLE - 1)
	if golden_subtitle:
		var big: bool = daily_controller.is_big_flight_today()
		var minutes: int = maxi(1, roundi((big_flight_sec if big else flight_sec) / 60.0))
		var format: String = "Большой полёт: %d %s!" if big else "Лови монетки: %d %s!"
		golden_subtitle.text = tr(format) % [minutes, tr(_minutes_word(minutes))]


## Stamps `from`..`to`-1 slam in one by one; reaching 5/5 with the flight open → the series show.
func _play_new_stamps(from: int, to: int, can_fly: bool) -> void:
	_show_state(false)
	var series: bool = can_fly and to >= PData.DAILY_SLOT_COUNT
	var delay: float = 0.35
	for index in range(from, mini(to, _slots.size())):
		var slot: DailySlot = _slots[index]
		slot.play_stamp(delay)
		slot.ev_stamp_landed.connect(_on_stamp_landed.bind(series and index == to - 1), CONNECT_ONE_SHOT)
		delay += stamp_step_sec
	if not series:
		return
	_celebrating = true
	var tween := create_tween()
	tween.tween_interval(delay + 0.45)
	tween.tween_callback(_play_series)


func _on_stamp_landed(completes_series: bool) -> void:
	if root_events:
		root_events.ev_daily_stamp_landed.emit(completes_series)
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.tween_property(self, "rotation", 0.012, 0.04)
	tween.tween_property(self, "rotation", -0.008, 0.06)
	tween.tween_property(self, "rotation", 0.0, 0.08)


## All stamps glow and melt, then the golden flight pops in their place.
func _play_series() -> void:
	var delay: float = 0.0
	for slot in _slots:
		slot.glow_out(delay)
		delay += 0.09
	var tween := create_tween()
	tween.tween_interval(delay + 0.45)
	tween.tween_callback(_pop_golden_state)


func _pop_golden_state() -> void:
	_celebrating = false
	if root_events:
		root_events.ev_daily_series_shown.emit()
	_show_state(true)
	golden_state.pivot_offset = golden_state.size * 0.5
	golden_state.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(golden_state, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Golden flight waiting: stamps hidden, title shown, the scroll breathes and is one big button.
func _show_state(can_fly: bool) -> void:
	for slot in _slots:
		slot.set_shown(not can_fly)
	if golden_title and can_fly:
		golden_title.text = "ЗОЛОТОЙ ПОЛЁТ"
	if golden_state:
		golden_state.visible = can_fly
		golden_state.scale = Vector2.ONE
	if scroll_button:
		scroll_button.visible = can_fly
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	scale = Vector2.ONE
	if not can_fly:
		return
	pivot_offset = size * 0.5
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "scale", Vector2.ONE * pulse_scale, 0.7)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.7)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Finished flight is queued. Hidden card keeps the filled stamps until it is on screen.
func _present_set_reset(reveal: int) -> void:
	if _mounting or not is_visible_in_tree():
		_hold_set_reset(reveal)
		return
	_play_set_reset(reveal)


func _hold_set_reset(reveal: int) -> void:
	_show_state(false)
	_force_stamps_filled()
	_apply_cycle_before_reveal(reveal)


func _play_set_reset(reveal: int) -> void:
	_celebrating = true
	daily_controller.consume_set_reveal()
	_show_state(false)
	_force_stamps_filled()
	_apply_cycle_before_reveal(reveal)
	var clearing := reveal == DailyChallengesController.REVEAL_CLEAR_CYCLE
	var stamps_only := reveal == DailyChallengesController.REVEAL_STAMPS_ONLY
	var start := 0.0
	for step in _slots.size():
		var slot: DailySlot = _slots[_slots.size() - 1 - step]
		slot.lift_stamp(start)
		slot.ev_stamp_landed.connect(_on_stamp_landed.bind(false), CONNECT_ONE_SHOT)
		start += lift_step_sec
	var last_start := maxf(start - lift_step_sec, 0.0)
	var tween := create_tween()
	if not stamps_only:
		tween.tween_interval(0.16)
		tween.tween_callback(_pop_completed_mark.bind(reveal))
		tween.tween_interval(maxf(last_start + DailySlot.LIFT_SEC - 0.16, 0.05))
	else:
		tween.tween_interval(last_start + DailySlot.LIFT_SEC)
	tween.tween_callback(_pop_congrats.bind(clearing))
	tween.tween_interval(congrats_hold_sec)
	tween.tween_callback(_hide_congrats)
	tween.tween_interval(0.26)
	tween.tween_callback(_return_to_default.bind(clearing))
	tween.tween_interval(0.85 if clearing else 0.5)
	tween.tween_callback(_finish_set_reset)


func _force_stamps_filled() -> void:
	for slot in _slots:
		slot.set_filled(true)
		slot.set_shown(true)


## Pips as they looked before this set's mark lands. The clear-cycle flight shows 4 pips, coin still dim.
func _apply_cycle_before_reveal(reveal: int) -> void:
	if reveal == DailyChallengesController.REVEAL_STAMPS_ONLY:
		var filled: int = daily_controller.get_cycle_filled()
		_apply_cycle(filled, filled >= DailyChallengesController.STREAK_CYCLE - 1)
		return
	if reveal == DailyChallengesController.REVEAL_CLEAR_CYCLE:
		_apply_cycle(DailyChallengesController.STREAK_CYCLE - 1, false)
		return
	_apply_cycle(reveal, false)


func _pop_completed_mark(reveal: int) -> void:
	if reveal == DailyChallengesController.REVEAL_CLEAR_CYCLE:
		_pop_mark(cycle_goal, false)
	elif reveal >= 0 and reveal < cycle_pips.size():
		_pop_mark(cycle_pips[reveal], true)
		if reveal == cycle_pips.size() - 1:
			_light_goal()
	if root_events:
		root_events.ev_daily_stamp_landed.emit(false)


func _pop_mark(mark: Control, filled_pip: bool) -> void:
	if mark == null:
		return
	if filled_pip and mark is Panel:
		(mark as Panel).add_theme_stylebox_override("panel", pip_filled)
	_arm_pivot(mark)
	mark.modulate = Color.WHITE
	mark.scale = Vector2.ZERO
	var tween := mark.create_tween()
	tween.tween_property(mark, "scale", Vector2.ONE * 1.45, 0.18)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mark, "scale", Vector2.ONE, 0.12)


## Four sets are in: the coin wakes up so the next flight reads as the long one.
func _light_goal() -> void:
	if cycle_goal == null:
		return
	_arm_pivot(cycle_goal)
	cycle_goal.modulate = Color(1, 1, 1, 0.35)
	cycle_goal.scale = Vector2.ONE
	var tween := cycle_goal.create_tween()
	tween.tween_property(cycle_goal, "modulate", Color.WHITE, 0.2)
	tween.parallel().tween_property(cycle_goal, "scale", Vector2.ONE * 1.28, 0.16)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(cycle_goal, "scale", Vector2.ONE, 0.12)


func _pop_congrats(clearing: bool) -> void:
	if golden_state == null:
		return
	if golden_title:
		golden_title.text = "Круг завершён!" if clearing else "Молодец!"
	if golden_subtitle:
		golden_subtitle.text = "Всё сначала!" if clearing else "Серия собрана!"
	golden_state.visible = true
	golden_state.pivot_offset = golden_state.size * 0.5
	golden_state.scale = Vector2.ZERO
	golden_state.modulate.a = 1.0
	if root_events:
		root_events.ev_daily_series_shown.emit()
	var tween := create_tween()
	tween.tween_property(golden_state, "scale", Vector2.ONE, 0.42)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide_congrats() -> void:
	if golden_state == null or not golden_state.visible:
		return
	var tween := create_tween()
	tween.tween_property(golden_state, "scale", Vector2.ZERO, 0.22)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: golden_state.visible = false)


func _return_to_default(clearing: bool) -> void:
	var step := 0.0
	for slot in _slots:
		slot.reveal_empty(step)
		step += 0.05
	if clearing:
		_clear_cycle_marks()


func _clear_cycle_marks() -> void:
	var marks: Array[Control] = []
	for pip in cycle_pips:
		marks.append(pip)
	if cycle_goal:
		marks.append(cycle_goal)
	var delay := 0.0
	for mark in marks:
		var is_goal := mark == cycle_goal
		var tween := mark.create_tween()
		tween.tween_interval(delay)
		tween.tween_property(mark, "scale", Vector2.ZERO, 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(mark, "modulate:a", 0.0, 0.18)
		tween.tween_callback(_rest_empty_mark.bind(mark, is_goal))
		tween.tween_property(mark, "scale", Vector2.ONE, 0.22)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(mark, "modulate:a", 0.35 if is_goal else 1.0, 0.22)
		delay += 0.06


func _rest_empty_mark(mark: Control, is_goal: bool) -> void:
	if mark is Panel:
		(mark as Panel).add_theme_stylebox_override("panel", pip_empty)
	mark.scale = Vector2.ONE * 0.4
	mark.modulate = Color(1, 1, 1, 0.0)
	_arm_pivot(mark)
	if is_goal:
		mark.modulate = Color(1, 1, 1, 0.0)


func _finish_set_reset() -> void:
	_celebrating = false
	_seen_completed = 0
	refresh()


func _apply_cycle(filled: int, goal_lit: bool) -> void:
	for index in cycle_pips.size():
		var pip: Panel = cycle_pips[index]
		pip.add_theme_stylebox_override("panel", pip_filled if index < filled else pip_empty)
		_rest_control(pip, 1.0)
	if cycle_goal:
		_rest_control(cycle_goal, 1.0 if goal_lit else 0.35)


func _rest_control(mark: Control, alpha: float) -> void:
	mark.scale = Vector2.ONE
	mark.modulate = Color(1, 1, 1, alpha)
	_arm_pivot(mark)


func _arm_pivot(mark: Control) -> void:
	var side := mark.size
	if side.x < 1.0:
		side = mark.custom_minimum_size
	mark.pivot_offset = side * 0.5


func _on_flight_pressed() -> void:
	if root_events == null or golden_flight_config == null:
		return
	var seconds: float = big_flight_sec if daily_controller.is_big_flight_today() else flight_sec
	if not daily_controller.start_bonus_flight():
		return
	root_events.ev_start_game.emit({
		"custom_battle": GoldenFlightScenario.build(golden_flight_config, progress, seconds),
	})


func _on_resized() -> void:
	pivot_offset = size * 0.5
	_fit_slot_sizes()


func _build_slots() -> void:
	for child in slots_row.get_children():
		slots_row.remove_child(child)
		child.free()
	_slots.clear()
	for index in range(PData.DAILY_SLOT_COUNT):
		var slot: DailySlot = slot_scene.instantiate() as DailySlot
		if not stamp_filled_variants.is_empty():
			slot.stamp_filled = stamp_filled_variants[index % stamp_filled_variants.size()]
		slots_row.add_child(slot)
		_slots.append(slot)


func _fit_slot_sizes() -> void:
	if _slots.is_empty() or slots_row == null or size.x <= 1.0:
		return
	var sep: float = float(slots_row.get_theme_constant("separation"))
	var count: int = _slots.size()
	var inset: float = PARCHMENT_INSET * size.x / SCROLL_ART_WIDTH
	var gaps: float = sep * float(count - 1)
	var paper_w: float = size.x - inset * 2.0
	if paper_w <= gaps + 1.0:
		return
	var side: float = clampf((paper_w - gaps) / float(count), slot_size_min, slot_size_max)
	var slot_size := Vector2(side, side)
	for slot in _slots:
		slot.custom_minimum_size = slot_size
		slot.call_deferred("_fit_mark")


## Key «минута» / «минуты» / «минут» for the active language's plural rule.
static func _minutes_word(n: int) -> String:
	return GameLocale.plural(n, "минута", "минуты", "минут")
