class_name AnimatedTitle
extends Control

## Per-letter title intro (fall + bounce) with optional idle hop wave.

enum IntroStyle { FALL_BOUNCE, HOP }

@export var title_text: String = "Улётная математика":
	set(value):
		title_text = value
		if is_node_ready():
			_rebuild_and_play()

@export var title_font: Font
@export var font_size: int = 58
@export var font_color: Color = Color(0.165, 0.2, 0.251, 1)
@export var intro_style: IntroStyle = IntroStyle.FALL_BOUNCE
@export_range(0.0, 0.3, 0.005) var letter_stagger: float = 0.055
@export var fall_distance: float = 150.0
@export_range(0.2, 1.5, 0.05) var fall_duration: float = 0.6
@export var letter_spacing: float = 2.0
@export var play_on_ready: bool = true
@export var replay_when_visible: bool = true
@export var idle_wave: bool = true
@export_range(0.0, 24.0, 1.0) var idle_hop_px: float = 7.0

var _row: HBoxContainer
var _glyphs: Array[Control] = []
var _intro_tween: Tween
var _idle_tweens: Array[Tween] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ensure_row()
	_rebuild()
	if play_on_ready and is_visible_in_tree():
		call_deferred("play_intro")
	if replay_when_visible:
		# Connect after first frame so the initial show does not double-play.
		call_deferred("_connect_visibility_replay")


func _connect_visibility_replay() -> void:
	if not visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)


func play_intro() -> void:
	if _glyphs.is_empty() or not is_visible_in_tree():
		return
	_stop_all_tweens()
	match intro_style:
		IntroStyle.FALL_BOUNCE:
			_play_fall_bounce()
		IntroStyle.HOP:
			_play_hop()


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		play_intro()
	else:
		_stop_all_tweens()


func _ensure_row() -> void:
	if _row != null:
		return
	_row = HBoxContainer.new()
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", int(letter_spacing))
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_row)


func _rebuild_and_play() -> void:
	_rebuild()
	play_intro()


func _rebuild() -> void:
	_stop_all_tweens()
	_ensure_row()
	_row.add_theme_constant_override("separation", int(letter_spacing))
	for child in _row.get_children():
		child.queue_free()
	_glyphs.clear()

	var font := title_font
	if font == null:
		font = get_theme_default_font()

	var total_w := 0.0
	var max_h := 0.0
	for i in title_text.length():
		var ch := title_text.substr(i, 1)
		var cell := _make_glyph_cell(ch, font)
		_row.add_child(cell)
		_glyphs.append(cell)
		total_w += cell.custom_minimum_size.x
		max_h = maxf(max_h, cell.custom_minimum_size.y)

	if _glyphs.size() > 1:
		total_w += letter_spacing * float(_glyphs.size() - 1)
	custom_minimum_size = Vector2(total_w, max_h)


func _make_glyph_cell(ch: String, font: Font) -> Control:
	var metrics := font.get_string_size(ch if ch != " " else "А", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	if ch == " ":
		metrics.x = maxf(metrics.x * 0.45, font_size * 0.28)

	var cell := Control.new()
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.custom_minimum_size = metrics
	cell.clip_contents = false

	if ch != " ":
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text = ch
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if font:
			label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", font_color)
		label.add_theme_constant_override("outline_size", 0)
		# Top-left anchors so position tweens are not overridden by layout.
		label.position = Vector2.ZERO
		label.size = metrics
		label.pivot_offset = metrics * 0.5
		cell.add_child(label)
		cell.set_meta("glyph", label)
	return cell


func _glyph_visual(cell: Control) -> Control:
	if cell.has_meta("glyph"):
		return cell.get_meta("glyph") as Control
	return null


func _stop_all_tweens() -> void:
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_tween = null
	for tw in _idle_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_idle_tweens.clear()


func _play_fall_bounce() -> void:
	_intro_tween = create_tween()
	_intro_tween.set_parallel(true)

	for i in _glyphs.size():
		var visual := _glyph_visual(_glyphs[i])
		if visual == null:
			continue
		var delay := letter_stagger * float(i)
		visual.position = Vector2(0.0, -fall_distance)
		visual.rotation = randf_range(-0.22, 0.22)
		visual.modulate.a = 0.0
		visual.scale = Vector2.ONE

		_intro_tween.tween_property(visual, "position:y", 0.0, fall_duration) \
			.set_delay(delay).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		_intro_tween.tween_property(visual, "rotation", 0.0, fall_duration) \
			.set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_intro_tween.tween_property(visual, "modulate:a", 1.0, fall_duration * 0.35) \
			.set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if idle_wave:
		_intro_tween.set_parallel(false)
		_intro_tween.chain().tween_callback(_start_idle_wave)


func _play_hop() -> void:
	_intro_tween = create_tween()
	_intro_tween.set_parallel(true)

	for i in _glyphs.size():
		var visual := _glyph_visual(_glyphs[i])
		if visual == null:
			continue
		var delay := letter_stagger * float(i)
		visual.position = Vector2.ZERO
		visual.rotation = 0.0
		visual.modulate.a = 1.0
		visual.scale = Vector2.ONE
		_intro_tween.tween_callback(_hop_glyph.bind(visual)).set_delay(delay)

	if idle_wave:
		var wait := letter_stagger * float(maxi(_glyphs.size() - 1, 0)) + 0.55
		_intro_tween.set_parallel(false)
		_intro_tween.chain().tween_interval(wait)
		_intro_tween.tween_callback(_start_idle_wave)


func _hop_glyph(visual: Control) -> void:
	var hop := create_tween()
	hop.tween_property(visual, "position:y", -idle_hop_px * 2.2, 0.14) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hop.tween_property(visual, "position:y", 0.0, 0.28) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_idle_tweens.append(hop)


func _start_idle_wave() -> void:
	for tw in _idle_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_idle_tweens.clear()
	if not idle_wave or idle_hop_px <= 0.0:
		return

	for i in _glyphs.size():
		var visual := _glyph_visual(_glyphs[i])
		if visual == null:
			continue
		var tw := create_tween().set_loops()
		tw.tween_interval(0.08 * float(i))
		tw.tween_property(visual, "position:y", -idle_hop_px, 0.16) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(visual, "position:y", 0.0, 0.26) \
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_interval(2.1)
		_idle_tweens.append(tw)
