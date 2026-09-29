class_name SpotlightDim
extends ColorRect

## Full-screen dim with "holes" over the UI the player must use.
## Clicks/taps outside holes are swallowed (`_has_point`); inside holes they reach the UI below.
## Optionally swallows keyboard/gamepad `ui_*` actions unless focus is inside the followed control.
## Holes: static rects (`set_rects`) or following a Control (`follow`). Draw hints above this node.

const MAX_HOLES := 4
const UI_ACTIONS: Array[StringName] = [
	&"ui_accept", &"ui_select", &"ui_cancel", &"ui_focus_next", &"ui_focus_prev",
	&"ui_left", &"ui_right", &"ui_up", &"ui_down",
]

@export var fade_seconds: float = 0.25
## Swallow `ui_*` actions while active (menus). Keep off in battle so movement keys work.
@export var block_ui_keys: bool = true

var _active: bool = false
var _rects: Array[Rect2] = []
var _follow: Control
var _follow_norm: Rect2 = Rect2(0, 0, 1, 1)
var _follow_margin: float = 0.0
var _fade: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	modulate.a = 0.0
	resized.connect(_push_uniforms)
	set_process(false)
	set_process_input(false)


## Holes in screen (canvas) pixels. Empty → full dim, nothing clickable.
func set_rects(rects: Array[Rect2]) -> void:
	_follow = null
	_rects = rects.slice(0, MAX_HOLES)
	_push_uniforms()


## One hole tracking `control` (sub-rect `norm` 0..1 of its rect, grown by `margin`).
func follow(control: Control, norm: Rect2 = Rect2(0, 0, 1, 1), margin: float = 12.0) -> void:
	_follow = control
	_follow_norm = norm
	_follow_margin = margin
	_update_follow()


func set_active(value: bool) -> void:
	if value == _active:
		return
	_active = value
	set_process(value)
	set_process_input(value)
	if _fade:
		_fade.kill()
	_fade = create_tween()
	if value:
		visible = true
		_push_uniforms()
		_fade.tween_property(self, "modulate:a", 1.0, fade_seconds)
	else:
		_fade.tween_property(self, "modulate:a", 0.0, fade_seconds)
		_fade.tween_callback(hide)


func is_active() -> bool:
	return _active


func _process(_delta: float) -> void:
	if _follow != null:
		_update_follow()


func _update_follow() -> void:
	if _follow == null or not is_instance_valid(_follow):
		_rects = []
	else:
		var r := _follow.get_global_rect()
		var sub := Rect2(r.position + r.size * _follow_norm.position, r.size * _follow_norm.size)
		_rects = [sub.grow(_follow_margin)]
	_push_uniforms()


func _to_local_rect(r: Rect2) -> Rect2:
	var inv := get_global_transform().affine_inverse()
	return Rect2(inv * r.position, r.size)


func _push_uniforms() -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		return
	var packed: Array[Vector4] = []
	for r in _rects:
		var l := _to_local_rect(r)
		packed.append(Vector4(l.position.x, l.position.y, l.size.x, l.size.y))
	while packed.size() < MAX_HOLES:
		packed.append(Vector4.ZERO)
	mat.set_shader_parameter("rect_size", size)
	mat.set_shader_parameter("hole_count", mini(_rects.size(), MAX_HOLES))
	mat.set_shader_parameter("holes", packed)


func _has_point(point: Vector2) -> bool:
	if not _active:
		return false
	for r in _rects:
		if _to_local_rect(r).has_point(point):
			return false
	return true


func _input(event: InputEvent) -> void:
	if not block_ui_keys or not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	for action in UI_ACTIONS:
		if event.is_action(action):
			if action in [&"ui_accept", &"ui_select"] and _focus_inside_follow():
				return
			get_viewport().set_input_as_handled()
			return


func _focus_inside_follow() -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	return focus != null and _follow != null and is_instance_valid(_follow) and (focus == _follow or _follow.is_ancestor_of(focus))
