class_name HallBulb
extends Control

## One garland bulb of the hall of fame (template `hall_bulb.tscn`): unlit grey glass, or lit warm glass with
## a twinkling halo. Parent `HallLamps` calls `set_lit`.

@export var glass: TextureRect
@export var glow: TextureRect
@export var unlit_texture: Texture2D
@export var lit_texture: Texture2D

var _tween: Tween


func set_lit(lit: bool, delay: float = 0.0) -> void:
	if _tween:
		_tween.kill()
	glass.texture = unlit_texture
	glow.visible = false
	if not lit:
		return
	_tween = create_tween()
	_tween.tween_interval(delay)
	_tween.tween_callback(_turn_on)


func _turn_on() -> void:
	glass.texture = lit_texture
	glow.visible = true
	glow.pivot_offset = glow.size * 0.5
	glow.scale = Vector2.ZERO
	glow.modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_property(glow, "scale", Vector2.ONE * 1.25, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(glow, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_SINE)
	_tween.tween_callback(_twinkle)


## Soft endless flicker, own random pace per bulb.
func _twinkle() -> void:
	var half: float = randf_range(0.6, 1.1)
	_tween = create_tween().set_loops()
	_tween.tween_property(glow, "modulate:a", randf_range(0.55, 0.75), half).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(glow, "modulate:a", 1.0, half).set_trans(Tween.TRANS_SINE)
