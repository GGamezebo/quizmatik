class_name PanelButton
extends PanelContainer

signal pressed

@export var drag_cancel_distance: float = 24.0
@export var label: Label

var _text: String = ""
var text: String = "":
	get:
		return _text
	set(value):
		_text = value
		if label:
			label.text = value

var _disabled: bool = false
var disabled: bool = false:
	get:
		return _disabled
	set(value):
		_disabled = value
		mouse_filter = MOUSE_FILTER_IGNORE if _disabled else MOUSE_FILTER_STOP
		_update_visual_state()

var _pointer_down: bool = false
var _dragging: bool = false
var _press_position: Vector2 = Vector2.ZERO

var _style_normal: StyleBox
var _style_hover: StyleBox
var _style_pressed: StyleBox
var _style_disabled: StyleBox


func _ready() -> void:
	_cache_theme_styles()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if text and label:
		label.text = text
	_update_visual_state()


func _cache_theme_styles() -> void:
	_style_normal = get_theme_stylebox(&"normal", &"Button")
	_style_hover = get_theme_stylebox(&"hover", &"Button")
	_style_pressed = get_theme_stylebox(&"pressed", &"Button")
	if _style_normal:
		_style_disabled = _style_normal.duplicate()
		if _style_disabled is StyleBoxFlat:
			var flat := _style_disabled as StyleBoxFlat
			flat.bg_color = flat.bg_color.darkened(0.4)
			flat.border_color = flat.border_color.darkened(0.25)


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(event.pressed, event.position)
	elif event is InputEventScreenTouch:
		_handle_pointer(event.pressed, event.position)
	elif event is InputEventMouseMotion and _pointer_down:
		_handle_drag(event.relative, event.position)
	elif event is InputEventScreenDrag and _pointer_down:
		_handle_drag(event.relative, event.position)


func _handle_pointer(is_pressed: bool, local_position: Vector2) -> void:
	if is_pressed:
		_pointer_down = true
		_dragging = false
		_press_position = local_position
		_apply_style(_style_pressed)
		return

	if _pointer_down and not _dragging:
		pressed.emit()

	_pointer_down = false
	_dragging = false
	_update_visual_state()


func _handle_drag(relative: Vector2, local_position: Vector2) -> void:
	if not _dragging and local_position.distance_to(_press_position) > drag_cancel_distance:
		_dragging = true
		_update_visual_state()

	if not _dragging:
		return

	_scroll_parent(relative)
	accept_event()


func _scroll_parent(relative: Vector2) -> void:
	var scroll := _find_scroll_container()
	if scroll == null:
		return

	var h_bar := scroll.get_h_scroll_bar()
	scroll.scroll_horizontal = clampi(
		scroll.scroll_horizontal - int(relative.x),
		0,
		int(h_bar.max_value),
	)


func _on_mouse_entered() -> void:
	if not disabled and not _pointer_down:
		_apply_style(_style_hover)


func _on_mouse_exited() -> void:
	if not _pointer_down:
		_update_visual_state()


func _update_visual_state() -> void:
	if disabled:
		modulate = Color(0.7, 0.7, 0.7, 1.0)
		_apply_style(_style_disabled if _style_disabled else _style_normal)
		return

	modulate = Color.WHITE
	if _pointer_down and not _dragging:
		_apply_style(_style_pressed)
	elif get_global_rect().has_point(get_global_mouse_position()):
		_apply_style(_style_hover)
	else:
		_apply_style(_style_normal)


func _apply_style(style: StyleBox) -> void:
	if style:
		add_theme_stylebox_override(&"panel", style)


func _find_scroll_container() -> ScrollContainer:
	var node: Node = get_parent()
	while node:
		if node is ScrollContainer:
			return node as ScrollContainer
		node = node.get_parent()
	return null
