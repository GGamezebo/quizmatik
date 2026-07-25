class_name PDataProgress
extends Resource

const SAVE_PATH: String = "user://progress.json"
const CURRENT_VERSION: int = 1
const DAILY_SLOT_COUNT: int = 5

@export var progress: Dictionary = {
	"version": 0,  # don't change it
	"levels": default_levels_progress(),
	"state": default_state(),
	"statistics": default_statistics(),
	"daily": default_daily(),
}

static func default_container() -> Dictionary:
	return {
		"seen": false,
		"completed_levels": {
			# level_id: {'stars': int, 'seen': bool}
		},
		"exam_passed": false,
	}

static func default_levels_progress() -> Dictionary:
	return {
		"addition": default_container(),
	}
	
static func default_state() -> Dictionary:
	return {
		"tutorial_completed": false,
	}

static func default_statistics() -> Dictionary:
	return {
		"total_time": 0.0,
		"game_sessions": 0,
		"battle_total_time": 0.0,
		"total_shoot_count": 0,
		"total_battles": 0,
		"total_wins": 0,
		"total_answers": 0,
		"total_scores": 0,
		"total_stars": 0,
		"total_mistakes": 0,
	}

static func default_daily() -> Dictionary:
	var slots: Array = []
	slots.resize(DAILY_SLOT_COUNT)
	slots.fill(false)
	return {
		"utc_day": "",
		"slots": slots,
	}

## JSON forces every dictionary key to a String. Restore the int keys the
## progress schema relies on (per-container completed_levels is keyed by level_id).
static func normalize_loaded(data: Dictionary) -> Dictionary:
	var levels: Variant = data.get("levels")
	if levels is Dictionary:
		for container_id in levels:
			var container: Variant = levels[container_id]
			if not (container is Dictionary):
				continue
			var completed: Variant = container.get("completed_levels")
			if not (completed is Dictionary):
				continue
			var fixed: Dictionary = {}
			for level_key in completed:
				fixed[int(level_key)] = completed[level_key]
			container["completed_levels"] = fixed
	return data

static func utc_day_key(unix_time: int = -1) -> String:
	# get_datetime_dict_from_unix_time is always UTC; system() needs utc=true.
	var dt: Dictionary = (
		Time.get_datetime_dict_from_unix_time(unix_time)
		if unix_time >= 0
		else Time.get_datetime_dict_from_system(true)
	)
	return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]
