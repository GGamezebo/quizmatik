class_name TutorialHint
extends Control

## Tutorial pointer: ink arrow + semi-transparent cloud bubble, bobbing toward a point.
## Root position = arrow tip. With `target`, tip follows `target` rect at `anchor_point`.
## Never blocks input (all mouse_filter = IGNORE). Parent decides when to `set_active`.
## Project-agnostic: font face from the parent theme; colors/size from `style` (TutorialHintStyle).

const ARROW_HEIGHT := 48.0
const BOB_DISTANCE := 10.0
const BOB_SECONDS := 0.55

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

var _active: bool = false
var _bob_tween: Tween
var _pop_tween: Tween


func _ready() -> void:
	label.text = text
	label.custom_minimum_size.x = bubble_width
	arrow.visible = show_arrow
	_apply_style()
	## Autowrapped label settles its height after the first sort — re-fit (shrink too) every time.
	bubble.minimum_size_changed.connect(_layout, CONNECT_DEFERRED)
	_layout()
	_active = active_on_ready
	_apply_active()


func set_active(value: bool) -> void:
	if value == _active:
		return
	_active = value
	_apply_active()


func is_active() -> bool:
	return _active


## Re-aim at runtime (null target → stays at its own position). Re-pops if active.
func point_at(new_target: Control, new_anchor_point: Vector2, new_points_up: bool, new_text: String) -> void:
	target = new_target
	anchor_point = new_anchor_point
	points_up = new_points_up
	text = new_text
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
	cloud.position = bubble.position
	cloud.size = bubble_size
	var mat := cloud.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("rect_size", bubble_size)


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
