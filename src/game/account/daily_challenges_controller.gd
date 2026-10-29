class_name DailyChallengesController
extends Node

## Daily stamps (5 win-slots) + a calendar-day streak + a cycle of 5 completed golden flights.
## 5/5 opens a «Золотой полёт». Finishing it clears the stamps (another set can start at once)
## and fills one cycle mark. The flight that starts on the 5th mark lasts longer, then the marks reset.
## +1 gold still only the first 5/5 of the UTC day.

signal ev_daily_changed

## Streak sets per bonus cycle (the last one = big golden flight).
const STREAK_CYCLE: int = 5
## `pending_set_reveal` values. 0..3 = pop that pip. Clear = the 5th mark, then wipe the strip.
const REVEAL_NONE := -1
const REVEAL_CLEAR_CYCLE := 4
const REVEAL_STAMPS_ONLY := 5

@export var pdata: PData
@export var root_events: RootEvents

## This load migrated `cycle_sets` from the old day-streak, and that flight is already counted.
var _migrated_open_flight: bool = false


static func find_in_tree(tree: SceneTree) -> DailyChallengesController:
	if tree == null:
		return null
	return tree.root.find_child("DailyChallengesController", true, false) as DailyChallengesController


func _ready() -> void:
	_prepare_daily()
	if root_events != null:
		root_events.ev_profiles_changed.connect(_on_profiles_changed)
		root_events.ev_exit_game.connect(_on_exit_game)


func _on_profiles_changed() -> void:
	_prepare_daily()
	ev_daily_changed.emit()


func save() -> void:
	root_events.ev_save_progress.emit()


func _prepare_daily() -> void:
	_ensure_today()
	_settle_used_flight()


func _ensure_today() -> bool:
	var today: String = PData.utc_day_key()
	var daily: PData.DailyData = pdata.daily
	var needs_migration := daily.cycle_sets < 0
	var rolled := false
	if daily.utc_day != today or daily.slots.size() != PData.DAILY_SLOT_COUNT:
		rolled = true
		# A day without 5/5 in between breaks the streak. The set cycle is flights, not days.
		if daily.last_complete_day != today and daily.last_complete_day != _yesterday_key():
			daily.streak_days = 0
		daily.utc_day = today
		daily.slots = PData.DailyData.empty_slots()
		daily.reward_claimed = false
		daily.bonus_flight_played = false
		daily.pending_set_reveal = REVEAL_NONE
	_migrated_open_flight = false
	if needs_migration:
		daily.cycle_sets = _legacy_cycle_sets(daily)
		_migrated_open_flight = daily.bonus_flight_played and daily.completed_count() >= PData.DAILY_SLOT_COUNT
	if rolled or needs_migration:
		save()
		ev_daily_changed.emit()
	return rolled


func get_slots() -> Array:
	_ensure_today()
	return pdata.daily.slots


func get_completed_count() -> int:
	_ensure_today()
	return pdata.daily.completed_count()


func is_all_complete() -> bool:
	return get_completed_count() >= PData.DAILY_SLOT_COUNT


## Registers one daily slot for a successful battle (campaign or training).
## Returns `{slot_filled, gold_awarded}`. Gold is granted once per UTC day at 5/5.
func register_win() -> Dictionary:
	_ensure_today()
	var slot_filled := false
	var slots: Array[bool] = pdata.daily.slots
	for index in range(slots.size()):
		if not slots[index]:
			slots[index] = true
			slot_filled = true
			break
	var gold_awarded := false
	if slot_filled and pdata.daily.completed_count() >= PData.DAILY_SLOT_COUNT:
		_count_streak_day()
	if pdata.daily.completed_count() >= PData.DAILY_SLOT_COUNT and not pdata.daily.reward_claimed:
		pdata.daily.reward_claimed = true
		pdata.gold += 1
		gold_awarded = true
	if slot_filled or gold_awarded:
		save()
		ev_daily_changed.emit()
	return {
		"slot_filled": slot_filled,
		"gold_awarded": gold_awarded,
	}


## «Золотой полёт»: open after 5/5 until it is started. Finishing it clears the slots for another set.
func can_start_bonus_flight() -> bool:
	return is_all_complete() and not pdata.daily.bonus_flight_played


func is_bonus_flight_played() -> bool:
	_ensure_today()
	return pdata.daily.bonus_flight_played


## Marks the open flight as used (before the battle starts → no replays). False = not available.
func start_bonus_flight() -> bool:
	if not can_start_bonus_flight():
		return false
	pdata.daily.bonus_flight_played = true
	save()
	ev_daily_changed.emit()
	return true


## Days in a row with 5/5 (today included once completed).
func get_streak_days() -> int:
	_ensure_today()
	return pdata.daily.streak_days


## 0..1 sky paint. A finished flight today stays fully colored until the next UTC day.
func get_sky_fill() -> float:
	_ensure_today()
	if _flight_colored_today():
		return 1.0
	return clampf(float(pdata.daily.completed_count()) / float(PData.DAILY_SLOT_COUNT), 0.0, 1.0)


## True after a golden flight was finished today, even once the stamps are cleared.
func holds_full_sky() -> bool:
	_ensure_today()
	return _flight_colored_today()


func _flight_colored_today() -> bool:
	var daily: PData.DailyData = pdata.daily
	return not daily.last_flight_day.is_empty() and daily.last_flight_day == daily.utc_day


## Filled marks of the 0..4 set strip (the coin is the 5th, lit by the panel when this is 4).
func get_cycle_filled() -> int:
	_ensure_today()
	return clampi(pdata.daily.cycle_sets, 0, STREAK_CYCLE - 1)


## The flight about to start completes the cycle → it is the long one.
func is_big_flight_today() -> bool:
	_ensure_today()
	return pdata.daily.cycle_sets >= STREAK_CYCLE - 1


## Ceremony the daily card still has to play (`REVEAL_*`). -1 = nothing pending.
func get_pending_set_reveal() -> int:
	_ensure_today()
	return pdata.daily.pending_set_reveal


## Dev lab: pretend a UTC day passed. Stored daily dates step back, then the normal roll runs.
func debug_advance_day() -> void:
	_ensure_today()
	var daily: PData.DailyData = pdata.daily
	daily.utc_day = _previous_day_key(daily.utc_day)
	daily.last_flight_day = _previous_day_key(daily.last_flight_day)
	daily.last_complete_day = _previous_day_key(daily.last_complete_day)


## The card started the ceremony. Does not emit — a refresh would cut the animation.
func consume_set_reveal() -> void:
	if pdata.daily.pending_set_reveal < 0:
		return
	pdata.daily.pending_set_reveal = REVEAL_NONE
	save()


func _count_streak_day() -> void:
	var daily: PData.DailyData = pdata.daily
	var today: String = PData.utc_day_key()
	if daily.last_complete_day == today:
		return
	daily.streak_days = daily.streak_days + 1 if daily.last_complete_day == _yesterday_key() else 1
	daily.last_complete_day = today


## Finished flight → one set. The 5th set of the cycle wraps the strip back to empty.
func _bank_completed_set() -> void:
	var daily: PData.DailyData = pdata.daily
	if daily.pending_set_reveal >= 0:
		return
	if daily.completed_count() < PData.DAILY_SLOT_COUNT:
		return
	var index := clampi(daily.cycle_sets, 0, STREAK_CYCLE - 1)
	if index >= STREAK_CYCLE - 1:
		daily.cycle_sets = 0
		daily.pending_set_reveal = REVEAL_CLEAR_CYCLE
	else:
		daily.cycle_sets = index + 1
		daily.pending_set_reveal = index
	daily.slots = PData.DailyData.empty_slots()
	daily.bonus_flight_played = false
	daily.last_flight_day = daily.utc_day if not daily.utc_day.is_empty() else PData.utc_day_key()
	# No signal: this runs while the battle scene is still up, and a repaint would flash the sky.
	save()


## Left the flight early: the same set can be launched again. No pip, no stamp reset.
func _restore_bonus_flight() -> void:
	var daily: PData.DailyData = pdata.daily
	if not daily.bonus_flight_played or daily.pending_set_reveal >= 0:
		return
	daily.bonus_flight_played = false
	save()


## A used flight with no win saved: the player quit, or the app closed mid-flight.
## Old saves that already counted the flight only replay the stamp reset.
func _settle_used_flight() -> void:
	var daily: PData.DailyData = pdata.daily
	if daily.pending_set_reveal >= 0:
		_migrated_open_flight = false
		return
	if _migrated_open_flight:
		_migrated_open_flight = false
		daily.slots = PData.DailyData.empty_slots()
		daily.bonus_flight_played = false
		daily.pending_set_reveal = REVEAL_STAMPS_ONLY
		save()
		ev_daily_changed.emit()
		return
	if not daily.bonus_flight_played:
		return
	daily.bonus_flight_played = false
	save()
	ev_daily_changed.emit()


func _on_exit_game(data: Dictionary) -> void:
	var config: Variant = data.get("game_config")
	if config == null or not (config is GameConfig):
		return
	if not (config as GameConfig).golden_flight:
		return
	if bool(data.get("is_win", false)):
		_bank_completed_set()
	else:
		_restore_bonus_flight()


## Old day-cycle position, after today's roll. An unflown set from today is not a finished flight yet.
static func _legacy_cycle_sets(daily: PData.DailyData) -> int:
	if daily.streak_days <= 0:
		return 0
	var filled: int
	if daily.last_complete_day != daily.utc_day:
		filled = daily.streak_days % STREAK_CYCLE
	else:
		var position := (daily.streak_days - 1) % STREAK_CYCLE + 1
		if position == STREAK_CYCLE and daily.bonus_flight_played:
			return 0
		filled = position
		if not daily.bonus_flight_played:
			filled -= 1
	return clampi(filled, 0, STREAK_CYCLE - 1)


static func _yesterday_key() -> String:
	return PData.utc_day_key(int(Time.get_unix_time_from_system()) - 86400)


static func _previous_day_key(day: String) -> String:
	if day.is_empty():
		return ""
	var bits: PackedStringArray = day.split("-")
	if bits.size() != 3:
		return day
	var year := int(bits[0])
	var month := int(bits[1])
	var day_num := int(bits[2]) - 1
	if day_num < 1:
		month -= 1
		if month < 1:
			month = 12
			year -= 1
		var lengths: PackedInt32Array = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
		day_num = lengths[month - 1]
		if month == 2 and (year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)):
			day_num = 29
	return "%04d-%02d-%02d" % [year, month, day_num]
