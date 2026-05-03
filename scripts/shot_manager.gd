extends Node

@export var shot_scene: PackedScene
@export var explosion_scene: PackedScene
@export var eventManager: EventManager

func _on_player_ev_shoot(position:Vector2) -> void:
	if shot_scene:
		var shot = shot_scene.instantiate()
		shot.init(position)
		shot.ev_explosion.connect(_on_explosion)
		get_tree().root.add_child(shot)
		
func _on_explosion(answer:Answer) -> void:
	var explosion:Explosion = explosion_scene.instantiate()
	explosion.init(answer.position)
	get_tree().root.add_child.call_deferred(explosion)
	eventManager.ev_explosion.emit(answer)
