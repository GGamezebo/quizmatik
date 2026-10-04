extends Sprite2D
class_name InkBlot

## Fountain-pen ink stain left on the background paper.

@export var fade_duration: float = 5.0
## Recolors the dark atlas with the modulate color (colored shot inks only).
@export var tint_material: Material


## `style` = equipped shot look (colors / drip sprite); null → classic fountain ink.
func setup(local_pos: Vector2, style: ShotItem = null) -> void:
	position = local_pos
	var scale_min := 0.12
	var scale_max := 0.38
	if style != null:
		if not style.ink_colors.is_empty():
			material = tint_material
		scale_min = style.drip_scale_min
		scale_max = style.drip_scale_max
		if style.drip_texture != null:
			texture = style.drip_texture
			hframes = maxi(1, style.drip_frames.x)
			vframes = maxi(1, style.drip_frames.y)
	frame = randi() % (hframes * vframes)
	var s := randf_range(scale_min, scale_max)
	if style != null and style.drip_texture != null:
		# Shaped drips (stars, hearts) stay readable: slight tilt, no squash.
		rotation = randf_range(-0.35, 0.35)
		scale = Vector2(s, s)
	else:
		rotation = randf_range(-PI, PI)
		scale = Vector2(s, s * randf_range(0.75, 1.25))
	modulate = style.pick_ink_color() if style != null else ShotItem.classic_ink()
	z_index = 0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.finished.connect(queue_free)
