class_name BattleTips
extends Node

## One-shot battle tips inside the tutorial context — shown the first time the player meets something new.
## Talks to the battle only via shared `GameEvents`: listens `ev_answers_spawned` / `ev_boss_*`,
## commands `ev_pause_answers` / `ev_lock_shoot` (missing-operand tip waits for «Понятно!» / shoot key).
## Parent passes still-unseen tip ids (`set_pending`); signals up `ev_tip_shown(tip_id)` once shown.

signal ev_tip_shown(tip_id: String)

const TIP_MISSING_OPERAND := "tip_missing_operand"
const TIP_BOSS := "tip_boss"
const TIP_BOSS_RAGE := "tip_boss_rage"
const TIPS: Array[String] = [TIP_MISSING_OPERAND, TIP_BOSS, TIP_BOSS_RAGE]

@export var game_events: GameEvents
@export var anchors: UiAnchorRegistry
@export var question_anchor_id: String = "battle.question"
@export var boss_anchor_id: String = "battle.boss"
@export var hint: TutorialHint

@export_group("Texts")
@export_multiline var missing_operand_text: String = "Новый пример! Одно число спряталось.\nКакое число стоит вместо «?»"
@export var missing_operand_button: String = "Понятно!"
@export_multiline var boss_text: String = "Дирижабль! Каждый верный ответ\nсбивает с него одну броню"
@export_multiline var boss_rage_text: String = "Он разозлился и летит к тебе!\nСтреляй прямо в дирижабль!"

@export_group("Tuning")
## Boss tips hide after this many seconds (or on the next boss hit/shot).
@export var boss_tip_seconds: float = 4.0

var _listener: EventListener = EventListener.new()
var _pending: Array[String] = []
var _blocking: bool = false
var _hide_tween: Tween


func _ready() -> void:
	hint.set_active(false)
	hint.ev_button_pressed.connect(_release)
	set_process_input(false)
	_listener.add(game_events.ev_game_state_changed, _on_game_state_changed)
	_listener.add(game_events.ev_answers_spawned, _on_answers_spawned)
	_listener.add(game_events.ev_boss_appeared, _on_boss_appeared)
	_listener.add(game_events.ev_boss_hit, _on_boss_progress)
	_listener.add(game_events.ev_boss_enraged, _on_boss_enraged)
	_listener.add(game_events.ev_boss_shot, _on_boss_progress)


func _exit_tree() -> void:
	stop()
	_listener.deinit()


## Parent sets which tips are still unseen (empty = all off).
func set_pending(tip_ids: Array[String]) -> void:
	_pending = tip_ids.duplicate()


## Hide the tip and release battle commands (battle left / restarted / tips disarmed).
func stop() -> void:
	_release()
	_hide()


func _on_game_state_changed(_from_state: String, to_state: String) -> void:
	if to_state != GameState.get_state():
		stop()


func _on_answers_spawned(_answers: Array, _correct_value: int, _lanes: Array, missing_operand: bool) -> void:
	if not missing_operand or not _take(TIP_MISSING_OPERAND):
		return
	_blocking = true
	game_events.ev_pause_answers.emit(true)
	game_events.ev_lock_shoot.emit(true)
	set_process_input(true)
	_show(question_anchor_id, missing_operand_text, missing_operand_button, 0.0)


func _on_boss_appeared(_armor: int) -> void:
	if _take(TIP_BOSS):
		_show(boss_anchor_id, boss_text, "", boss_tip_seconds)


func _on_boss_enraged(_hits: int) -> void:
	if _take(TIP_BOSS_RAGE):
		_show(boss_anchor_id, boss_rage_text, "", boss_tip_seconds)


## A boss tip is read once the player acts on it.
func _on_boss_progress(_left: int) -> void:
	if not _blocking:
		_hide()


func _take(tip_id: String) -> bool:
	if _blocking or not _pending.has(tip_id):
		return false
	_pending.erase(tip_id)
	ev_tip_shown.emit(tip_id)
	return true


func _show(anchor_id: String, message: String, button: String, seconds: float) -> void:
	_kill_hide_tween()
	hint.set_active(false)
	hint.point_at(anchors.get_control(anchor_id), Vector2(0.5, 1.0), true, message, button)
	hint.set_active(true)
	if seconds > 0.0:
		_hide_tween = create_tween()
		_hide_tween.tween_interval(seconds)
		_hide_tween.tween_callback(_hide)


func _release() -> void:
	set_process_input(false)
	if not _blocking:
		return
	_blocking = false
	game_events.ev_pause_answers.emit(false)
	game_events.ev_lock_shoot.emit(false)
	_hide()


func _hide() -> void:
	_kill_hide_tween()
	hint.set_active(false)


func _kill_hide_tween() -> void:
	if _hide_tween:
		_hide_tween.kill()
		_hide_tween = null


## Keyboard players confirm the blocking tip with the shoot key.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_release()
