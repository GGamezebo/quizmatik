extends AnimatedSprite2D
class_name BalloonPop


func _ready() -> void:
	animation_finished.connect(queue_free)
	if not is_playing():
		play("default")


static func spawn(
	pop_scene: PackedScene,
	parent: Node,
	global_pos: Vector2,
	tint: Color,
) -> BalloonPop:
	var pop: BalloonPop = pop_scene.instantiate()
	pop.modulate = tint
	parent.add_child(pop)
	pop.global_position = global_pos
	return pop
