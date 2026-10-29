class_name FlightModeCoach
extends Node

## Lanes flight mode (HUD button right of the sound one) coached once inside the tutorial context
## (late chapter `ProgressController.FLIGHT_MODE_INTRO_STEP`): first round of campaign level `level_id`, any valley.
## Talks to the battle only via shared `GameEvents` + the shared `UserSettings` the HUD mode button writes:
## listens `ev_answers_spawned` / `ev_plane_lane_changed` / `ev_lanes_changed` / `ev_correct_answer` /
## `UserSettings.ev_changed`, commands `ev_pause_answers` / `ev_lock_shoot`.
##
## Stages: answers appear → SWITCH (world frozen, hint at the mode button) → TRY (lanes on: fly up and down)
## → AIM (correct balloon lit; shooting only in its lane) → RESTORE (world still frozen, hint at the button:
## back to the old mode, the choice stays the player's) → DONE (praise, world goes on).
## Already flying on lanes → this battle is skipped and does not count as seen. The flag is saved the moment
## the hint is first shown, so leaving mid-way never replays it. Battle left mid-way → the old mode is put back.
## Signals up: `ev_goal_reached` when the hint is shown, `ev_finished` after the praise.

signal ev_goal_reached
signal ev_finished

enum Stage { IDLE, WAIT_ANSWERS, SWITCH, TRY, AIM, RESTORE, DONE }

@export var game_events: GameEvents
@export var user_settings: UserSettings
@export var anchors: UiAnchorRegistry
@export var button_anchor_id: String = "battle.movement_mode"
@export var goal_anchor_id: String = "battle.question"
@export var dim: SpotlightDim
## Campaign level (any valley, never the exam) whose first round is coached.
@export var level_id: int = 4

@export_group("Hints")
## Points at the mode button (SWITCH, RESTORE).
@export var button_hint: TutorialHint
## Points at the question banner during AIM.
@export var goal_hint: TutorialHint
## Step instruction (no arrow), bottom of the screen.
@export var coach_hint: TutorialHint
@export var feedback_hint: TutorialHint

@export_group("Texts")
@export_multiline var switch_text: String = "Мир замер — открою тебе секрет асов!\nЭта кнопка ставит самолёт на дорожки:\nон летит ровно вдоль них\nи бьёт без промаха. Нажми её!"
@export_multiline var try_text_touch: String = "Теперь самолёт сам встаёт точно на дорожку!\nВеди пальцем вверх и вниз — попробуй"
@export_multiline var try_text_keys: String = "Теперь самолёт сам встаёт точно на дорожку!\nЖми ВВЕРХ и ВНИЗ — попробуй"
@export_multiline var goal_text: String = "Реши пример — ответ\nна подсвеченном шарике!"
@export_multiline var aim_text: String = "Встань напротив\nподсвеченного шарика"
@export_multiline var shoot_text_touch: String = "Ровно напротив — промаха не будет!\nНажми на правую половину экрана — огонь!"
@export_multiline var shoot_text_keys: String = "Ровно напротив — промаха не будет!\nЖми ПРОБЕЛ или кликни мышкой — огонь!"
@export_multiline var restore_text: String = "В яблочко! А теперь вернём всё\nна свои места — нажми кнопку ещё раз.\nКак летать дальше — выбирай сам!"
@export_multiline var success_text: String = "Всё как было!\nА выбор — за тобой, пилот"

@export_group("Tuning")
@export var success_seconds: float = 2.6
@export var hole_margin: float = 6.0

var _listener: EventListener = EventListener.new()
var _armed: bool = false
var _level_matches: bool = false
var _stage: Stage = Stage.IDLE
var _start_mode: int = AirPlane.MovementMode.DIRECT
var _correct_lane: int = -1
var _lanes: Array = []
var _plane_lane: int = -1
var _plane_centered: bool = false
var _went_up: bool = false
var _went_down: bool = false
var _feedback_tween: Tween


func _ready() -> void:
	_listener.add(game_events.ev_game_state_changed, _on_game_state_changed)
	_listener.add(game_events.ev_answers_spawned, _on_answers_spawned)
	_listener.add(game_events.ev_plane_lane_changed, _on_plane_lane_changed)
	_listener.add(game_events.ev_lanes_changed, _on_lanes_changed)
	_listener.add(game_events.ev_correct_answer, _on_correct_answer)
	_listener.add(user_settings.ev_changed, _on_settings_changed)


func _exit_tree() -> void:
	stop()
	_listener.deinit()


## Parent enables coaching while the flight-mode intro is pending.
func arm(value: bool) -> void:
	if value and not _armed and _stage == Stage.DONE:
		_stage = Stage.IDLE
	_armed = value
	if not value:
		stop()


## Parent passes every battle start's campaign info (null = practice / mode battle).
func set_battle(battle_info: GameConfig.BattleInfo) -> void:
	_level_matches = battle_info != null and not battle_info.is_exam and battle_info.level_id == level_id


## Abort coaching (battle left / restarted): old mode back, battle commands released, hints hidden.
func stop() -> void:
	var coaching := _stage in [Stage.SWITCH, Stage.TRY, Stage.AIM, Stage.RESTORE]
	if _stage != Stage.DONE:
		_stage = Stage.IDLE
	if not coaching:
		return
	game_events.ev_pause_answers.emit(false)
	game_events.ev_lock_shoot.emit(false)
	_hide_hints()
	if user_settings.movement_mode != _start_mode:
		user_settings.movement_mode = _start_mode
		user_settings.save()


func _on_game_state_changed(_from_state: String, to_state: String) -> void:
	if to_state == GameState.get_state():
		if _armed and _level_matches and _stage == Stage.IDLE:
			_stage = Stage.WAIT_ANSWERS
	elif _stage != Stage.DONE:
		stop()


func _on_answers_spawned(answers: Array, correct_value: int, lanes: Array, missing_operand: bool) -> void:
	if _stage != Stage.WAIT_ANSWERS or missing_operand or lanes.is_empty():
		return
	if user_settings.movement_mode == AirPlane.MovementMode.DISCRETE:
		_stage = Stage.IDLE
		return
	var correct: Answer = null
	for answer: Answer in answers:
		if answer.value == correct_value:
			correct = answer
	if correct == null or anchors.get_visible(button_anchor_id) == null:
		return
	_lanes = lanes
	_correct_lane = correct.lane_index
	_start_mode = user_settings.movement_mode
	game_events.ev_pause_answers.emit(true)
	_enter_switch()


func _enter_switch() -> void:
	_stage = Stage.SWITCH
	game_events.ev_lock_shoot.emit(true)
	goal_hint.set_active(false)
	coach_hint.set_active(false)
	_point_at_button(switch_text)
	## Seen once — never shown again, even if this battle is left before the praise.
	ev_goal_reached.emit()


func _enter_try() -> void:
	_stage = Stage.TRY
	_went_up = false
	_went_down = false
	button_hint.set_active(false)
	dim.set_rects([_plane_zone()])
	_show_coach(try_text_touch if AirPlane.is_touch_scheme() else try_text_keys)


func _enter_aim() -> void:
	_stage = Stage.AIM
	goal_hint.point_at(anchors.get_control(goal_anchor_id), Vector2(0.5, 1.0), true, goal_text)
	goal_hint.set_active(true)
	dim.set_rects(_aim_holes())
	_update_aim()


func _enter_restore() -> void:
	_stage = Stage.RESTORE
	game_events.ev_lock_shoot.emit(true)
	goal_hint.set_active(false)
	coach_hint.set_active(false)
	_point_at_button(restore_text)


func _finish() -> void:
	_stage = Stage.DONE
	game_events.ev_pause_answers.emit(false)
	game_events.ev_lock_shoot.emit(false)
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


## The HUD mode button saved a new mode.
func _on_settings_changed() -> void:
	var switched := user_settings.movement_mode != _start_mode
	match _stage:
		Stage.SWITCH:
			if switched:
				_enter_try()
		Stage.TRY, Stage.AIM:
			if not switched:
				_enter_switch()
		Stage.RESTORE:
			if not switched:
				_finish()


## Up and down at least once each → AIM.
func _on_plane_lane_changed(lane: int, centered: bool) -> void:
	if _stage == Stage.TRY and _plane_lane >= 0 and lane != _plane_lane:
		if lane < _plane_lane:
			_went_up = true
		else:
			_went_down = true
	_plane_lane = lane
	_plane_centered = centered
	match _stage:
		Stage.TRY:
			if _went_up and _went_down:
				_enter_aim()
		Stage.AIM:
			_update_aim()


func _on_correct_answer() -> void:
	if _stage == Stage.AIM:
		_enter_restore()


## Window resized mid-coaching: re-cut the spotlight holes for the new lanes (button holes follow by themselves).
func _on_lanes_changed(lanes: Array) -> void:
	if lanes.is_empty():
		return
	_lanes = lanes
	match _stage:
		Stage.TRY:
			dim.set_rects([_plane_zone()])
		Stage.AIM:
			dim.set_rects(_aim_holes())


## Shooting only once lined up with the lit balloon; the instruction follows.
func _update_aim() -> void:
	var aligned := _plane_lane == _correct_lane and _plane_centered
	game_events.ev_lock_shoot.emit(not aligned)
	var message := aim_text
	if aligned:
		message = shoot_text_touch if AirPlane.is_touch_scheme() else shoot_text_keys
	_show_coach(message)


func _point_at_button(message: String) -> void:
	var button := anchors.get_control(button_anchor_id)
	button_hint.set_active(false)
	button_hint.point_at(button, Vector2(0.5, 1.0), true, message)
	button_hint.set_active(true)
	dim.follow(button, Rect2(0, 0, 1, 1), hole_margin)
	dim.set_active(true)


func _show_coach(message: String) -> void:
	if coach_hint.text == message and coach_hint.is_active():
		return
	coach_hint.set_active(false)
	coach_hint.text = message
	coach_hint.set_active(true)


func _hide_hints() -> void:
	button_hint.set_active(false)
	goal_hint.set_active(false)
	coach_hint.set_active(false)
	dim.set_active(false)


func _aim_holes() -> Array[Rect2]:
	var holes: Array[Rect2] = [_plane_zone(), _lane_rect(_correct_lane)]
	var banner := anchors.get_control(goal_anchor_id)
	if banner != null:
		holes.append(banner.get_global_rect().grow(hole_margin))
	return holes


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
