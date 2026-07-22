class_name Player
extends Node

signal ev_health_changed(new_health: int)
signal ev_score_changed(new_score: int)
signal ev_acceleration_changed(acceleration: float)

const ACCELERATION_DEFAULT: float = GameConfig.PLAYER_ACCELERATION_DEFAULT

var game_events: GameEvents
var components: Array[PlayerComponent] = []
var health: int = 1:
	set(new_value):
		if health != new_value:
			health = new_value
			ev_health_changed.emit(health)

@onready var score: int = 0:
	set(new_value):
		if score != new_value:
			score = new_value
			ev_score_changed.emit(score)

@onready var acceleration: float = ACCELERATION_DEFAULT:
	set(new_value):
		if acceleration != new_value:
			acceleration = new_value
			ev_acceleration_changed.emit(acceleration)		

func initialize(game_config: GameConfig) -> void:
	self.health = game_config.health
	
	var componentClasses = [
		AccelerationComponent
	]
	for componentClass in componentClasses:
		if componentClass.is_need(game_config):
			components.append(componentClass.new(self, game_config))

func _exit_tree() -> void:
	components.reverse()
	for component in components:
		component.deinit()
	components.clear()

func _process(delta: float) -> void:
	for component in components:
		component.process(delta)



@abstract class PlayerComponent:
	var player: Player
	var game_config: GameConfig
	
	static func is_need(_game_config: GameConfig) -> bool:
		return true
		
	func _init(_player: Player, _game_config: GameConfig) -> void:
		player = _player
		game_config = _game_config
	
	func deinit() -> void:
		player = null
		game_config = null
		
	func process(_delta: float) -> void:
		pass

class AccelerationComponent extends PlayerComponent:
	static func is_need(_game_config: GameConfig) -> bool:
		return not is_equal_approx(_game_config.player_acceleration_min, ACCELERATION_DEFAULT) or\
			not is_equal_approx(_game_config.player_acceleration_max, ACCELERATION_DEFAULT)
		
	func process(delta: float) -> void:
		var input_direction: float = Input.get_axis("ui_left", "ui_right")
		var target_acceleration: float = ACCELERATION_DEFAULT
		if not is_zero_approx(input_direction):
			if input_direction >= 0:
				target_acceleration = game_config.player_acceleration_max
			else:
				target_acceleration = game_config.player_acceleration_min
		player.acceleration = move_toward(player.acceleration, target_acceleration, game_config.player_acceleration_speed * delta)
