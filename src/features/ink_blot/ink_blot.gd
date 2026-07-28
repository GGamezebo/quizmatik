extends Sprite2D
class_name InkBlot

## Fountain-pen ink stain left on the background paper.

@export var fade_duration: float = 5.0


func setup(local_pos: Vector2) -> void:
	position = local_pos
	hframes = 2
	vframes = 2
	frame = randi() % 4
	rotation = randf_range(-PI, PI)
	var s := randf_range(0.12, 0.38)
	scale = Vector2(s, s * randf_range(0.75, 1.25))
	# Classic blue-black fountain ink, slightly uneven soak.
	var ink := Color(
		randf_range(0.06, 0.14),
		randf_range(0.10, 0.18),
		randf_range(0.22, 0.38),
		randf_range(0.55, 0.88),
	)
	modulate = ink
	z_index = 0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.finished.connect(queue_free)
