extends IScene

## Controls intro context — HFSM state `App/ControlsIntro` (parallel to Menu/Battle), opened by AppRoot
## once per app session. First battle of the session: holds the countdown (`GameEvents.ev_hold_countdown`)
## and shows how to play — touch: left half drag = move, right half tap = shoot; keys: arrows + space / click.
## Any tap / key → touch cards fly into the HUD corner hints (`HUD/TouchHints`), keys card fades; countdown
## resumes; the state closes itself (`ev.close_controls_intro`). Skipped (still used up) while the tutorial
## coaches the first flight. The battle knows nothing about it — only shared `GameEvents`.

@export var game_events: GameEvents
@export var progress: ProgressController
## Tutorial chapter whose battle already teaches the controls — no intro until it's done.
@export var coached_step_id: String = "first_flight"

@export_group("Nodes")
@export var overlay: CanvasLayer
@export var root: Control
@export var touch_nodes: Array[Control] = []
@export var key_nodes: Array[Control] = []
## Fade out on dismiss (touch: the rest flies into the corners).
@export var fade_nodes: Array[Control] = []
@export var move_pill: Control
@export var move_finger: Control
@export var shoot_disc: Control
@export var shoot_finger: Control
@export var arrows_key: Control
@export var space_key: Control
@export var mouse_icon: Control
@export var move_caption: Label
@export var shoot_caption: Label
@export var start_label: Label

@export_group("Texts")
@export_multiline var move_text_touch: String = "Веди пальцем вверх и вниз —\nсамолёт полетит за ним"
@export_multiline var move_text_keys: String = "Стрелки ВВЕРХ и ВНИЗ —\nсамолёт летит за ними"
@export_multiline var shoot_text_touch: String = "Нажми в любом месте\nсправа — выстрел!"
@export_multiline var shoot_text_keys: String = "ПРОБЕЛ или клик\nмышкой — выстрел!"
@export var start_text_touch: String = "Нажми, чтобы начать"
@export var start_text_keys: String = "Нажми любую клавишу или кликни, чтобы начать"

@export_group("Tuning")
## Let the battle loading screen slide away first.
@export var appear_delay: float = 0.5
@export var appear_seconds: float = 0.3
## Taps right after appearing are ignored (a second tap after «Играть» must not skip it).
@export var input_delay: float = 0.6
@export var fly_seconds: float = 0.5
## Centers of the HUD corner hints (`HUD/TouchHints`): x from left / right edge, y from bottom.
@export var move_corner: Vector2 = Vector2(68.0, -100.0)
@export var shoot_corner: Vector2 = Vector2(-100.0, -100.0)
@export var move_corner_scale: float = 0.67
@export var shoot_corner_scale: float = 0.67
@export var finger_travel: float = 70.0

var _listener: EventListener = EventListener.new()
var _used: bool = false
var _holding: bool = false
var _showing: bool = false
var _accepting: bool = false
var _touch: bool = true
var _tweens: Array[Tween] = []


func _ready() -> void:
	overlay.visible = false
	root.gui_input.connect(_on_root_gui_input)
	super._ready()


func initialize(_data: Dictionary) -> void:
	_listener.add(game_events.ev_countdown_entered, _on_countdown_entered)
	if _is_isolated_run():
		_show()


func deinit() -> void:
	_listener.deinit()
	_kill_tweens()
	_release()
	super.deinit()


func _on_countdown_entered() -> void:
	if _used:
		return
	_used = true
	if _is_coached():
		_close()
		return
	_holding = true
	game_events.ev_hold_countdown.emit(true)
	_show()


func _is_coached() -> bool:
	return (
		progress != null and not progress.is_tutorial_completed()
		and not progress.is_tutorial_step_done(coached_step_id)
	)


func _show() -> void:
	_touch = AirPlane.is_touch_scheme()
	for node in touch_nodes:
		node.visible = _touch
	for node in key_nodes:
		node.visible = not _touch
	move_caption.text = move_text_touch if _touch else move_text_keys
	shoot_caption.text = shoot_text_touch if _touch else shoot_text_keys
	start_label.text = start_text_touch if _touch else start_text_keys
	overlay.visible = true
	root.modulate.a = 0.0
	_showing = true
	_accepting = false
	_start_loops.call_deferred()
	var tween := _track(create_tween())
	tween.tween_interval(appear_delay)
	tween.tween_property(root, "modulate:a", 1.0, appear_seconds)
	tween.tween_interval(input_delay)
	tween.tween_callback(func() -> void: _accepting = true)


## Looping demo: finger steers / taps (touch) or keys press (keyboard); «start» line breathes.
func _start_loops() -> void:
	for node: Control in [move_pill, move_finger, shoot_disc, shoot_finger, arrows_key, space_key, mouse_icon]:
		node.pivot_offset = node.size * 0.5
	if _touch:
		var y0: float = move_finger.position.y
		var steer := _track(create_tween().set_loops())
		steer.tween_property(move_finger, "position:y", y0 - finger_travel, 0.6).set_trans(Tween.TRANS_SINE)
		steer.tween_property(move_finger, "position:y", y0 + finger_travel, 1.2).set_trans(Tween.TRANS_SINE)
		steer.tween_property(move_finger, "position:y", y0, 0.6).set_trans(Tween.TRANS_SINE)
		_press_loop(shoot_finger, shoot_disc)
	else:
		_press_loop(arrows_key, null)
		_press_loop(space_key, mouse_icon)
	var breathe := _track(create_tween().set_loops())
	breathe.tween_property(start_label, "modulate:a", 0.45, 0.7)
	breathe.tween_property(start_label, "modulate:a", 1.0, 0.7)


func _press_loop(node: Control, echo: Control) -> void:
	var tween := _track(create_tween().set_loops())
	tween.tween_property(node, "scale", Vector2.ONE * 0.85, 0.1)
	if echo:
		tween.parallel().tween_property(echo, "scale", Vector2.ONE * 0.85, 0.1)
	tween.tween_property(node, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if echo:
		tween.parallel().tween_property(echo, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.55)


func _on_root_gui_input(event: InputEvent) -> void:
	var pressed: bool = (
		(event is InputEventMouseButton and event.pressed)
		or (event is InputEventScreenTouch and event.pressed)
	)
	if pressed:
		root.accept_event()
		_dismiss()


## Keyboard / gamepad: any key starts the battle.
func _input(event: InputEvent) -> void:
	if not _showing:
		return
	if (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		_dismiss()


func _dismiss() -> void:
	if not _showing or not _accepting:
		return
	_showing = false
	_accepting = false
	_release()
	_kill_tweens()
	var tween := _track(create_tween().set_parallel(true))
	if _touch:
		for node in fade_nodes:
			tween.tween_property(node, "modulate:a", 0.0, fly_seconds * 0.5)
		var view: Vector2 = root.size
		_fly(tween, move_pill, Vector2(move_corner.x, view.y + move_corner.y), move_corner_scale)
		_fly(tween, shoot_disc, Vector2(view.x + shoot_corner.x, view.y + shoot_corner.y), shoot_corner_scale)
	else:
		tween.tween_property(root, "modulate:a", 0.0, fly_seconds * 0.6)
	tween.chain().tween_callback(_close)


func _fly(tween: Tween, node: Control, center: Vector2, to_scale: float) -> void:
	node.scale = Vector2.ONE
	tween.tween_property(node, "global_position", center - node.size * 0.5, fly_seconds) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", Vector2.ONE * to_scale, fly_seconds) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "modulate:a", 0.0, fly_seconds * 0.3).set_delay(fly_seconds * 0.8)


func _release() -> void:
	if not _holding:
		return
	_holding = false
	game_events.ev_hold_countdown.emit(false)


func _close() -> void:
	overlay.visible = false
	add_event("ev.close_controls_intro")


func _track(tween: Tween) -> Tween:
	_tweens.append(tween)
	return tween


func _kill_tweens() -> void:
	for tween in _tweens:
		if tween and tween.is_valid():
			tween.kill()
	_tweens.clear()
