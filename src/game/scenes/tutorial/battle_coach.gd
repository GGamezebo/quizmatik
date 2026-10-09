class_name BattleCoach
extends Node

## First-battle coaching inside the tutorial context. Talks to the battle only via shared `GameEvents`:
## listens `ev_answers_spawned` / `ev_plane_lane_changed` / `ev_correct_answer`,
## commands `ev_pause_answers` / `ev_lock_shoot`. No battle node refs are stored across rounds.
##
## Stages: answers appear → PAUSE + MOVE (practice up/down, balloons frozen)
## → AIM (correct balloon lit; shooting unlocked only in its lane, so the first shot is right) → DONE.
## Signals up: `ev_goal_reached` on the coached correct hit, `ev_finished` after the praise flash.

signal ev_goal_reached
signal ev_finished

enum Stage { IDLE, WAIT_ANSWERS, MOVE, AIM, DONE }

@export var game_events: GameEvents
@export var anchors: UiAnchorRegistry
@export var goal_anchor_id: String = "battle.question"
@export var dim: SpotlightDim

@export_group("Hints")
## Points at the question banner during AIM.
@export var goal_hint: TutorialHint
## Main instruction (no arrow), bottom of the screen.
@export var coach_hint: TutorialHint
@export var feedback_hint: TutorialHint

@export_group("Texts")
@export_multiline var move_text_touch: String = "Пауза! Сначала научимся летать.\nВеди пальцем по левой половине экрана вверх и вниз"
@export_multiline var move_text_keys: String = "Пауза! Сначала научимся летать.\nЖми стрелки ВВЕРХ и ВНИЗ"
@export_multiline var goal_text: String = "Реши пример — ответ\nна подсвеченном шарике!"
@export_multiline var aim_text: String = "Встань напротив\nподсвеченного шарика"
@export_multiline var shoot_text_touch: String = "Отлично! Теперь нажми\nна правую половину экрана — выстрел!"
@export_multiline var shoot_text_keys: String = "Отлично! Теперь жми ПРОБЕЛ\nили кликни мышкой — выстрел!"
@export_multiline var success_text: String = "Попал! Так держать!"

@export_group("Tuning")
## Seconds of held movement input (or one lane change) before AIM.
@export var move_seconds_to_learn: float = 0.8
@export var success_seconds: float = 2.0
@export var hole_margin: float = 6.0

var _listener: EventListener = EventListener.new()
var _armed: bool = false
var _stage: Stage = Stage.IDLE
var _correct: Answer
var _correct_lane: int = -1
var _lanes: Array = []
var _plane_lane: int = -1
var _plane_centered: bool = false
var _moved_seconds: float = 0.0
var _touch_on_left_half: bool = false
var _feedback_tween: Tween


func _ready() -> void:
	_hide_hints()
	feedback_hint.set_active(false)
	set_process(false)
	_listener.add(game_events.ev_game_state_changed, _on_game_state_changed)
	_listener.add(game_events.ev_answers_spawned, _on_answers_spawned)
	_listener.add(game_events.ev_plane_lane_changed, _on_plane_lane_changed)
	_listener.add(game_events.ev_lanes_changed, _on_lanes_changed)
	_listener.add(game_events.ev_correct_answer, _on_correct_answer)


func _exit_tree() -> void:
	stop()
	_listener.deinit()


## Parent enables coaching while the first-flight chapter is pending.
func arm(value: bool) -> void:
	_armed = value
	if not value:
		stop()


## Abort coaching (battle left / restarted): release battle commands, hide everything but praise.
func stop() -> void:
	if _stage in [Stage.MOVE, Stage.AIM]:
		game_events.ev_pause_answers.emit(false)
		game_events.ev_lock_shoot.emit(false)
	if _stage != Stage.DONE:
		_stage = Stage.IDLE
	_correct = null
	set_process(false)
	_hide_hints()


func _on_game_state_changed(_from_state: String, to_state: String) -> void:
	if to_state == GameState.get_state():
		if _armed and _stage == Stage.IDLE:
			_stage = Stage.WAIT_ANSWERS
	elif _stage != Stage.DONE:
		stop()


func _on_plane_lane_changed(lane: int, centered: bool) -> void:
	if _stage == Stage.MOVE and _plane_lane >= 0 and lane != _plane_lane:
		_moved_seconds = move_seconds_to_learn
	_plane_lane = lane
	_plane_centered = centered
	if _stage == Stage.AIM:
		_update_aim()


## Window resized mid-coaching: re-cut the spotlight holes for the new lanes.
func _on_lanes_changed(lanes: Array) -> void:
	if lanes.is_empty():
		return
	_lanes = lanes
	match _stage:
		Stage.MOVE:
			dim.set_rects([_plane_zone()])
		Stage.AIM:
			dim.set_rects(_aim_holes())


func _on_answers_spawned(answers: Array, correct_value: int, lanes: Array, _missing_operand: bool) -> void:
	if _stage != Stage.WAIT_ANSWERS:
		return
	_lanes = lanes
	_correct = null
	for answer: Answer in answers:
		if answer.value == correct_value:
			_correct = answer
	if _correct == null or lanes.is_empty():
		return
	_correct_lane = _correct.lane_index
	game_events.ev_pause_answers.emit(true)
	game_events.ev_lock_shoot.emit(true)
	_enter_move()


func _enter_move() -> void:
	_stage = Stage.MOVE
	_moved_seconds = 0.0
	dim.set_rects([_plane_zone()])
	dim.set_active(true)
	coach_hint.text = move_text_touch if AirPlane.is_touch_scheme() else move_text_keys
	coach_hint.set_active(true)
	set_process(true)


func _enter_aim() -> void:
	_stage = Stage.AIM
	coach_hint.set_active(false)
	var banner := anchors.get_control(goal_anchor_id)
	goal_hint.point_at(banner, Vector2(0.5, 1.0), true, goal_text)
	goal_hint.set_active(true)
	dim.set_rects(_aim_holes())
	_update_aim()


func _aim_holes() -> Array[Rect2]:
	var holes: Array[Rect2] = [_plane_zone(), _lane_rect(_correct_lane)]
	var banner := anchors.get_control(goal_anchor_id)
	if banner != null:
		holes.append(banner.get_global_rect().grow(hole_margin))
	return holes


func _update_aim() -> void:
	var aligned := _plane_lane == _correct_lane and _plane_centered
	game_events.ev_lock_shoot.emit(not aligned)
	var message := aim_text
	if aligned:
		message = shoot_text_touch if AirPlane.is_touch_scheme() else shoot_text_keys
	if coach_hint.text != message or not coach_hint.is_active():
		coach_hint.set_active(false)
		coach_hint.text = message
		coach_hint.set_active(true)


func _process(delta: float) -> void:
	if _stage != Stage.MOVE:
		return
	if _is_move_input_held():
		_moved_seconds += delta
	if _moved_seconds >= move_seconds_to_learn:
		_enter_aim()


func _on_correct_answer() -> void:
	if _stage != Stage.AIM:
		return
	_stage = Stage.DONE
	game_events.ev_pause_answers.emit(false)
	game_events.ev_lock_shoot.emit(false)
	set_process(false)
	_hide_hints()
	ev_goal_reached.emit()
	feedback_hint.text = success_text
	feedback_hint.set_active(true)
	if _feedback_tween:
		_feedback_tween.kill()
	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(success_seconds)
	_feedback_tween.tween_callback(feedback_hint.set_active.bind(false))
	_feedback_tween.tween_callback(ev_finished.emit)


func _hide_hints() -> void:
	goal_hint.set_active(false)
	coach_hint.set_active(false)
	dim.set_active(false)


## Left half over all lanes — where the plane flies.
func _plane_zone() -> Rect2:
	var top: Rect2 = _lanes[0]
	var bottom: Rect2 = _lanes[_lanes.size() - 1]
	var half := dim.get_viewport_rect().size.x * AirPlane.SCREEN_SPLIT_RATIO
	return Rect2(0.0, top.position.y, half, bottom.end.y - top.position.y).grow(hole_margin)


func _lane_rect(lane: int) -> Rect2:
	var r: Rect2 = _lanes[clampi(lane, 0, _lanes.size() - 1)]
	var width := dim.get_viewport_rect().size.x
	return Rect2(0.0, r.position.y, width, r.size.y).grow(hole_margin)


func _is_move_input_held() -> bool:
	if AirPlane.is_touch_scheme():
		return _touch_on_left_half
	return Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down")


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var half: float = get_viewport().get_visible_rect().size.x * AirPlane.SCREEN_SPLIT_RATIO
		var pressed: bool = event is InputEventScreenDrag or (event as InputEventScreenTouch).pressed
		_touch_on_left_half = pressed and event.position.x < half
