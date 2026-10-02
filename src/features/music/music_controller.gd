class_name MusicController
extends Node

## Swaps AppRoot MusicPlayer: menu background, battle / exam themes, post-battle win/lose.
## Empty battle/exam slots fall back to background_music.

@export var root_events: RootEvents
@export var music_player: AudioStreamPlayer
@export var background_music: AudioStream
@export var battle_music: AudioStream
@export var exam_music: AudioStream
@export var win_music: AudioStream
@export var lose_music: AudioStream
@export var background_volume_db: float = -7.69
@export var result_volume_db: float = -5.0

var _listener: EventListener = EventListener.new()
var _playing_result: bool = false


func _ready() -> void:
	if root_events:
		_listener.add(root_events.ev_exit_game, _on_exit_game)
		_listener.add(root_events.ev_return_to_menu, _on_return_to_menu)
		_listener.add(root_events.ev_start_game, _on_start_game)
	_prepare_loops()


func _exit_tree() -> void:
	_listener.deinit()


func _prepare_loops() -> void:
	_enable_loop(win_music)
	_enable_loop(lose_music)
	_enable_loop(background_music)
	_enable_loop(battle_music)
	_enable_loop(exam_music)


func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true


func _on_exit_game(data: Dictionary = {}) -> void:
	var is_win: bool = bool(data.get("is_win", false))
	_play_result(win_music if is_win else lose_music)


func _on_return_to_menu(_data: Dictionary = {}) -> void:
	_play_loop(background_music)


func _on_start_game(data: Dictionary = {}) -> void:
	var battle_info = data.get("battle_info")
	if battle_info is GameConfig.BattleInfo and battle_info.is_exam and exam_music:
		_play_loop(exam_music)
	elif battle_music:
		_play_loop(battle_music)
	else:
		_play_loop(background_music)


func _play_result(stream: AudioStream) -> void:
	if music_player == null or stream == null:
		return
	_playing_result = true
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = result_volume_db
	music_player.play()


func _play_loop(stream: AudioStream) -> void:
	if music_player == null:
		return
	if stream == null:
		stream = music_player.stream
	if not _playing_result and music_player.stream == stream:
		return
	_playing_result = false
	music_player.stop()
	if stream:
		music_player.stream = stream
	music_player.volume_db = background_volume_db
	music_player.play()
