extends Button

## Square cream level tile. Next = green; exam = purple + graduation-cap overlay.

const CREAM := Color(0.992, 0.984, 0.957, 1.0)
const CREAM_LOCKED := Color(0.94, 0.92, 0.88, 1.0)
const GRAPHITE := Color(0.376, 0.353, 0.345, 1.0)
const BORDER_SOFT := Color(0.165, 0.2, 0.251, 0.16)
const GREEN_BORDER := Color(0.45, 0.62, 0.42, 1.0)
const PURPLE_BORDER := Color(0.55, 0.42, 0.72, 1.0)
const PURPLE_TEXT := Color(0.42, 0.32, 0.58, 1.0)
const CORNER := 18
const BORDER_NORMAL := 2
const BORDER_FOCUS := 4
const TILE_SIZE := Vector2(100, 100)

@export var text_lable: Label
@export var stars: Array[TextureRect]
@export var star_empty: Texture2D
@export var star_filled: Texture2D
@export var stamp_rect: TextureRect
@export var exam_icon: TextureRect
@export var exam_cap: TextureRect
@export var exam_title: Label
@export var exam_hint: Label
@export var exam_header: Control
@export var next_badge: Label
@export var lock_icon: TextureRect
@export var inner_frame: Panel

var is_exam: bool = false
var level_id: int = 0
var _unlocked: bool = false
var _is_next: bool = false
var _stars_count: int = 0

## Slight ink-stamp tilt so completed tiles don't look identical.
const STAMP_ROTATION_DEG := 8.0
const STAMP_PIVOT := Vector2(24, 24)

const INNER_BORDER := 2
const INNER_CORNER := 12
const INNER_SOFT := Color(0.165, 0.2, 0.251, 0.28)
const INNER_GREEN := Color(0.45, 0.62, 0.42, 0.55)
const INNER_PURPLE := Color(0.55, 0.42, 0.72, 0.55)


func _ready() -> void:
	text = ""
	icon = null
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = TILE_SIZE
	_style_next_badge()
	HoverScaleButton.bind(self)
	_apply_exam_layout()
	_refresh_chrome()


func _style_next_badge() -> void:
	if next_badge == null:
		return
	var bg := next_badge.get_node_or_null("NextBadgeBg") as Panel
	if bg == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.45, 0.62, 0.42, 1.0)
	style.set_corner_radius_all(10)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	bg.add_theme_stylebox_override("panel", style)


func initialize(_level_id: int, is_unlocked: bool, stars_count: int, _is_exam: bool) -> void:
	level_id = _level_id
	is_exam = _is_exam
	if text_lable:
		text_lable.text = str(level_id)
	_apply_exam_layout()
	_set_params(is_unlocked, stars_count)


func set_params(is_unlocked: bool, stars_count: int) -> void:
	_set_params(is_unlocked, stars_count)


func set_as_next(is_next: bool) -> void:
	_is_next = is_next and not is_exam
	_refresh_chrome()


func _set_params(is_unlocked: bool, stars_count: int) -> void:
	_unlocked = is_unlocked
	_stars_count = clampi(stars_count, 0, 3)
	for i in range(stars.size()):
		stars[i].visible = true
		stars[i].modulate = Color(1, 1, 1, 1.0 if (_unlocked or is_exam) else 0.7)
		stars[i].texture = star_filled if i < _stars_count else star_empty

	_refresh_stamp(_stars_count >= 1)
	disabled = not is_exam and not is_unlocked
	_refresh_chrome()


func _refresh_stamp(completed: bool) -> void:
	if stamp_rect == null:
		return
	if not completed:
		stamp_rect.visible = false
		stamp_rect.texture = null
		return
	stamp_rect.texture = LevelPackArt.get_exam_stamp(_stars_count)
	stamp_rect.visible = stamp_rect.texture != null
	stamp_rect.pivot_offset = stamp_rect.size * 0.5 if stamp_rect.size.x > 1.0 else STAMP_PIVOT
	stamp_rect.rotation_degrees = STAMP_ROTATION_DEG


func _apply_exam_layout() -> void:
	custom_minimum_size = TILE_SIZE
	# Cap silhouette replaces the tiny corner icon.
	if exam_cap:
		exam_cap.visible = is_exam
	if exam_icon:
		exam_icon.visible = false
	if exam_header:
		exam_header.visible = is_exam
	if exam_title:
		exam_title.visible = is_exam
	if exam_hint:
		exam_hint.visible = false
	if text_lable:
		text_lable.visible = not is_exam
	if next_badge and is_exam:
		next_badge.visible = false


func _refresh_chrome() -> void:
	var show_lock := not is_exam and not _unlocked
	if lock_icon:
		lock_icon.visible = show_lock
	if next_badge:
		next_badge.visible = _is_next

	var fill := CREAM if _unlocked or is_exam else CREAM_LOCKED
	var border := BORDER_SOFT
	var border_w := BORDER_NORMAL
	if is_exam:
		border = PURPLE_BORDER
		border_w = BORDER_FOCUS
		fill = fill.lerp(Color(0.72, 0.62, 0.85, 1.0), 0.12)
	elif _is_next:
		border = GREEN_BORDER
		border_w = BORDER_FOCUS
		fill = fill.lerp(Color(0.72, 0.82, 0.62, 1.0), 0.18)

	add_theme_stylebox_override("normal", _make_box(fill, border, border_w))
	add_theme_stylebox_override("hover", _make_box(fill.lightened(0.03), border, border_w))
	add_theme_stylebox_override("pressed", _make_box(fill.darkened(0.04), border, border_w))
	add_theme_stylebox_override("disabled", _make_box(CREAM_LOCKED, BORDER_SOFT, BORDER_NORMAL))
	add_theme_stylebox_override("focus", _make_box(fill, border, border_w))
	add_theme_constant_override("outline_size", 0)
	_refresh_inner_frame(border)

	if text_lable:
		text_lable.add_theme_color_override("font_color", GRAPHITE)
		text_lable.modulate.a = 1.0 if _unlocked else 0.85
	if exam_title:
		exam_title.add_theme_color_override("font_color", PURPLE_TEXT)
		exam_title.modulate.a = 1.0
	if exam_hint:
		exam_hint.add_theme_color_override("font_color", GRAPHITE)
		exam_hint.modulate.a = 1.0


func _refresh_inner_frame(outer_border: Color) -> void:
	if inner_frame == null:
		return
	var inner_col := INNER_SOFT
	if is_exam:
		inner_col = INNER_PURPLE
	elif _is_next:
		inner_col = INNER_GREEN
	elif not _unlocked:
		inner_col = Color(0.165, 0.2, 0.251, 0.18)
	# Slightly echo the outer accent so the double line reads as one frame.
	inner_col = inner_col.lerp(outer_border, 0.35)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = inner_col
	style.set_border_width_all(INNER_BORDER)
	style.set_corner_radius_all(INNER_CORNER)
	style.anti_aliasing = true
	inner_frame.add_theme_stylebox_override("panel", style)


func _make_box(bg: Color, border: Color, border_w: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(CORNER)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 8
	style.content_margin_bottom = 6
	style.shadow_color = Color(0.15, 0.12, 0.08, 0.18)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	return style
