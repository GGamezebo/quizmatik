extends Node

@export var shot_scene: PackedScene
@export var explosion_scene: PackedScene
@export var game_events: GameEvents

func _on_player_ev_shoot(position:Vector2) -> void:
	if shot_scene:
		var shot = shot_scene.instantiate()
		shot.init(position)
		shot.ev_explosion.connect(_on_explosion)
		owner.add_child(shot)
		
func _on_explosion(answer:Answer) -> void:
	var explosion:Explosion = explosion_scene.instantiate()
	explosion.init(answer.position)
	owner.add_child.call_deferred(explosion)
	game_events.ev_explosion.emit(answer)
