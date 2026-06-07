class_name PDataProgress
extends Resource

const SAVE_PATH: String = "user://progress.tres"
const CURRENT_VERSION: int = 0

@export var progress: Dictionary = {
	"version": 0,  # don't change it
	"levels": default_levels_progress(),
	"statistics": default_statistics(),
}

static func default_levels_progress() -> Dictionary:
	return {
		"addition": {
			"completed_levels": {
			},
			"exam_passed": false,
		}
	}

static func default_statistics() -> Dictionary:
	return {
		"total_time": 0.0,
		"game_session_count": 0,
		"battle_total_time": 0.0,
		"total_shoot_count": 0,
	}
