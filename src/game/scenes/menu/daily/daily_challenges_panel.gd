class_name DailyChallengesPanel
extends Control

## Daily streak card for the main menu: today's 5 stamps, days-in-a-row + 5-day cycle strip in the header.
## New stamps since the card was last shown slam in (sound / vibration via `RootEvents`). 5/5 → the stamps
## glow and melt, «ЗОЛОТОЙ ПОЛЁТ» takes their place and the whole scroll breathes = one big button
## (once per UTC day; the cycle's last day = the long flight). Battle = `GoldenFlightScenario`.

@export var daily_controller: DailyChallengesController
@export var slots_row: HBoxContainer
@export var slot_scene: PackedScene
@export var title_label: Label
## Filled ink stamps assigned by slot index (cycles if fewer than slot count).
@export var stamp_filled_variants: Array[Texture2D] = []
@export var slot_size_max: float = 96.0
@export var slot_size_min: float = 88.0
@export var stamp_step_sec: float = 0.35
@export_group("Streak")
@export var streak_label: Label
## Cycle days before the goal (the goal icon = last day).
@export var cycle_pips: Array[Panel] = []
@export var cycle_goal: Control
@export var pip_empty: StyleBox
@export var pip_filled: StyleBox
@export_group("Golden flight")
@export var root_events: RootEvents
@export var progress: ProgressController
@export var golden_flight_config: GameConfig
@export var golden_state: Control
@export var golden_subtitle: Label
## Covers the whole scroll; shown only while today's flight waits.
@export var scroll_button: BaseButton
@export var flight_sec: float = 60.0
@export var big_flight_sec: float = 120.0
@export var pulse_scale: float = 1.035

## Stamps on the card when it was last shown (session-wide: survives menu remounts); -1 = never.
static var _seen_completed: int = -1

var _slots: Array[DailySlot] = []
var _event_listener = EventListener.new()
var _pulse_tween: Tween
## Series animation running: refreshes (language switch, signals) must not cut it.
var _celebrating: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_event_listener.add(resized, _on_resized)
	_build_slots()
	if daily_controller != null:
		_event_listener.add(daily_controller.ev_daily_changed, refresh)
	if scroll_button != null:
		_event_listener.add(scroll_button.pressed, _on_flight_pressed)
	refresh()
	call_deferred("_fit_slot_sizes")


func refresh() -> void:
	var filled: Array = daily_controller.get_slots()
	for index in range(_slots.size()):
		var is_filled: bool = index < filled.size() and bool(filled[index])
		_slots[index].set_filled(is_filled)
	_refresh_streak()
	_fit_slot_sizes()
	if _celebrating:
		return
	var completed: int = daily_controller.get_completed_count()
	var animate_from: int = _seen_completed if _seen_completed >= 0 and completed > _seen_completed else completed
	_seen_completed = completed
	var can_fly: bool = daily_controller.can_start_bonus_flight() and golden_flight_config != null
	if animate_from < completed:
		_play_new_stamps(animate_from, completed, can_fly)
	else:
		_show_state(can_fly)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh()


func _exit_tree() -> void:
	_event_listener.deinit()


func _refresh_streak() -> void:
	var days: int = daily_controller.get_streak_days()
	if streak_label:
		streak_label.text = _days_in_row_text(days) if days > 0 else ""
	var cycle_filled: int = daily_controller.get_cycle_filled()
	for index in cycle_pips.size():
		cycle_pips[index].add_theme_stylebox_override("panel", pip_filled if index < cycle_filled else pip_empty)
	if cycle_goal:
		cycle_goal.modulate = Color.WHITE if cycle_filled >= DailyChallengesController.STREAK_CYCLE else Color(1, 1, 1, 0.35)
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
	if _slots.is_empty() or slots_row == null:
		return
	var sep: float = float(slots_row.get_theme_constant("separation"))
	var count: int = _slots.size()
	var available: float = maxf(slots_row.size.x - sep * float(count - 1), slot_size_min * count)
	var side: float = clampf(available / float(count), slot_size_min, slot_size_max)
	var slot_size := Vector2(side, side)
	for slot in _slots:
		slot.custom_minimum_size = slot_size
		slot.call_deferred("_fit_mark")


## «1 день подряд», «2 дня подряд», «5 дней подряд» — form by the active language's plural rule.
static func _days_in_row_text(days: int) -> String:
	var format := GameLocale.plural(days, "%d день подряд", "%d дня подряд", "%d дней подряд")
	return TranslationServer.translate(format) % days


## Key «минута» / «минуты» / «минут» for the active language's plural rule.
static func _minutes_word(n: int) -> String:
	return GameLocale.plural(n, "минута", "минуты", "минут")
