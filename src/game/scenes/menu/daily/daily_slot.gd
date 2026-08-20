class_name DailySlot
extends PanelContainer

## Display-only daily challenge slot (not interactive).

@export var mark: TextureRect
@export var star_empty: Texture2D
@export var star_filled: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	if mark != null:
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_fit_star)
	_fit_star()


func set_filled(filled: bool) -> void:
	if mark == null:
		return
	mark.texture = star_filled if filled else star_empty
	mark.modulate = Color.WHITE


func _fit_star() -> void:
	if mark == null:
		return
	# Keep the star at a fixed size; the circle is just a tighter frame around it.
	var inner := 46.0
	mark.custom_minimum_size = Vector2(inner, inner)
	mark.size = Vector2(inner, inner)
