extends Node

@export var game_events:GameEvents

func _on_player_ev_player_colladed(player: Player, area: Area2D) -> void:
	game_events.ev_player_colladed.emit(player, area)
