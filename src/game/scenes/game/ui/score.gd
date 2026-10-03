extends HBoxContainer

## Battle progress in the score frame: «score / max», or a countdown «0:45» on timed levels.

@export var player: Player
@export var game_config: GameConfig
@export var game_events: GameEvents
@export var score: Label
@export var maxScore: Label
@export var separator: Control
@export var time_left: Label
@export var time_icon: Control
@export var time_warning_sec: int = 10
@export var time_warning_color: Color = Color(0.70, 0.28, 0.26, 1.0)

var _time_color: Color


func _ready() -> void:
	_time_color = time_left.get_theme_color("font_color") if time_left else Color.BLACK
	_refresh_mode()
	game_config.changed.connect(_refresh_mode)
	score.text = str(player.score)
	player.ev_score_changed.connect(_on_score_changed)
	if game_events:
		game_events.ev_time_left.connect(_on_time_left)


func _exit_tree() -> void:
	if game_events and game_events.ev_time_left.is_connected(_on_time_left):
		game_events.ev_time_left.disconnect(_on_time_left)


func _refresh_mode() -> void:
	var timed: bool = game_config.is_timed()
	score.visible = not timed
	separator.visible = not timed
	maxScore.visible = not timed
	time_left.visible = timed
	if time_icon:
		time_icon.visible = timed
	maxScore.text = str(game_config.questions_count)
	if timed:
		_on_time_left(ceili(game_config.time_limit_sec))


func _on_score_changed(new_score: int) -> void:
	score.text = str(new_score)


func _on_time_left(seconds: int) -> void:
	@warning_ignore("integer_division")
	time_left.text = "%d:%02d" % [seconds / 60, seconds % 60]
	time_left.add_theme_color_override("font_color", time_warning_color if seconds <= time_warning_sec else _time_color)
