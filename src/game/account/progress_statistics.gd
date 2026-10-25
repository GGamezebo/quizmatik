class_name ProgressStatistics
extends RefCounted

## Player-facing order for Trophy Room (key → title).
const DISPLAY_ROWS: Array = [
	["total_wins", "Победы"],
	["total_battles", "Битвы"],
	["total_answers", "Верные ответы"],
	["total_stars", "Звёзды"],
	["total_shoot_count", "Выстрелы"],
	["total_time", "Время в игре"],
	["game_sessions", "Сессии"],
]


static func format_stat_value(key: String, value: Variant, _stats: Dictionary = {}) -> String:
	if key.ends_with("_time") and (value is float or value is int):
		return format_duration(float(value))
	return str(value)


static func format_duration(seconds: float) -> String:
	var total_seconds: int = maxi(0, int(round(seconds)))
	var hours: int = int(total_seconds / 3600.0)
	var minutes: int = int((total_seconds % 3600) / 60.0)
	var secs: int = total_seconds % 60
	if hours > 0:
		return _tr("%dч %02dм %02dс") % [hours, minutes, secs]
	if minutes > 0:
		return _tr("%dм %02dс") % [minutes, secs]
	return _tr("%dс") % secs


## Whole minutes for parents: «1 ч 05 мин» / «12 мин» (seconds mean nothing in a report).
static func format_hours_minutes(seconds: float) -> String:
	var minutes: int = maxi(0, int(seconds / 60.0))
	@warning_ignore("integer_division")
	var hours: int = minutes / 60
	if hours > 0:
		return _tr("%d ч %02d мин") % [hours, minutes % 60]
	return _tr("%d мин") % minutes


## Stopwatch look «m:ss», from an hour «h:mm:ss» (endless time in HUD, post-battle, menu, trophy room).
static func format_clock(seconds: int) -> String:
	var total: int = maxi(0, seconds)
	@warning_ignore("integer_division")
	var hours: int = total / 3600
	@warning_ignore("integer_division")
	var minutes: int = (total % 3600) / 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, total % 60]
	return "%d:%02d" % [minutes, total % 60]


## Record battles (menu endless, valley clocks) pay per new whole minute of the record: 2:45 → 3:00+ = 1.
const RECORD_MINUTE_SEC := 60


## New whole record minutes reached by `seconds` over the previous best `best_before` (0 = no coin).
static func record_new_minutes(seconds: int, best_before: int) -> int:
	@warning_ignore("integer_division")
	return maxi(0, seconds / RECORD_MINUTE_SEC - maxi(0, best_before) / RECORD_MINUTE_SEC)


## Record time that pays the next coin after a best of `best` seconds (the next whole minute).
static func next_record_coin_sec(best: int) -> int:
	@warning_ignore("integer_division")
	return (maxi(0, best) / RECORD_MINUTE_SEC + 1) * RECORD_MINUTE_SEC


static func _tr(message: String) -> String:
	return String(TranslationServer.translate(message))
