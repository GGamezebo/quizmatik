extends AnimatedSprite2D
class_name Explosion

func init(_position: Vector2) -> void:
	position = _position
	animation_finished.connect(queue_free)

static func spawn_attached(
	explosion_scene: PackedScene,
	parent: Node2D,
	global_hit: Vector2,
) -> Explosion:
	var explosion: Explosion = explosion_scene.instantiate()
	explosion.init(parent.to_local(global_hit))
	parent.add_child(explosion)
	return explosion
