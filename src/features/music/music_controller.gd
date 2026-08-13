class_name MusicController
extends Node

## Swaps AppRoot MusicPlayer between background and post-battle win/lose themes.

@export var root_events: RootEvents
@export var music_player: AudioStreamPlayer
@export var background_music: AudioStream
@export var win_music: AudioStream
@export var lose_music: AudioStream
@export var background_volume_db: float = -7.69
@export var result_volume_db: float = -5.0

var _listener: EventListener = EventListener.new()
var _playing_result: bool = false


func _ready() -> void:
	if root_events:
		_listener.add(root_events.ev_exit_game, _on_exit_game)
		_listener.add(root_events.ev_return_to_menu, _on_restore_background)
		_listener.add(root_events.ev_start_game, _on_restore_background)
	_prepare_loops()


func _exit_tree() -> void:
	_listener.deinit()


func _prepare_loops() -> void:
	_enable_loop(win_music)
	_enable_loop(lose_music)
	_enable_loop(background_music)


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


func _on_restore_background(_data: Dictionary = {}) -> void:
	if not _playing_result and music_player and music_player.stream == background_music:
		return
	_play_background()


func _play_result(stream: AudioStream) -> void:
	if music_player == null or stream == null:
		return
	_playing_result = true
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = result_volume_db
	music_player.play()


func _play_background() -> void:
	if music_player == null:
		return
	_playing_result = false
	var stream: AudioStream = background_music if background_music else music_player.stream
	music_player.stop()
	if stream:
		music_player.stream = stream
	music_player.volume_db = background_volume_db
	music_player.play()
