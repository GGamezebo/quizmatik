extends HBoxContainer

## Battle progress in the score frame: «score / max», a countdown «0:45» on timed levels,
## or seconds survived «2:15» in the endless battle.

@export var player: Player
@export var game_config: GameConfig
@export var game_events: GameEvents
@export var score: Label
@export var maxScore: Label
@export var separator: Control
@export var time_left: Label
@export var time_icon: TextureRect
## Endless counts up → stopwatch; timed levels keep the scene clock (countdown).
@export var endless_time_texture: Texture2D
@export var time_warning_sec: int = 10
@export var time_warning_color: Color = Color(0.70, 0.28, 0.26, 1.0)
## Clock + time must fit inside the frame: the time font shrinks for «10:00» / «1:05:30».
@export var frame_padding: float = 30.0
@export var time_min_font_size: int = 20

var _time_color: Color
var _time_font_size: int = 42
var _countdown_texture: Texture2D


func _ready() -> void:
	_time_color = time_left.get_theme_color("font_color") if time_left else Color.BLACK
	_time_font_size = time_left.get_theme_font_size("font_size")
	if time_icon:
		_countdown_texture = time_icon.texture
	resized.connect(_fit_time)
	_refresh_mode()
	game_config.changed.connect(_refresh_mode)
	score.text = str(player.score)
	player.ev_score_changed.connect(_on_score_changed)
	if game_events:
		game_events.ev_time_left.connect(_on_time_left)
		game_events.ev_endless_time.connect(_on_endless_time)


func _exit_tree() -> void:
	if game_events and game_events.ev_time_left.is_connected(_on_time_left):
		game_events.ev_time_left.disconnect(_on_time_left)
	if game_events and game_events.ev_endless_time.is_connected(_on_endless_time):
		game_events.ev_endless_time.disconnect(_on_endless_time)


func _refresh_mode() -> void:
	var timed: bool = game_config.is_timed() or game_config.endless
	score.visible = not timed
	separator.visible = not timed
	maxScore.visible = not timed
	time_left.visible = timed
	if time_icon:
		time_icon.visible = timed
		if game_config.endless and endless_time_texture:
			time_icon.texture = endless_time_texture
		else:
			time_icon.texture = _countdown_texture
	maxScore.text = str(game_config.questions_count)
	if game_config.endless:
		_on_endless_time(0)
	elif timed:
		_on_time_left(ceili(game_config.time_limit_sec))


func _on_score_changed(new_score: int) -> void:
	score.text = str(new_score)


func _on_endless_time(seconds: int) -> void:
	time_left.text = ProgressStatistics.format_clock(seconds)
	time_left.add_theme_color_override("font_color", _time_color)
	_fit_time()


func _on_time_left(seconds: int) -> void:
	time_left.text = ProgressStatistics.format_clock(seconds)
	time_left.add_theme_color_override("font_color", time_warning_color if seconds <= time_warning_sec else _time_color)
	_fit_time()


## Largest font size (≤ scene size) at which icon + gap + time fit the frame width.
func _fit_time() -> void:
	if time_left == null or size.x <= 0.0:
		return
	var font: Font = time_left.get_theme_font("font")
	var icon_width: float = time_icon.get_combined_minimum_size().x if time_icon and time_icon.visible else 0.0
	var available: float = size.x - frame_padding * 2.0 - icon_width - float(get_theme_constant("separation"))
	var font_size: int = _time_font_size
	while font_size > time_min_font_size 			and font.get_string_size(time_left.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available:
		font_size -= 2
	time_left.add_theme_font_size_override("font_size", font_size)
