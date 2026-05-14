extends Resource
class_name GameConfig

@export_category("Global Game Settings")
@export var answer_lines_count: int = 4
@export var health: int = 3
@export var questions_count: int = 5
@export var min_generate_number: int = 2
@export var max_generate_number: int = 9
@export var answer_speed: float = 50.0

@export_category("AirPlane")
@export var player_air_plane_speed: float = 800.0


@export var answer_speed1: float = 50.0
@export var answer_speed2: float = 50.0
@export var answer_speed3: float = 50.0
@export var answer_speed4: float = 50.0
@export var answer_speed5: float = 50.0
@export var answer_speed6: float = 50.0
@export var answer_speed7: float = 50.0
@export var answer_speed9: float = 50.0
@export var answer_speed0: float = 50.0
@export var answer_spee1: float = 50.0
@export var answer_spee2: float = 50.0
@export var answer_spee3: float = 50.0
@export var answer_spee4: float = 50.0
@export var answer_spee5: float = 50.0
@export var answer_spee6: float = 50.0
@export var answer_spee7: float = 50.0


func clone() -> GameConfig:
	return self.duplicate(true)
