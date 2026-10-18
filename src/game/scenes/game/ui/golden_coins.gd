extends HBoxContainer

## Golden flight HUD chip (in place of the hearts): gold caught so far. Hidden in other battles.

@export var game_events: GameEvents
@export var count_label: Label

var _coins: int = 0
var _listener: EventListener = EventListener.new()


func initialize(game_config: GameConfig) -> void:
	visible = game_config != null and game_config.golden_flight
	_coins = 0
	if count_label:
		count_label.text = "0"
	if visible and game_events:
		_listener.add(game_events.ev_bonus_collected, _on_bonus_collected)


func _exit_tree() -> void:
	_listener.deinit()


func _on_bonus_collected(amount: int) -> void:
	_coins += amount
	if count_label == null:
		return
	count_label.text = str(_coins)
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.3, 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
