class_name MathLabel
extends Label

## Single-line label for math: `set_math_text("√144 = ?")` swaps the font's thin √ for an em space and draws a
## bold radical with a bar over the radicand (readable on phones). Other text is shown as is.

const ROOT_GLYPH := "√"
## Where the drawn radical sits.
const ROOT_GAP := " "

## Stroke of the drawn radical at font size 56 (scales with the font).
@export var root_line_width: float = 6.0
## Editor-set math line (e.g. «√9 = 3»); runtime callers use `set_math_text`.
@export var math_text: String = "":
	set(value):
		math_text = value
		set_math_text(value)

## Digits under the drawn radical ("" = no radical).
var _radicand: String = ""


func set_math_text(value: String) -> void:
	_radicand = ""
	if value.begins_with(ROOT_GLYPH):
		_radicand = value.substr(ROOT_GLYPH.length()).get_slice(" ", 0)
		value = ROOT_GAP + value.substr(ROOT_GLYPH.length())
	text = value
	queue_redraw()


## Tick → down-stroke to the baseline → up above the digits → bar over the radicand.
func _draw() -> void:
	if _radicand.is_empty():
		return
	var font: Font = get_theme_font("font")
	var font_size: int = get_theme_font_size("font_size")
	var full_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var gap: float = font.get_string_size(ROOT_GAP, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var radicand_width: float = font.get_string_size(_radicand, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x0: float = 0.0
	match horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			x0 = (size.x - full_width) * 0.5
		HORIZONTAL_ALIGNMENT_RIGHT:
			x0 = size.x - full_width
	var line_top: float = 0.0
	match vertical_alignment:
		VERTICAL_ALIGNMENT_CENTER:
			line_top = (size.y - font.get_height(font_size)) * 0.5
		VERTICAL_ALIGNMENT_BOTTOM:
			line_top = size.y - font.get_height(font_size)
	var baseline: float = line_top + font.get_ascent(font_size)
	var em: float = float(font_size)
	var top: float = baseline - em * 0.84
	var points := PackedVector2Array([
		Vector2(x0 + gap * 0.06, baseline - em * 0.3),
		Vector2(x0 + gap * 0.24, baseline - em * 0.36),
		Vector2(x0 + gap * 0.5, baseline + em * 0.02),
		Vector2(x0 + gap * 0.86, top),
		Vector2(x0 + gap + radicand_width + em * 0.06, top),
	])
	var color: Color = get_theme_color("font_color")
	if label_settings != null:
		color = label_settings.font_color
	var width: float = root_line_width * em / 56.0
	draw_polyline(points, color, width, true)
	for point in points:
		draw_circle(point, width * 0.5, color)
