class_name Player
extends Node

@export var game_events: GameEvents
@export var gameConfig: GameConfig

@onready var health: int = gameConfig.health:
	set(new_value):
		if health != new_value:
			health = new_value
			game_events.ev_health_changed.emit(health)
