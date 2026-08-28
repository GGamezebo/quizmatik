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

const EXTRA_ROWS: Array = [
	["avg_battle_time", "СКОРОСТЬ РЕШЕНИЯ", "Среднее время: %s"],
	["total_flights", "КОЛИЧЕСТВО ПОЛЁТОВ", "Всего полётов: %s"],
]


static func format_stat_value(key: String, value: Variant, stats: Dictionary = {}) -> String:
	if key == "avg_battle_time":
		var battles: int = int(stats.get("total_battles", 0))
		if battles <= 0:
			return "—"
		var avg: float = float(stats.get("battle_total_time", 0.0)) / battles
		return format_duration(avg)
	if key == "total_flights":
		return str(int(stats.get("total_battles", 0)))
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
