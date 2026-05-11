class_name Player
extends Node

signal ev_health_changed(new_health: int)
signal ev_score_changed(new_score: int)

@export var game_events: GameEvents
@export var gameConfig: GameConfig

@onready var health: int = gameConfig.health:
	set(new_value):
		if health != new_value:
			health = new_value
			ev_health_changed.emit(health)

@onready var score: int = 0:
	set(new_value):
		if score != new_value:
			score = new_value
			ev_score_changed.emit(score)
