extends Control

## HUD chip «СЕРИЯ ×N»: visible from `streak_feedback_min` correct answers in a row.

@export var player: Player
@export var game_config: GameConfig
@export var label: Label
@export var text_format: String = "СЕРИЯ ×%d"

var _tween: Tween


func _ready() -> void:
	visible = false
	pivot_offset = size / 2.0
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	if player:
		player.ev_streak_changed.connect(_on_streak_changed)


func _on_streak_changed(streak: int) -> void:
	var min_streak: int = game_config.streak_feedback_min if game_config else 3
	if streak < min_streak:
		_hide()
		return
	label.text = tr(text_format) % streak
	visible = true
	_pop()


func _pop() -> void:
	if _tween:
		_tween.kill()
	modulate.a = 1.0
	scale = Vector2(1.35, 1.35)
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.3)


func _hide() -> void:
	if not visible:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_tween.tween_callback(func() -> void: visible = false)
