class_name DailyChallengesController
extends Node

## Daily stamps (5 win-slots per UTC day) + day streak (consecutive days with all slots filled).
## 5/5 opens one «Золотой полёт» a day; every `STREAK_CYCLE`-th streak day it is the big (longer) one.

signal ev_daily_changed

## Streak days per bonus cycle (the last one = big golden flight); a missed day or the big flight resets it.
const STREAK_CYCLE: int = 5

@export var pdata: PData
@export var root_events: RootEvents


func _ready() -> void:
	_ensure_today()
	if root_events != null:
		root_events.ev_profiles_changed.connect(_on_profiles_changed)


func _on_profiles_changed() -> void:
	_ensure_today()
	ev_daily_changed.emit()


func save() -> void:
	root_events.ev_save_progress.emit()


func _ensure_today() -> bool:
	var today: String = PData.utc_day_key()
	var daily: PData.DailyData = pdata.daily
	if daily.utc_day == today and daily.slots.size() == PData.DAILY_SLOT_COUNT:
		return false
	# A day without 5/5 in between breaks the streak.
	if daily.last_complete_day != today and daily.last_complete_day != _yesterday_key():
		daily.streak_days = 0
	daily.utc_day = today
	daily.slots = PData.DailyData.empty_slots()
	daily.reward_claimed = false
	daily.bonus_flight_played = false
	save()
	ev_daily_changed.emit()
	return true


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


## «Золотой полёт»: one bonus battle per UTC day, open after 5/5.
func can_start_bonus_flight() -> bool:
	return is_all_complete() and not pdata.daily.bonus_flight_played


func is_bonus_flight_played() -> bool:
	_ensure_today()
	return pdata.daily.bonus_flight_played


## Marks today's bonus flight as used (before the battle starts → no replays). False = not available.
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


## Filled marks of the 0..`STREAK_CYCLE` progress strip. Resets after the big day (once its flight
## is used, or on the next day) and on a broken streak.
func get_cycle_filled() -> int:
	_ensure_today()
	var daily: PData.DailyData = pdata.daily
	if daily.streak_days <= 0:
		return 0
	if daily.last_complete_day != daily.utc_day:
		return daily.streak_days % STREAK_CYCLE
	var position: int = (daily.streak_days - 1) % STREAK_CYCLE + 1
	if position == STREAK_CYCLE and daily.bonus_flight_played:
		return 0
	return position


## Today completes a streak cycle → the golden flight is the big one.
func is_big_flight_today() -> bool:
	_ensure_today()
	var daily: PData.DailyData = pdata.daily
	return daily.streak_days > 0 and daily.last_complete_day == daily.utc_day 		and daily.streak_days % STREAK_CYCLE == 0


func _count_streak_day() -> void:
	var daily: PData.DailyData = pdata.daily
	var today: String = PData.utc_day_key()
	if daily.last_complete_day == today:
		return
	daily.streak_days = daily.streak_days + 1 if daily.last_complete_day == _yesterday_key() else 1
	daily.last_complete_day = today


static func _yesterday_key() -> String:
	return PData.utc_day_key(int(Time.get_unix_time_from_system()) - 86400)
