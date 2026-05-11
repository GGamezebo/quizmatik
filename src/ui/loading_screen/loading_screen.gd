extends CanvasLayer

@export var progress_bar: ProgressBar
@export var background: CanvasGroup

const duration: float = 1.0

func update_progress(value: float):
	progress_bar.value = value * 100

func fade_out():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "offset:y", -1080, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(background, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	var random_rotation = randf_range(-45.0, 45.0)
	var target_rotation = background.rotation_degrees + random_rotation
	tween.tween_property(background, "rotation_degrees", target_rotation, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
	tween.tween_property(background, "scale", Vector2(0.6, 0.6), duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween.finished.connect(queue_free)
