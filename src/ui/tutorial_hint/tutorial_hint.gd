class_name TutorialHint
extends Control

## Optional confirm button pressed (only when `button_text` is set).
signal ev_button_pressed

## Tutorial pointer: ink arrow + semi-transparent cloud bubble, bobbing toward a point.
## Root position = arrow tip. With `target`, tip follows `target` rect at `anchor_point`.
## Never blocks input (all mouse_filter = IGNORE). Parent decides when to `set_active`.
## Project-agnostic: font face from the parent theme; colors/size from `style` (TutorialHintStyle).

const ARROW_HEIGHT := 48.0
const BOB_DISTANCE := 10.0
const BOB_SECONDS := 0.55
## Min gap between the bubble and the screen edge (arrow tip never moves).
const SCREEN_MARGIN := 8.0

## Runtime-assignable (e.g. a spawned level tile). Set → hint positions itself globally.
@export var target: Control:
	set(value):
		target = value
		top_level = value != null
		if is_node_ready():
			set_process(_active and target != null)
## Point on the target rect (0..1) the arrow tip touches.
@export var anchor_point: Vector2 = Vector2(0.5, 0.0)
@export var points_up: bool = false
@export var show_arrow: bool = true
@export_multiline var text: String = "":
	set(value):
		text = value
		if label:
			label.text = value
@export var bubble_width: float = 300.0
## Non-empty → shows a confirm button under the text (the only clickable part of the hint).
@export var button_text: String = "":
	set(value):
		button_text = value
		if button:
			button.text = value
			button.visible = not value.is_empty()
@export var style: TutorialHintStyle
@export var active_on_ready: bool = false

@export_group("Nodes")
@export var body: Control
@export var arrow: Node2D
@export var bubble: Control
## Cloud backdrop (shader `cloud_bubble.gdshader`), kept on the bubble rect.
@export var cloud: Control
@export var arrow_outline: Line2D
@export var label: Label
@export var button: Button
## Optional gesture row. `GESTURE_MOVE` slides the finger; `GESTURE_SHOOT` taps it. Hidden otherwise.
@export var gestures: Control
@export var gesture_move: TextureRect
@export var gesture_finger_move: TextureRect
@export var gesture_shoot: TextureRect
@export var gesture_finger_shoot: TextureRect

const GESTURE_NONE := 0
const GESTURE_MOVE := 1
const GESTURE_SHOOT := 2
const _FINGER_TRAVEL := 22.0

var _active: bool = false
var _bob_tween: Tween
var _pop_tween: Tween
var _gesture_tween: Tween
var _gesture_mode: int = GESTURE_NONE
var _homes_ready: bool = false
var _move_finger_home := Vector2.ZERO
var _shoot_finger_home := Vector2.ZERO
## Unclamped bubble position from `_layout`; screen clamp must not stack on itself.
var _bubble_home := Vector2.ZERO


func _ready() -> void:
	label.text = text
	label.custom_minimum_size.x = bubble_width
	button.text = button_text
	button.visible = not button_text.is_empty()
	button.pressed.connect(ev_button_pressed.emit)
	arrow.visible = show_arrow
	_apply_style()
	## Autowrapped label settles its height after the first sort — re-fit (shrink too) every time.
	bubble.minimum_size_changed.connect(_layout, CONNECT_DEFERRED)
	_layout()
	_active = active_on_ready
	_apply_active()


## Art for the gesture row. Does not show it — `set_gesture_mode` does.
func set_gesture_art(move_texture: Texture2D, move_finger: Texture2D, shoot_texture: Texture2D, shoot_finger: Texture2D) -> void:
	if gesture_move != null:
		gesture_move.texture = move_texture
	if gesture_finger_move != null:
		gesture_finger_move.texture = move_finger
	if gesture_shoot != null:
		gesture_shoot.texture = shoot_texture
	if gesture_finger_shoot != null:
		gesture_finger_shoot.texture = shoot_finger


## `GESTURE_NONE` hides the row. `GESTURE_MOVE` shows the finger sliding up and down.
## `GESTURE_SHOOT` shows the finger tapping the shoot mark.
func set_gesture_mode(mode: int) -> void:
	if gestures == null or mode == _gesture_mode:
		return
	_gesture_mode = mode
	_ensure_homes()
	_stop_gesture_motion()
	gesture_move.get_parent().visible = mode == GESTURE_MOVE
	gesture_shoot.get_parent().visible = mode == GESTURE_SHOOT
	gestures.visible = mode != GESTURE_NONE
	if mode == GESTURE_MOVE:
		_slide_finger()
	elif mode == GESTURE_SHOOT:
		_tap_finger()
	_layout.call_deferred()


func set_active(value: bool) -> void:
	if value == _active:
		return
	_active = value
	_apply_active()


func is_active() -> bool:
	return _active


## Re-aim at runtime (null target → stays at its own position). Re-pops if active.
func point_at(new_target: Control, new_anchor_point: Vector2, new_points_up: bool, new_text: String, new_button_text: String = "") -> void:
	target = new_target
	anchor_point = new_anchor_point
	points_up = new_points_up
	text = new_text
	button_text = new_button_text
	_layout()
	if _active:
		_apply_active()


func _apply_active() -> void:
	body.visible = _active
	set_process(_active and target != null)
	if _bob_tween:
		_bob_tween.kill()
		_bob_tween = null
	if not _active:
		return
	_follow_target()
	_pop_in()
	_start_bob()


func _apply_style() -> void:
	if style == null:
		return
	var mat := cloud.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("fill_color", style.fill_color)
		mat.set_shader_parameter("edge_alpha", style.edge_alpha)
		mat.set_shader_parameter("core_alpha", style.core_alpha)
		mat.set_shader_parameter("outline_color", style.outline_color)
		mat.set_shader_parameter("outline_width", style.outline_width)
	(arrow as Polygon2D).color = style.arrow_color
	arrow_outline.default_color = style.arrow_outline_color
	label.add_theme_color_override("font_color", style.font_color)
	if style.font_size > 0:
		label.add_theme_font_size_override("font_size", style.font_size)
	label.add_theme_constant_override("line_spacing", style.line_spacing)


func _process(_delta: float) -> void:
	_follow_target()


func _follow_target() -> void:
	if target == null or not is_instance_valid(target):
		return
	var rect := target.get_global_rect()
	global_position = rect.position + rect.size * anchor_point
	_keep_bubble_on_screen()


func _layout() -> void:
	var bubble_size := bubble.get_combined_minimum_size()
	bubble.size = bubble_size
	var x := -bubble_size.x / 2.0
	if not show_arrow:
		bubble.position = Vector2(x, -bubble_size.y / 2.0)
	elif points_up:
		arrow.scale = Vector2(1.0, -1.0)
		bubble.position = Vector2(x, ARROW_HEIGHT - 4.0)
	else:
		arrow.scale = Vector2.ONE
		bubble.position = Vector2(x, -ARROW_HEIGHT + 4.0 - bubble_size.y)
	cloud.size = bubble_size
	var mat := cloud.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("rect_size", bubble_size)
	_bubble_home = bubble.position
	_keep_bubble_on_screen()


## Slide the bubble inside the viewport. Arrow hints only shift sideways (the tip stays on the target);
## a hint without an arrow also shifts up so a tall bubble is not cut off by the screen edge.
func _keep_bubble_on_screen() -> void:
	var width := bubble.size.x
	var left := global_position.x - width / 2.0
	var view_size := get_viewport_rect().size
	var shift := 0.0
	if left < SCREEN_MARGIN:
		shift = SCREEN_MARGIN - left
	elif left + width > view_size.x - SCREEN_MARGIN:
		shift = view_size.x - SCREEN_MARGIN - (left + width)
	bubble.position.x = -width / 2.0 + shift
	bubble.position.y = _bubble_home.y
	if not show_arrow:
		var height := bubble.size.y
		var top := global_position.y + _bubble_home.y
		var shift_y := 0.0
		if top < SCREEN_MARGIN:
			shift_y = SCREEN_MARGIN - top
		elif top + height > view_size.y - SCREEN_MARGIN:
			shift_y = view_size.y - SCREEN_MARGIN - (top + height)
		bubble.position.y = _bubble_home.y + shift_y
	cloud.position = bubble.position


func _ensure_homes() -> void:
	if _homes_ready or gesture_finger_move == null:
		return
	_homes_ready = true
	_move_finger_home = Vector2(gesture_finger_move.offset_left, gesture_finger_move.offset_top)
	_shoot_finger_home = Vector2(gesture_finger_shoot.offset_left, gesture_finger_shoot.offset_top)


func _slide_finger() -> void:
	var finger := gesture_finger_move
	finger.position = _move_finger_home
	var y0 := _move_finger_home.y
	_gesture_tween = create_tween().set_loops()
	_gesture_tween.tween_property(finger, "position:y", y0 - _FINGER_TRAVEL, 0.45).set_trans(Tween.TRANS_SINE)
	_gesture_tween.tween_property(finger, "position:y", y0 + _FINGER_TRAVEL, 0.9).set_trans(Tween.TRANS_SINE)
	_gesture_tween.tween_property(finger, "position:y", y0, 0.45).set_trans(Tween.TRANS_SINE)


func _tap_finger() -> void:
	var finger := gesture_finger_shoot
	var disc := gesture_shoot
	finger.pivot_offset = _pivot_of(finger)
	disc.pivot_offset = _pivot_of(disc)
	_gesture_tween = create_tween().set_loops()
	_gesture_tween.tween_property(finger, "scale", Vector2.ONE * 0.82, 0.1)
	_gesture_tween.parallel().tween_property(disc, "scale", Vector2.ONE * 0.9, 0.1)
	_gesture_tween.tween_property(finger, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gesture_tween.parallel().tween_property(disc, "scale", Vector2.ONE, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gesture_tween.tween_interval(0.45)


func _pivot_of(node: Control) -> Vector2:
	var bounds := node.size if node.size != Vector2.ZERO else node.custom_minimum_size
	return bounds * 0.5


func _stop_gesture_motion() -> void:
	if _gesture_tween and _gesture_tween.is_valid():
		_gesture_tween.kill()
	_gesture_tween = null
	if gesture_finger_move:
		gesture_finger_move.position = _move_finger_home
	if gesture_finger_shoot:
		gesture_finger_shoot.scale = Vector2.ONE
		gesture_finger_shoot.position = _shoot_finger_home
	if gesture_shoot:
		gesture_shoot.scale = Vector2.ONE


func _pop_in() -> void:
	if _pop_tween:
		_pop_tween.kill()
	body.scale = Vector2(0.6, 0.6)
	body.modulate.a = 0.0
	_pop_tween = create_tween().set_parallel(true)
	_pop_tween.tween_property(body, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop_tween.tween_property(body, "modulate:a", 1.0, 0.2)


func _start_bob() -> void:
	if not show_arrow:
		return
	## Bob away from the target and back.
	var away := BOB_DISTANCE if points_up else -BOB_DISTANCE
	body.position.y = 0.0
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(body, "position:y", away, BOB_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(body, "position:y", 0.0, BOB_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
