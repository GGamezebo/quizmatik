extends Node


@export var bullet_scene: PackedScene

func _on_player_ev_shoot(position:Vector2) -> void:
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.position = position
		get_tree().root.add_child(bullet)
		
