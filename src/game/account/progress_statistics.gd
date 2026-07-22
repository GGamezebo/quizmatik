class_name ProgressStatistics
extends RefCounted

## Player-facing order for Trophy Room (key → title).
const DISPLAY_ROWS: Array = [
	["total_wins", "Победы"],
	["total_battles", "Битвы"],
	["total_answers", "Верные ответы"],
	["total_stars", "Звёзды"],
	# ["total_scores", "Очки"],
	# ["total_mistakes", "Ошибки"],
	["total_shoot_count", "Выстрелы"],
	#["battle_total_time", "Время в бою"],
	["total_time", "Время в игре"],
	["game_sessions", "Сессии"],
]


static func format_stat_value(key: String, value: Variant) -> String:
	if key.ends_with("_time") and (value is float or value is int):
		return format_duration(float(value))
	return str(value)


static func format_duration(seconds: float) -> String:
	var total_seconds: int = maxi(0, int(round(seconds)))
	var hours: int = int(total_seconds / 3600.0)
	var minutes: int = int((total_seconds % 3600) / 60.0)
	var secs: int = total_seconds % 60
	if hours > 0:
		return "%dч %02dм %02dс" % [hours, minutes, secs]
	if minutes > 0:
		return "%dм %02dс" % [minutes, secs]
	return "%dс" % secs
