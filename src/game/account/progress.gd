class_name PDataProgress
extends Resource

const SAVE_PATH: String = "user://progress.tres"
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

static func utc_day_key(unix_time: int = -1) -> String:
	# get_datetime_dict_from_unix_time is always UTC; system() needs utc=true.
	var dt: Dictionary = (
		Time.get_datetime_dict_from_unix_time(unix_time)
		if unix_time >= 0
		else Time.get_datetime_dict_from_system(true)
	)
	return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]
