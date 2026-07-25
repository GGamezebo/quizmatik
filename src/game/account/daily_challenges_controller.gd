class_name DailyChallengesController
extends Node

signal ev_daily_changed

@export var pdata: PData
@export var root_events: RootEvents


func _ready() -> void:
	_ensure_today()


func save() -> void:
	root_events.ev_save_progress.emit()


func _ensure_today() -> bool:
	var today: String = PData.utc_day_key()
	var daily: PData.DailyData = pdata.daily
	if daily.utc_day == today and daily.slots.size() == PData.DAILY_SLOT_COUNT:
		return false
	daily.utc_day = today
	daily.slots = PData.DailyData.empty_slots()
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
## Returns true if a slot was newly filled.
func register_win() -> bool:
	_ensure_today()
	var slots: Array[bool] = pdata.daily.slots
	for index in range(slots.size()):
		if not slots[index]:
			slots[index] = true
			save()
			ev_daily_changed.emit()
			return true
	return false
