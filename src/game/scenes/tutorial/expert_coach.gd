class_name ExpertCoach
extends Node

## First expert round coached inside the tutorial context (late chapter `ProgressController.EXPERT_INTRO_STEP`).
## Talks to the battle only via shared `GameEvents`: listens `ev_pair_spawned` / `ev_pair_pick` / `ev_pair_result` /
## `ev_plane_lane_changed`, commands `ev_pause_answers` / `ev_lock_shoot`.
##
## Stages: pair round appears → EXPLAIN (balloons frozen, banner hint + «Понятно!» / shoot key) → FIRST (lane of the
## first hidden number lit; shooting unlocked only in it) → SECOND (same for the second) → DONE (praise).
## Signals up: `ev_goal_reached` on the solved round, `ev_finished` after the praise.

signal ev_goal_reached
signal ev_finished

enum Stage { IDLE, WAIT_ROUND, EXPLAIN, FIRST, SECOND, DONE }

@export var game_events: GameEvents
@export var anchors: UiAnchorRegistry
@export var goal_anchor_id: String = "battle.question"
@export var dim: SpotlightDim

@export_group("Hints")
## Points at the question banner during EXPLAIN (with the button).
@export var goal_hint: TutorialHint
## Step instruction (no arrow), bottom of the screen.
@export var coach_hint: TutorialHint
@export var feedback_hint: TutorialHint

@export_group("Texts")
@export_multiline var explain_text: String = "Испытание эксперта! Спрятались два числа.\nСбей два шарика: сначала первое, потом второе"
@export var explain_button: String = "Понятно!"
@export_multiline var first_text: String = "Первое число — %d.\nВстань напротив шарика и стреляй!"
@export_multiline var second_text: String = "Теперь второе число — %d.\nСтреляй!"
@export_multiline var success_text: String = "Пример решён! Дальше — сам"

@export_group("Tuning")
@export var success_seconds: float = 2.2
@export var hole_margin: float = 6.0

var _listener: EventListener = EventListener.new()
var _armed: bool = false
var _stage: Stage = Stage.IDLE
var _pair: Array = []
var _pair_lanes: Array[int] = [-1, -1]
var _lanes: Array = []
var _plane_lane: int = -1
var _plane_centered: bool = false
var _feedback_tween: Tween


func _ready() -> void:
	_hide_hints()
	set_process_input(false)
	goal_hint.ev_button_pressed.connect(_on_explain_confirmed)
	_listener.add(game_events.ev_game_state_changed, _on_game_state_changed)
	_listener.add(game_events.ev_pair_spawned, _on_pair_spawned)
	_listener.add(game_events.ev_pair_pick, _on_pair_pick)
	_listener.add(game_events.ev_pair_result, _on_pair_result)
	_listener.add(game_events.ev_plane_lane_changed, _on_plane_lane_changed)
	_listener.add(game_events.ev_lanes_changed, _on_lanes_changed)


func _exit_tree() -> void:
	stop()
	_listener.deinit()


## Parent enables coaching while the expert intro is pending.
func arm(value: bool) -> void:
	if value and not _armed and _stage == Stage.DONE:
		_stage = Stage.IDLE
	_armed = value
	if not value:
		stop()


## Abort coaching (battle left / restarted): release battle commands, hide everything but praise.
func stop() -> void:
	if _stage in [Stage.EXPLAIN, Stage.FIRST, Stage.SECOND]:
		game_events.ev_pause_answers.emit(false)
		game_events.ev_lock_shoot.emit(false)
	if _stage != Stage.DONE:
		_stage = Stage.IDLE
	set_process_input(false)
	_hide_hints()


func _on_game_state_changed(_from_state: String, to_state: String) -> void:
	if to_state == GameState.get_state():
		if _armed and _stage == Stage.IDLE:
			_stage = Stage.WAIT_ROUND
	elif _stage != Stage.DONE:
		stop()


func _on_pair_spawned(answers: Array, pair: Array, lanes: Array) -> void:
	if _stage != Stage.WAIT_ROUND or pair.size() < 2 or lanes.is_empty():
		return
	_pair = pair
	_lanes = lanes
	_pair_lanes = [-1, -1]
	for answer: Answer in answers:
		for slot in 2:
			if _pair_lanes[slot] < 0 and answer.value == pair[slot] and answer.lane_index != _pair_lanes[1 - slot]:
				_pair_lanes[slot] = answer.lane_index
	if _pair_lanes.has(-1):
		return
	game_events.ev_pause_answers.emit(true)
	game_events.ev_lock_shoot.emit(true)
	_stage = Stage.EXPLAIN
	goal_hint.point_at(anchors.get_control(goal_anchor_id), Vector2(0.5, 1.0), true, explain_text, explain_button)
	goal_hint.set_active(true)
	dim.set_rects(_holes(-1))
	dim.set_active(true)
	set_process_input(true)


func _on_explain_confirmed() -> void:
	if _stage != Stage.EXPLAIN:
		return
	set_process_input(false)
	goal_hint.set_active(false)
	_enter_aim(Stage.FIRST)


func _enter_aim(stage: Stage) -> void:
	_stage = stage
	dim.set_rects(_holes(_target_lane()))
	_update_aim(true)


func _on_pair_pick(slot: int, _value: int, _from_global: Vector2) -> void:
	if _stage == Stage.FIRST and slot == 0:
		_enter_aim(Stage.SECOND)


func _on_pair_result(correct: bool, _solution: String) -> void:
	if _stage not in [Stage.FIRST, Stage.SECOND]:
		return
	_stage = Stage.DONE
	game_events.ev_pause_answers.emit(false)
	game_events.ev_lock_shoot.emit(false)
	_hide_hints()
	ev_goal_reached.emit()
	if not correct:
		ev_finished.emit()
		return
	feedback_hint.text = success_text
	feedback_hint.set_active(true)
	if _feedback_tween:
		_feedback_tween.kill()
	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(success_seconds)
	_feedback_tween.tween_callback(feedback_hint.set_active.bind(false))
	_feedback_tween.tween_callback(ev_finished.emit)


func _on_plane_lane_changed(lane: int, centered: bool) -> void:
	_plane_lane = lane
	_plane_centered = centered
	if _stage in [Stage.FIRST, Stage.SECOND]:
		_update_aim(false)


## Window resized mid-coaching: re-cut the spotlight holes for the new lanes.
func _on_lanes_changed(lanes: Array) -> void:
	if lanes.is_empty():
		return
	_lanes = lanes
	match _stage:
		Stage.EXPLAIN:
			dim.set_rects(_holes(-1))
		Stage.FIRST, Stage.SECOND:
			dim.set_rects(_holes(_target_lane()))


func _target_lane() -> int:
	return _pair_lanes[0 if _stage == Stage.FIRST else 1]


## Shooting only once lined up with the lit balloon; the instruction follows the stage.
func _update_aim(force_text: bool) -> void:
	var aligned := _plane_lane == _target_lane() and _plane_centered
	game_events.ev_lock_shoot.emit(not aligned)
	var message: String = tr(first_text if _stage == Stage.FIRST else second_text) % _pair[0 if _stage == Stage.FIRST else 1]
	if force_text or coach_hint.text != message or not coach_hint.is_active():
		coach_hint.set_active(false)
		coach_hint.text = message
		coach_hint.set_active(true)


## Plane zone + banner, plus lane `lane` (EXPLAIN: both pair lanes).
func _holes(lane: int) -> Array[Rect2]:
	var holes: Array[Rect2] = [_plane_zone()]
	if lane >= 0:
		holes.append(_lane_rect(lane))
	else:
		holes.append(_lane_rect(_pair_lanes[0]))
		holes.append(_lane_rect(_pair_lanes[1]))
	var banner := anchors.get_control(goal_anchor_id)
	if banner != null:
		holes.append(banner.get_global_rect().grow(hole_margin))
	return holes


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


## Keyboard players confirm the explanation with the shoot key.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_on_explain_confirmed()
