class_name MusicController
extends Node

## Swaps AppRoot MusicPlayer: menu background, battle / exam themes, boss fight, post-battle win/lose.
## Empty battle/exam slots fall back to background_music; empty boss slot keeps the battle theme.
## In battle (GameEvents): boss fly-in crossfades to boss_music; timed level's last seconds speed the
## music up; win / lose fades it out so the stingers are heard before the result theme.
## Endless battle: boss down → back to the battle theme; a new record plays the win theme.

@export var root_events: RootEvents
@export var game_events: GameEvents
@export var music_player: AudioStreamPlayer
@export var background_music: AudioStream
@export var battle_music: AudioStream
@export var exam_music: AudioStream
@export var boss_music: AudioStream
@export var win_music: AudioStream
@export var lose_music: AudioStream
@export var background_volume_db: float = -7.69
@export var result_volume_db: float = -5.0

@export_group("Battle")
@export var boss_fade_sec: float = 0.5
@export var end_fade_sec: float = 0.8
## Timed level: at this many seconds left (and below) the music plays faster / higher.
@export var hurry_seconds: int = 10
@export var hurry_pitch: float = 1.12

const _SILENT_DB := -40.0

var _listener: EventListener = EventListener.new()
var _playing_result: bool = false
var _faded: bool = false
var _tween: Tween = null
## Theme of the running battle (boss down → back to it).
var _battle_stream: AudioStream = null


func _ready() -> void:
	if root_events:
		_listener.add(root_events.ev_exit_game, _on_exit_game)
		_listener.add(root_events.ev_return_to_menu, _on_return_to_menu)
		_listener.add(root_events.ev_start_game, _on_start_game)
	if game_events:
		_listener.add(game_events.ev_boss_appeared, _on_boss_appeared)
		_listener.add(game_events.ev_boss_defeated, _on_boss_defeated)
		_listener.add(game_events.ev_time_left, _on_time_left)
		_listener.add(game_events.ev_win, _fade_out)
		_listener.add(game_events.ev_lose, _fade_out)
	_prepare_loops()


func _exit_tree() -> void:
	_listener.deinit()


func _prepare_loops() -> void:
	for stream in [win_music, lose_music, background_music, battle_music, exam_music, boss_music]:
		_enable_loop(stream)


func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true


func _on_exit_game(data: Dictionary = {}) -> void:
	var is_win: bool = bool(data.get("is_win", false)) or bool(data.get("is_record", false))
	_play_result(win_music if is_win else lose_music)


func _on_return_to_menu(_data: Dictionary = {}) -> void:
	_play_loop(background_music)


func _on_start_game(data: Dictionary = {}) -> void:
	var battle_info = data.get("battle_info")
	if battle_info is GameConfig.BattleInfo and battle_info.is_exam and exam_music:
		_battle_stream = exam_music
	elif battle_music:
		_battle_stream = battle_music
	else:
		_battle_stream = background_music
	_play_loop(_battle_stream)


func _on_boss_appeared(_armor: int) -> void:
	if music_player == null or boss_music == null or music_player.stream == boss_music:
		return
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(music_player, "volume_db", _SILENT_DB, boss_fade_sec)
	_tween.tween_callback(_play_loop.bind(boss_music))


## Regular battles end right after (win fade wins); endless keeps flying → battle theme again.
func _on_boss_defeated() -> void:
	if music_player == null or _battle_stream == null or music_player.stream == _battle_stream:
		return
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(music_player, "volume_db", _SILENT_DB, boss_fade_sec)
	_tween.tween_callback(_play_loop.bind(_battle_stream))


func _on_time_left(seconds: int) -> void:
	if music_player and seconds > 0 and seconds <= hurry_seconds:
		music_player.pitch_scale = hurry_pitch


func _fade_out() -> void:
	if music_player == null or _playing_result:
		return
	_kill_tween()
	_faded = true
	_tween = create_tween()
	_tween.tween_property(music_player, "volume_db", _SILENT_DB, end_fade_sec)


func _play_result(stream: AudioStream) -> void:
	if music_player == null or stream == null:
		return
	_kill_tween()
	_playing_result = true
	_faded = false
	music_player.stop()
	music_player.stream = stream
	music_player.pitch_scale = 1.0
	music_player.volume_db = result_volume_db
	music_player.play()


func _play_loop(stream: AudioStream) -> void:
	if music_player == null:
		return
	_kill_tween()
	if stream == null:
		stream = music_player.stream
	if not _playing_result and not _faded and music_player.stream == stream:
		music_player.pitch_scale = 1.0
		music_player.volume_db = background_volume_db
		return
	_playing_result = false
	_faded = false
	music_player.stop()
	if stream:
		music_player.stream = stream
	music_player.pitch_scale = 1.0
	music_player.volume_db = background_volume_db
	music_player.play()


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
