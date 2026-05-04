extends Node

@export var eventManager:EventManager

func _on_player_ev_player_colladed(player: Player, area: Area2D) -> void:
	eventManager.ev_player_colladed.emit(player, area)
