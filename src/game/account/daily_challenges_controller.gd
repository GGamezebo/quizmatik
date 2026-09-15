class_name DailyChallengesController
extends Node

signal ev_daily_changed

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
	daily.utc_day = today
	daily.slots = PData.DailyData.empty_slots()
	daily.reward_claimed = false
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
