extends Control

## Timed level intro: when the countdown starts (`ev_countdown_started`, after any hold) a clock card pops up («Продержись 60 секунд!»),
## then flies into the HUD timer clock when the battle starts. Hidden on regular levels.

@export var game_events: GameEvents
@export var card: Control
@export var clock: Control
@export var caption: Label
## HUD clock next to the countdown — the card shrinks into it.
@export var fly_target: Control
@export var pop_duration: float = 0.45
@export var fly_duration: float = 0.55

var _listener: EventListener = EventListener.new()
var _wobble: Tween


func initialize(game_config: GameConfig) -> void:
	visible = false
	if game_config == null or not game_config.is_timed():
		return
	var seconds: int = ceili(game_config.time_limit_sec)
	var caption_format: String = "Золотой полёт: %d %s!" if game_config.golden_flight else "Продержись %d %s!"
	# Whole minutes from 2 on («10 минут»), else seconds («60 секунд»).
	@warning_ignore("integer_division")
	var minutes: int = seconds / 60
	if seconds >= 120 and seconds % 60 == 0:
		caption.text = tr(caption_format) % [minutes, tr(_minutes_word(minutes))]
	else:
		caption.text = tr(caption_format) % [seconds, tr(_seconds_word(seconds))]
	if game_events:
		_listener.add(game_events.ev_game_state_changed, _on_game_state_changed)
		_listener.add(game_events.ev_countdown_started, _pop_in)


func _exit_tree() -> void:
	_listener.deinit()


func _pop_in() -> void:
	visible = true
	modulate.a = 1.0
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(card, "scale", Vector2.ONE, pop_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	clock.pivot_offset = clock.size * 0.5
	_wobble = create_tween().set_loops()
	_wobble.tween_property(clock, "rotation", 0.12, 0.09)
	_wobble.tween_property(clock, "rotation", -0.12, 0.09)
	_wobble.tween_property(clock, "rotation", 0.0, 0.09)
	_wobble.tween_interval(0.5)


func _on_game_state_changed(_from_state: String, to_state: String) -> void:
	if to_state == FSMGameStates.GAME and visible:
		_fly_away()


func _fly_away() -> void:
	if _wobble:
		_wobble.kill()
	clock.rotation = 0.0
	var target_scale := 0.15
	var end_pos: Vector2 = card.global_position
	if fly_target:
		var target_center: Vector2 = fly_target.global_position + fly_target.size * 0.5
		end_pos = target_center - card.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(card, "global_position", end_pos, fly_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(card, "scale", Vector2(target_scale, target_scale), fly_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, fly_duration * 0.4).set_delay(fly_duration * 0.6)
	tween.chain().tween_callback(hide)


## Key «секунду» / «секунды» / «секунд» for the active language's plural rule.
static func _seconds_word(n: int) -> String:
	return GameLocale.plural(n, "секунду", "секунды", "секунд")


## Key «минута» / «минуты» / «минут» for the active language's plural rule.
static func _minutes_word(n: int) -> String:
	return GameLocale.plural(n, "минута", "минуты", "минут")
