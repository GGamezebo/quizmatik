class_name BattleCoach
extends Node

## First-battle coaching inside the tutorial context: goal / move / shoot hints while `GameState` runs.
## Listens to shared `GameEvents` only (no battle node refs); goal hint aims at the `goal_anchor_id` anchor.
## Signals up: `ev_goal_reached` on first correct answer, `ev_finished` after the praise flash.

signal ev_goal_reached
signal ev_finished

@export var game_events: GameEvents
@export var anchors: UiAnchorRegistry
@export var goal_anchor_id: String = "battle.question"

@export_group("Hints")
@export var goal_hint: TutorialHint
@export var move_hint: TutorialHint
@export var shoot_hint: TutorialHint
@export var feedback_hint: TutorialHint
## Touch only: marks the left (move) / right (shoot) screen halves.
@export var touch_divider: CanvasItem

@export_group("Texts")
@export_multiline var goal_text: String = "Реши пример и сбей шарик\nс правильным ответом!"
@export_multiline var move_text_touch: String = "Веди пальцем слева —\nсамолёт летит вверх и вниз"
@export_multiline var move_text_keys: String = "Стрелки ВВЕРХ и ВНИЗ —\nуправляй самолётом"
@export_multiline var shoot_text_touch: String = "Нажимай справа —\nвыстрел!"
@export_multiline var shoot_text_keys: String = "ПРОБЕЛ — выстрел!"
@export_multiline var mistake_text: String = "Не тот ответ!\nИщи правильный"
@export_multiline var success_text: String = "Отлично! Так держать!"

@export_group("Timing")
## Seconds of held movement input before the move hint hides.
@export var move_seconds_to_learn: float = 0.8
@export var mistake_seconds: float = 1.6
@export var success_seconds: float = 2.0

var _listener: EventListener = EventListener.new()
var _running: bool = false
var _done: bool = false
var _moved_seconds: float = 0.0
var _touch_on_left_half: bool = false
var _feedback_tween: Tween


func _ready() -> void:
	stop()
	feedback_hint.set_active(false)
	_listener.add(game_events.ev_game_state_changed, _on_game_state_changed)
	_listener.add(game_events.ev_shoot, _on_shoot)
	_listener.add(game_events.ev_correct_answer, _on_correct_answer)
	_listener.add(game_events.ev_mistake, _on_mistake)


func _exit_tree() -> void:
	_listener.deinit()


## Hide running hints (battle left / restarted). Praise flash keeps playing.
func stop() -> void:
	_running = false
	set_process(false)
	goal_hint.set_active(false)
	move_hint.set_active(false)
	shoot_hint.set_active(false)
	touch_divider.visible = false


func _on_game_state_changed(_from_state: String, to_state: String) -> void:
	if to_state == GameState.get_state():
		_start()
	elif _running:
		stop()


func _start() -> void:
	if _done:
		return
	var is_touch := AirPlane.is_touch_scheme()
	goal_hint.point_at(anchors.get_control(goal_anchor_id), Vector2(0.5, 1.0), true, goal_text)
	move_hint.text = move_text_touch if is_touch else move_text_keys
	shoot_hint.text = shoot_text_touch if is_touch else shoot_text_keys
	touch_divider.visible = is_touch
	goal_hint.set_active(true)
	move_hint.set_active(true)
	shoot_hint.set_active(true)
	_moved_seconds = 0.0
	_running = true
	set_process(true)


func _process(delta: float) -> void:
	if not move_hint.is_active() or not _is_move_input_held():
		return
	_moved_seconds += delta
	if _moved_seconds >= move_seconds_to_learn:
		move_hint.set_active(false)


func _is_move_input_held() -> bool:
	if AirPlane.is_touch_scheme():
		return _touch_on_left_half
	return Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down")



func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var half: float = get_viewport().get_visible_rect().size.x * AirPlane.SCREEN_SPLIT_RATIO
		var pressed: bool = event is InputEventScreenDrag or (event as InputEventScreenTouch).pressed
		_touch_on_left_half = pressed and event.position.x < half


func _on_shoot() -> void:
	if _running:
		shoot_hint.set_active(false)


func _on_mistake() -> void:
	if _running:
		_flash(mistake_text, mistake_seconds)


func _on_correct_answer() -> void:
	if not _running:
		return
	_done = true
	stop()
	ev_goal_reached.emit()
	_flash(success_text, success_seconds, true)


func _flash(message: String, seconds: float, then_finish: bool = false) -> void:
	feedback_hint.text = message
	feedback_hint.set_active(true)
	if _feedback_tween:
		_feedback_tween.kill()
	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(seconds)
	_feedback_tween.tween_callback(feedback_hint.set_active.bind(false))
	if then_finish:
		_feedback_tween.tween_callback(ev_finished.emit)
