extends CanvasLayer

@export var progress_bar:ProgressBar

func update_progress(value: float):
	progress_bar.value = value * 100

func fade_out():
	var tween = create_tween()
	tween.tween_property(self, "offset:y", -1080, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)
