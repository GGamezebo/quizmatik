class_name PData
extends Resource

const DAILY_SLOT_COUNT: int = 5

var levels: LevelsProgress = LevelsProgress.new()
var state: StateData = StateData.new()
var statistics: StatisticsData = StatisticsData.new()
var daily: DailyData = DailyData.new()
var trophies: TrophiesData = TrophiesData.new()
var mistakes: MistakesData = MistakesData.new()
var cosmetics: CosmeticsData = CosmeticsData.new()
var profile_id: String = ""
var display_name: String = ""
## `BattleDifficulty` id for campaign valleys (`easy` / `normal` / `hard`).
var difficulty: String = "normal"
var gold: int = 0
var equipped_plane_id: String = "starter"
var unlocked_planes: Array[String] = ["starter"]


func to_dict() -> Dictionary:
	return {
		"levels": levels.to_dict(),
		"state": state.to_dict(),
		"statistics": statistics.to_dict(),
		"daily": daily.to_dict(),
		"trophies": trophies.to_dict(),
		"mistakes": mistakes.to_dict(),
		"cosmetics": cosmetics.to_dict(),
		"profile_id": profile_id,
		"name": display_name,
		"difficulty": difficulty,
		"gold": gold,
		"equipped_plane_id": equipped_plane_id,
		"unlocked_planes": unlocked_planes.duplicate(),
	}

## Mutates this resource in place so every `@export var pdata: PData` sharing the
## same `.tres` sees the loaded / reset state.
func apply_dict(data: Dictionary) -> void:
	levels = LevelsProgress.from_dict(data.get("levels", {}))
	state = StateData.from_dict(data.get("state", {}))
	statistics = StatisticsData.from_dict(data.get("statistics", {}))
	daily = DailyData.from_dict(data.get("daily", {}))
	trophies = TrophiesData.from_dict(data.get("trophies", {}))
	mistakes = MistakesData.from_dict(data.get("mistakes", {}))
	cosmetics = CosmeticsData.from_dict(data.get("cosmetics", {}))
	profile_id = String(data.get("profile_id", ""))
	display_name = String(data.get("name", ""))
	difficulty = String(BattleDifficulty.sanitize(StringName(data.get("difficulty", "normal"))))
	gold = maxi(0, int(data.get("gold", 0)))
	equipped_plane_id = String(data.get("equipped_plane_id", "starter"))
	unlocked_planes.clear()
	var planes_raw: Variant = data.get("unlocked_planes", ["starter"])
	if planes_raw is Array:
		for plane_id in planes_raw:
			var id := String(plane_id)
			if not id.is_empty() and not unlocked_planes.has(id):
				unlocked_planes.append(id)
	if unlocked_planes.is_empty():
		unlocked_planes.append("starter")
	if equipped_plane_id.is_empty():
		equipped_plane_id = unlocked_planes[0]
	elif not unlocked_planes.has(equipped_plane_id):
		unlocked_planes.append(equipped_plane_id)

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
	## Valley opened without the previous exam (dev lab «open all valleys»).
	var unlocked: bool = false
	var completed_levels: Dictionary[int, LevelEntry] = {}

	func to_dict() -> Dictionary:
		var entries: Dictionary = {}
		for level_id in completed_levels:
			entries[level_id] = completed_levels[level_id].to_dict()
		return {
			"seen": seen,
			"completed_levels": entries,
			"exam_passed": exam_passed,
			"unlocked": unlocked,
		}

	static func from_dict(d: Dictionary) -> ContainerProgress:
		var container := ContainerProgress.new()
		container.seen = bool(d.get("seen", false))
		container.exam_passed = bool(d.get("exam_passed", false))
		container.unlocked = bool(d.get("unlocked", false))
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

	## Any level or exam earned at least one star (a fresh pilot → false).
	func has_any_stars() -> bool:
		for container_id in containers:
			var container: ContainerProgress = containers[container_id]
			if container.exam_passed:
				return true
			for level_id in container.completed_levels:
				if container.completed_levels[level_id].stars > 0:
					return true
		return false

	func ensure_container(container_id: String) -> ContainerProgress:
		if not containers.has(container_id):
			containers[container_id] = ContainerProgress.new()
		return containers[container_id]


class TrophiesData:
	var unlocked: Dictionary[String, bool] = {}
	## Hall-of-fame awards the player already saw in the trophy room (ids from `ProgressController.award_ids`).
	var seen: Dictionary[String, bool] = {}

	func to_dict() -> Dictionary:
		var result: Dictionary = {}
		for container_id in unlocked:
			result[container_id] = unlocked[container_id]
		var seen_out: Dictionary = {}
		for award_id in seen:
			seen_out[award_id] = seen[award_id]
		return {"unlocked": result, "seen": seen_out}

	static func from_dict(d: Dictionary) -> TrophiesData:
		var trophies := TrophiesData.new()
		var raw: Variant = d.get("unlocked", {})
		if raw is Dictionary:
			for container_id in raw as Dictionary:
				trophies.unlocked[String(container_id)] = bool(raw[container_id])
		var raw_seen: Variant = d.get("seen", {})
		if raw_seen is Dictionary:
			for award_id in raw_seen as Dictionary:
				trophies.seen[String(award_id)] = bool(raw_seen[award_id])
		return trophies

	func unlock(container_id: String) -> bool:
		if is_unlocked(container_id):
			return false
		unlocked[container_id] = true
		return true

	func is_unlocked(container_id: String) -> bool:
		return unlocked.get(container_id, false)


## Weak examples by `MathFact` key (mutated only by `MistakesController`).
## `weights` = review pressure (0 → entry gone); `misses` = total wrong answers while the entry lives.
class MistakesData:
	var weights: Dictionary[String, int] = {}
	var misses: Dictionary[String, int] = {}

	func to_dict() -> Dictionary:
		var weights_out: Dictionary = {}
		var misses_out: Dictionary = {}
		for fact_key in weights:
			weights_out[fact_key] = weights[fact_key]
			misses_out[fact_key] = misses.get(fact_key, 1)
		return {"weights": weights_out, "misses": misses_out}

	static func from_dict(d: Dictionary) -> MistakesData:
		var mistakes := MistakesData.new()
		var raw: Variant = d.get("weights", {})
		var raw_misses: Variant = d.get("misses", {})
		if not (raw_misses is Dictionary):
			raw_misses = {}
		if raw is Dictionary:
			for fact_key in raw as Dictionary:
				var key := String(fact_key)
				var weight: int = int(raw[fact_key])
				if weight > 0 and not MathFact.parse(key).is_empty():
					mistakes.weights[key] = weight
					mistakes.misses[key] = maxi(1, int(raw_misses.get(key, 1)))
		return mistakes

	func erase(fact_key: String) -> void:
		weights.erase(fact_key)
		misses.erase(fact_key)

	## Most missed first, then heaviest, then by key; at most `limit`.
	func top_keys(limit: int) -> Array[String]:
		var keys: Array[String] = []
		keys.assign(weights.keys())
		keys.sort_custom(func(left: String, right: String) -> bool:
			var left_misses: int = misses.get(left, 1)
			var right_misses: int = misses.get(right, 1)
			if left_misses != right_misses:
				return left_misses > right_misses
			if weights[left] != weights[right]:
				return weights[left] > weights[right]
			return left < right
		)
		return keys.slice(0, limit)


class StateData:
	## Whole tutorial finished (all chapters) — AppRoot stops opening `App/Tutorial`.
	var tutorial_completed: bool = false
	## Finished tutorial chapters by id (ids owned by the tutorial context).
	var tutorial_steps: Dictionary[String, bool] = {}
	## Valley last picked in the menu carousel — menu reopens on it ("" = first valley).
	var last_container_id: String = ""

	func to_dict() -> Dictionary:
		var steps: Dictionary = {}
		for step_id in tutorial_steps:
			steps[step_id] = tutorial_steps[step_id]
		return {
			"tutorial_completed": tutorial_completed,
			"tutorial_steps": steps,
			"last_container_id": last_container_id,
		}

	static func from_dict(d: Dictionary) -> StateData:
		var state := StateData.new()
		state.tutorial_completed = bool(d.get("tutorial_completed", false))
		var raw: Variant = d.get("tutorial_steps", {})
		if raw is Dictionary:
			for step_id in raw as Dictionary:
				state.tutorial_steps[String(step_id)] = bool(raw[step_id])
		state.last_container_id = String(d.get("last_container_id", ""))
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
	## Best endless survival time, whole seconds (0 = never played).
	var endless_best_sec: int = 0

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
			"endless_best_sec": endless_best_sec,
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
		stats.endless_best_sec = int(d.get("endless_best_sec", 0))
		return stats


class DailyData:
	var utc_day: String = ""
	var slots: Array[bool] = empty_slots()
	var reward_claimed: bool = false
	## Today's «Золотой полёт» (bonus battle after 5/5) already started.
	var bonus_flight_played: bool = false
	## Consecutive UTC days with all slots filled (kept across days; 0 = broken / never).
	var streak_days: int = 0
	## Last UTC day the slots were completed ("" = never).
	var last_complete_day: String = ""

	func to_dict() -> Dictionary:
		return {
			"utc_day": utc_day,
			"slots": slots.duplicate(),
			"reward_claimed": reward_claimed,
			"bonus_flight_played": bonus_flight_played,
			"streak_days": streak_days,
			"last_complete_day": last_complete_day,
		}

	static func from_dict(d: Dictionary) -> DailyData:
		var daily := DailyData.new()
		daily.utc_day = String(d.get("utc_day", ""))
		daily.reward_claimed = bool(d.get("reward_claimed", false))
		daily.bonus_flight_played = bool(d.get("bonus_flight_played", false))
		daily.streak_days = maxi(int(d.get("streak_days", 0)), 0)
		daily.last_complete_day = String(d.get("last_complete_day", ""))
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


## Bought look items (`CosmeticCatalog` ids) + equipped id per slot key (`CosmeticItem.SLOT_KEYS`).
## Free items are owned implicitly and never stored. Mutated only by `CosmeticsController`.
class CosmeticsData:
	var owned: Array[String] = []
	var equipped: Dictionary[String, String] = {}

	func to_dict() -> Dictionary:
		var equipped_out: Dictionary = {}
		for slot_key in equipped:
			equipped_out[slot_key] = equipped[slot_key]
		return {"owned": owned.duplicate(), "equipped": equipped_out}

	static func from_dict(d: Dictionary) -> CosmeticsData:
		var cosmetics := CosmeticsData.new()
		var owned_raw: Variant = d.get("owned", [])
		if owned_raw is Array:
			for item_id in owned_raw:
				var id := String(item_id)
				if not id.is_empty() and not cosmetics.owned.has(id):
					cosmetics.owned.append(id)
		var equipped_raw: Variant = d.get("equipped", {})
		if equipped_raw is Dictionary:
			for slot_key in equipped_raw as Dictionary:
				cosmetics.equipped[String(slot_key)] = String(equipped_raw[slot_key])
		return cosmetics
