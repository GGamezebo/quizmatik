class_name HoverScaleButton
extends TextureButton

## Shared mouse-hover scale pop for HUD TextureButtons.

const HOVER_SCALE_FACTOR: float = 1.12
const HOVER_TWEEN_DURATION: float = 0.12

var _base_scale: Vector2 = Vector2.ONE
var _hover_tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_entered.connect(_on_hover_entered)
	mouse_exited.connect(_on_hover_exited)
	resized.connect(_update_hover_pivot)
	_base_scale = scale
	_update_hover_pivot()


func _on_hover_entered() -> void:
	_animate_hover_scale(_base_scale * HOVER_SCALE_FACTOR)


func _on_hover_exited() -> void:
	_animate_hover_scale(_base_scale)


func _animate_hover_scale(target_scale: Vector2) -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", target_scale, HOVER_TWEEN_DURATION).set_ease(Tween.EASE_OUT)


func _update_hover_pivot() -> void:
	pivot_offset = size * 0.5
