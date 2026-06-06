extends Label

## Padding from the label edges in pixels
@export var padding: float = 0.0

func _ready():
	# Center pivot so text scales toward the middle
	pivot_offset = size / 2
	
	# Re-fit when the label is resized (e.g. window resize)
	item_rect_changed.connect(_on_resized)
	
	_update_best_fit()

func _on_resized():
	pivot_offset = size / 2
	_update_best_fit()

## Call when the text changes (e.g. a new answer value)
func set_answer_text(new_text: String):
	text = new_text
	# Wait one frame so Godot updates the text size
	await owner.process_frame
	_update_best_fit()

func _update_best_fit():
	# Reset scale before measuring
	scale = Vector2.ONE
	
	var font = get_theme_font("font")
	var font_size = get_theme_font_size("font_size")
	
	# Measure text width via TextServer
	var text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	var available_width = size.x - (padding * 2)
	
	if text_width > available_width and available_width > 0:
		var fit_factor = available_width / text_width
		scale = Vector2(fit_factor, fit_factor)
	else:
		scale = Vector2.ONE
