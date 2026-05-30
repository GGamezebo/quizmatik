class_name PDataProgress
extends Resource

const SAVE_PATH: String = "user://progress.tres"
const CURRENT_VERSION: int = 0

@export var progress: Dictionary = {
	"version": 0,  # don't change it
	"levels": {
		"container_1_addition": {
			"completed_levels": {
			},
			"exam_passed": false,
		}
	},
	'statistics': {
		'total_time': 0.0,
		'game_session_count': 0,
		'battle_total_time': 0.0,
		'total_shoot_count': 0,
	},
}
