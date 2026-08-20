class_name LevelContainer
extends Control

signal ev_pressed

@export var card_root: Control
@export var card_bg: TextureRect
@export var art_rect: TextureRect
@export var stamp_rect: TextureRect
@export var title_label: Label
@export var progress_label: Label
@export var lock_overlay: Control
@export var hit_button: BaseButton

var _container_id: String = ""


func _ready() -> void:
	if hit_button != null:
		hit_button.pressed.connect(_on_hit_pressed)


func initialize(
	container_id: String,
	title: String,
	is_unlocked: bool,
	completed_count: int,
	total_count: int,
	exam_stars: int = 0,
) -> void:
	_container_id = container_id

	var art := LevelPackArt.get_art(container_id)
	if art != null and art_rect != null:
		art_rect.texture = art

	var clamped_exam_stars := clampi(exam_stars, 0, 3)
	var stamp := LevelPackArt.get_exam_stamp(clamped_exam_stars)
	if stamp_rect != null:
		if clamped_exam_stars >= 1 and stamp != null:
			stamp_rect.texture = stamp
			stamp_rect.visible = true
		else:
			stamp_rect.texture = null
			stamp_rect.visible = false

	if title_label != null:
		title_label.text = title
		# Rubik Doodle Shadow already has baked shadow contours — never add outline.
		title_label.add_theme_constant_override("outline_size", 0)
		if is_unlocked:
			title_label.add_theme_color_override("font_color", Color(0.165, 0.2, 0.251, 1))
		else:
			title_label.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62, 1))

	if progress_label != null:
		progress_label.text = "%d / %d" % [completed_count, total_count]
		progress_label.visible = is_unlocked

	if lock_overlay != null:
		lock_overlay.visible = not is_unlocked

	if art_rect != null:
		art_rect.modulate = Color.WHITE if is_unlocked else Color(0.72, 0.72, 0.72, 1.0)

	if card_root != null:
		card_root.modulate = Color.WHITE if is_unlocked else Color(0.88, 0.88, 0.88, 1.0)

	if hit_button != null:
		hit_button.disabled = not is_unlocked


func get_container_id() -> String:
	return _container_id


func ignore_pointer_input() -> void:
	_ignore_pointer_recursive(self)


func _ignore_pointer_recursive(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control:
			_ignore_pointer_recursive(child)


func _on_hit_pressed() -> void:
	ev_pressed.emit()
