class_name GameConfig
extends Resource

var extra_info: Dictionary = {}

enum Operations {
	ADDITION = 1,       # 1 << 0
	SUBTRACTION = 2,    # 1 << 1
	MULTIPLICATION = 4, # 1 << 2
	DIVISION = 8        # 1 << 3
}

@export_category("Global Game Settings")
@export var answer_lines_count: int = 4
@export var health: int = 3
@export var questions_count: int = 5
@export_flags("Addition:1", "Subtraction:2", "Multiplication:4", "Division:8") var allowed_operations: int = Operations.ADDITION | Operations.SUBTRACTION
@export var min_generate_number: int = 2
@export var max_generate_number: int = 9
@export var answer_speed: float = 80.0

@export_category("AirPlane")
@export var player_air_plane_speed: float = 600.0
const PLAYER_ACCELERATION_DEFAULT: float = 1.0  # default acceleration coefficient
@export var player_acceleration_min: float = 0.5  # min acceleration coefficient
@export var player_acceleration_max: float = 2.0  # max acceleration coefficient
@export var player_acceleration_speed: float = 1.0  # acceleration coefficient per second
