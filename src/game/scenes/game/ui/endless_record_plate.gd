extends Control

## Endless battle: «НОВЫЙ РЕКОРД!» plate pops once the survived time passes the profile best
## (`GameConfig.endless_best_sec`; only when there was a record to beat), holds, then fades.

@export var game_events: GameEvents
@export var card: Control
@export var subtitle: Label
@export var subtitle_format: String = "Прежний рекорд: %s"
@export var hold_seconds: float = 2.5

var _listener: EventListener = EventListener.new()
var _best: int = 0
var _shown: bool = false


func initialize(game_config: GameConfig) -> void:
	visible = false
	_listener.clear()
	_shown = false
	if game_config == null or not game_config.endless or game_config.endless_best_sec <= 0:
		return
	_best = game_config.endless_best_sec
	if game_events:
		_listener.add(game_events.ev_endless_time, _on_endless_time)


func _exit_tree() -> void:
	_listener.deinit()


func _on_endless_time(seconds: int) -> void:
	if _shown or seconds <= _best:
		return
	_shown = true
	subtitle.text = tr(subtitle_format) % ProgressStatistics.format_clock(_best)
	visible = true
	modulate.a = 1.0
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(card, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", -0.04, 0.12)
	tween.tween_property(card, "rotation", 0.04, 0.12)
	tween.tween_property(card, "rotation", 0.0, 0.12)
	tween.tween_interval(hold_seconds)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(hide)
