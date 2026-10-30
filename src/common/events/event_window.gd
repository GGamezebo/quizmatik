class_name EventWindow
extends Resource

## One dated run of a seasonal event (`EventCalendar`): open from `start_date` 00:00 UTC through the whole
## `end_date` (UTC). Progress (opened gift boxes) belongs to the run: `key()`; next year's run starts empty.

const DAY_SEC: int = 86400

## `SeasonalEvent.id` of this run.
@export var event_id: String = ""
## First UTC day, "YYYY-MM-DD".
@export var start_date: String = ""
## Last UTC day (inclusive), "YYYY-MM-DD".
@export var end_date: String = ""
## This run's own background (battle sky + last-box gift, on sale from this run's start); empty → the event's `cover`.
@export var cover: CoverItem


func start_unix() -> int:
	return _day_unix(start_date)


## First second after the run (the day after `end_date`, 00:00 UTC).
func end_unix() -> int:
	return _day_unix(end_date) + DAY_SEC


func contains(unix: int) -> bool:
	return unix >= start_unix() and unix < end_unix()


## Progress key of the run in `PData.events`, e.g. "halloween:2026-10-25".
func key() -> String:
	return "%s:%s" % [event_id, start_date]


## The date string is read as UTC (no timezone conversion).
static func _day_unix(date: String) -> int:
	if date.is_empty():
		return 0
	return Time.get_unix_time_from_datetime_string(date + "T00:00:00")
