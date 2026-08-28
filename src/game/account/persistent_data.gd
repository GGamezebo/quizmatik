class_name PData
extends Resource

const DAILY_SLOT_COUNT: int = 5

var levels: LevelsProgress = LevelsProgress.new()
var state: StateData = StateData.new()
var statistics: StatisticsData = StatisticsData.new()
var daily: DailyData = DailyData.new()
var trophies: TrophiesData = TrophiesData.new()


func to_dict() -> Dictionary:
	return {
		"levels": levels.to_dict(),
		"state": state.to_dict(),
		"statistics": statistics.to_dict(),
		"daily": daily.to_dict(),
		"trophies": trophies.to_dict(),
	}

## Mutates this resource in place so every `@export var pdata: PData` sharing the
## same `.tres` sees the loaded / reset state.
func apply_dict(data: Dictionary) -> void:
	levels = LevelsProgress.from_dict(data.get("levels", {}))
	state = StateData.from_dict(data.get("state", {}))
	statistics = StatisticsData.from_dict(data.get("statistics", {}))
	daily = DailyData.from_dict(data.get("daily", {}))
	trophies = TrophiesData.from_dict(data.get("trophies", {}))

func reset_to_defaults() -> void:
	apply_dict({})

static func from_dict(data: Dictionary) -> PData:
	var pdata := PData.new()
	pdata.apply_dict(data)
	return pdata

static func utc_day_key(unix_time: int = -1) -> String:
	# get_datetime_dict_from_unix_time is always UTC; system() needs utc=true.
	var dt: Dictionary = (
		Time.get_datetime_dict_from_unix_time(unix_time)
		if unix_time >= 0
		else Time.get_datetime_dict_from_system(true)
	)
	return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]


class LevelEntry:
	var stars: int = 0
	var seen: bool = false

	func to_dict() -> Dictionary:
		return {
			"stars": stars,
			"seen": seen,
		}

	static func from_dict(d: Dictionary) -> LevelEntry:
		var entry := LevelEntry.new()
		entry.stars = int(d.get("stars", 0))
		entry.seen = bool(d.get("seen", false))
		return entry


class ContainerProgress:
	var seen: bool = false
	var exam_passed: bool = false
	var completed_levels: Dictionary[int, LevelEntry] = {}

	func to_dict() -> Dictionary:
		var entries: Dictionary = {}
		for level_id in completed_levels:
			entries[level_id] = completed_levels[level_id].to_dict()
		return {
			"seen": seen,
			"completed_levels": entries,
			"exam_passed": exam_passed,
		}

	static func from_dict(d: Dictionary) -> ContainerProgress:
		var container := ContainerProgress.new()
		container.seen = bool(d.get("seen", false))
		container.exam_passed = bool(d.get("exam_passed", false))
		var entries: Variant = d.get("completed_levels", {})
		if entries is Dictionary:
			# JSON forces string keys, the schema keys levels by int level_id.
			for level_key in entries as Dictionary:
				container.completed_levels[int(level_key)] = LevelEntry.from_dict(entries[level_key])
		return container

	func ensure_level(level_id: int) -> LevelEntry:
		if not completed_levels.has(level_id):
			completed_levels[level_id] = LevelEntry.new()
		return completed_levels[level_id]


class LevelsProgress:
	const DEFAULT_CONTAINER_ID: String = "addition"

	var containers: Dictionary[String, ContainerProgress] = {
		DEFAULT_CONTAINER_ID: ContainerProgress.new(),
	}

	func to_dict() -> Dictionary:
		var result: Dictionary = {}
		for container_id in containers:
			result[container_id] = containers[container_id].to_dict()
		return result

	static func from_dict(d: Dictionary) -> LevelsProgress:
		var levels := LevelsProgress.new()
		levels.containers.clear()
		for container_id in d:
			var raw: Variant = d[container_id]
			if raw is Dictionary:
				levels.containers[String(container_id)] = ContainerProgress.from_dict(raw)
		if levels.containers.is_empty():
			levels.containers[DEFAULT_CONTAINER_ID] = ContainerProgress.new()
		return levels

	func ensure_container(container_id: String) -> ContainerProgress:
		if not containers.has(container_id):
			containers[container_id] = ContainerProgress.new()
		return containers[container_id]


class TrophiesData:
	var unlocked: Dictionary[String, bool] = {}

	func to_dict() -> Dictionary:
		var result: Dictionary = {}
		for container_id in unlocked:
			result[container_id] = unlocked[container_id]
		return {"unlocked": result}

	static func from_dict(d: Dictionary) -> TrophiesData:
		var trophies := TrophiesData.new()
		var raw: Variant = d.get("unlocked", {})
		if raw is Dictionary:
			for container_id in raw as Dictionary:
				trophies.unlocked[String(container_id)] = bool(raw[container_id])
		return trophies

	func unlock(container_id: String) -> bool:
		if is_unlocked(container_id):
			return false
		unlocked[container_id] = true
		return true

	func is_unlocked(container_id: String) -> bool:
		return unlocked.get(container_id, false)


class StateData:
	var tutorial_completed: bool = false

	func to_dict() -> Dictionary:
		return {
			"tutorial_completed": tutorial_completed,
		}

	static func from_dict(d: Dictionary) -> StateData:
		var state := StateData.new()
		state.tutorial_completed = bool(d.get("tutorial_completed", false))
		return state


class StatisticsData:
	var total_time: float = 0.0
	var game_sessions: int = 0
	var battle_total_time: float = 0.0
	var total_shoot_count: int = 0
	var total_battles: int = 0
	var total_wins: int = 0
	var total_answers: int = 0
	var total_scores: int = 0
	var total_stars: int = 0
	var total_mistakes: int = 0

	func to_dict() -> Dictionary:
		return {
			"total_time": total_time,
			"game_sessions": game_sessions,
			"battle_total_time": battle_total_time,
			"total_shoot_count": total_shoot_count,
			"total_battles": total_battles,
			"total_wins": total_wins,
			"total_answers": total_answers,
			"total_scores": total_scores,
			"total_stars": total_stars,
			"total_mistakes": total_mistakes,
		}

	static func from_dict(d: Dictionary) -> StatisticsData:
		var stats := StatisticsData.new()
		stats.total_time = float(d.get("total_time", 0.0))
		stats.game_sessions = int(d.get("game_sessions", 0))
		stats.battle_total_time = float(d.get("battle_total_time", 0.0))
		stats.total_shoot_count = int(d.get("total_shoot_count", 0))
		stats.total_battles = int(d.get("total_battles", 0))
		stats.total_wins = int(d.get("total_wins", 0))
		stats.total_answers = int(d.get("total_answers", 0))
		stats.total_scores = int(d.get("total_scores", 0))
		stats.total_stars = int(d.get("total_stars", 0))
		stats.total_mistakes = int(d.get("total_mistakes", 0))
		return stats


class DailyData:
	var utc_day: String = ""
	var slots: Array[bool] = empty_slots()

	func to_dict() -> Dictionary:
		return {
			"utc_day": utc_day,
			"slots": slots.duplicate(),
		}

	static func from_dict(d: Dictionary) -> DailyData:
		var daily := DailyData.new()
		daily.utc_day = String(d.get("utc_day", ""))
		var raw: Variant = d.get("slots", [])
		if raw is Array:
			var source: Array = raw
			for index in mini(source.size(), PData.DAILY_SLOT_COUNT):
				daily.slots[index] = bool(source[index])
		return daily

	static func empty_slots() -> Array[bool]:
		var result: Array[bool] = []
		result.resize(PData.DAILY_SLOT_COUNT)
		result.fill(false)
		return result

	func completed_count() -> int:
		return slots.count(true)
