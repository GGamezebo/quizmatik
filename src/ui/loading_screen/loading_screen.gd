extends CanvasLayer

@export var progress_bar: ProgressBar
@export var background: CanvasGroup

const duration: float = 1.0


func _ready() -> void:
	# Controls under CanvasGroup use the viewport; re-apply full-rect after first layout
	# so mobile safe areas / unusual aspects still cover the screen.
	get_viewport().size_changed.connect(_fit_to_viewport)
	call_deferred("_fit_to_viewport")


func update_progress(value: float) -> void:
	progress_bar.value = value * 100.0


func fade_out() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	var slide := -get_viewport().get_visible_rect().size.y
	tween.tween_property(self, "offset:y", slide, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(background, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	var random_rotation := randf_range(-45.0, 45.0)
	var target_rotation := background.rotation_degrees + random_rotation
	tween.tween_property(background, "rotation_degrees", target_rotation, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_property(background, "scale", Vector2(0.6, 0.6), duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.finished.connect(queue_free)


func _fit_to_viewport() -> void:
	var vp := get_viewport().get_visible_rect().size
	for child in background.get_children():
		if child is ColorRect or child is TextureRect:
			var rect := child as Control
			rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			rect.offset_left = 0.0
			rect.offset_top = 0.0
			rect.offset_right = 0.0
			rect.offset_bottom = 0.0
			rect.size = vp
		elif child is VBoxContainer:
			var box := child as VBoxContainer
			box.set_anchors_preset(Control.PRESET_CENTER)
			box.reset_size()
			box.position = (vp - box.size) * 0.5
