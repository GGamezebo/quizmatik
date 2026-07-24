class_name DailyChallengesController
extends Node

signal ev_daily_changed

@export var pdata: PDataProgress
@export var root_events: RootEvents


func _ready() -> void:
	_ensure_today()


func save() -> void:
	root_events.ev_save_progress.emit()


func _ensure_today() -> bool:
	_ensure_daily_dict()
	var today: String = PDataProgress.utc_day_key()
	var daily: Dictionary = pdata.progress["daily"]
	if str(daily.get("utc_day", "")) == today and _slots_valid(daily.get("slots", [])):
		return false
	daily["utc_day"] = today
	daily["slots"] = PDataProgress.default_daily()["slots"]
	save()
	ev_daily_changed.emit()
	return true


func get_slots() -> Array:
	_ensure_today()
	return pdata.progress["daily"]["slots"]


func get_completed_count() -> int:
	var count: int = 0
	for filled in get_slots():
		if filled:
			count += 1
	return count


func is_all_complete() -> bool:
	return get_completed_count() >= PDataProgress.DAILY_SLOT_COUNT


## Registers one daily slot for a successful battle (campaign or training).
## Returns true if a slot was newly filled.
func register_win() -> bool:
	_ensure_today()
	var slots: Array = pdata.progress["daily"]["slots"]
	for index in range(slots.size()):
		if not slots[index]:
			slots[index] = true
			save()
			ev_daily_changed.emit()
			return true
	return false


func _ensure_daily_dict() -> void:
	if not pdata.progress.has("daily"):
		pdata.progress["daily"] = PDataProgress.default_daily()


func _slots_valid(slots: Variant) -> bool:
	if typeof(slots) != TYPE_ARRAY:
		return false
	return (slots as Array).size() == PDataProgress.DAILY_SLOT_COUNT
