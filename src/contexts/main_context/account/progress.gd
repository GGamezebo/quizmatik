class_name PDataProgress
extends Resource

const SAVE_PATH: String = "user://progress.tres"
const CURRENT_VERSION: int = 0

@export var progress: Dictionary = {
	"version": 0,  # don't change it
	"levels": default_levels_progress(),
	"state": default_state(),
	"statistics": default_statistics(),
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
