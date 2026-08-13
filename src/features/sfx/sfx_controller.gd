class_name SfxController
extends Node

## App-root SFX: listens to GameEvents / UI button presses. Plane-local loops stay on the plane.

@export var game_events: GameEvents
@export var bus_name: StringName = &"SFX"
@export var player_count: int = 8

@export_group("UI")
@export var ui_click: AudioStream

@export_group("Battle")
@export var shoot: AudioStream
@export var pop: AudioStream
@export var correct: AudioStream
@export var mistake: AudioStream
@export var battle_start: AudioStream
@export var go: AudioStream
@export var win: AudioStream
@export var lose: AudioStream

const _BUTTON_META := "quizmatik_sfx_hooked"
const _POP_DEBOUNCE_MSEC := 80

var _listener: EventListener = EventListener.new()
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _last_pop_msec: int = -99999


func _ready() -> void:
	_build_pool()
	if game_events:
		_listener.add(game_events.ev_shoot, _on_shoot)
		_listener.add(game_events.ev_explosion, _on_explosion)
		_listener.add(game_events.ev_correct_answer, _on_correct_answer)
		_listener.add(game_events.ev_mistake, _on_mistake)
		_listener.add(game_events.ev_win, _on_win)
		_listener.add(game_events.ev_lose, _on_lose)
		_listener.add(game_events.ev_game_state_changed, _on_game_state_changed)
	get_tree().node_added.connect(_on_node_added)
	_hook_tree(get_tree().root)


func _exit_tree() -> void:
	_listener.deinit()
	var tree := get_tree()
	if tree and tree.node_added.is_connected(_on_node_added):
		tree.node_added.disconnect(_on_node_added)


func _build_pool() -> void:
	var bus := _resolve_bus()
	var count: int = maxi(player_count, 1)
	for i in count:
		var player := AudioStreamPlayer.new()
		player.bus = bus
		add_child(player)
		_players.append(player)


func _resolve_bus() -> StringName:
	if AudioServer.get_bus_index(bus_name) != -1:
		return bus_name
	return &"Master"


func play(stream: AudioStream, volume_db: float = 0.0, pitch_jitter: float = 0.0) -> void:
	if stream == null or _players.is_empty():
		return
	var player := _acquire_player()
	player.stream = stream
	player.volume_db = volume_db
	if pitch_jitter > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	else:
		player.pitch_scale = 1.0
	player.play()


func _acquire_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	return player


func _on_shoot() -> void:
	play(shoot, -2.0, 0.06)


func _on_explosion(_answer: Answer, _hit_point: Vector2) -> void:
	_play_pop()


func _on_correct_answer() -> void:
	play(correct, -3.0, 0.03)
	_play_pop_if_idle()


func _on_mistake() -> void:
	play(mistake, -2.0, 0.04)
	_play_pop_if_idle()


func _play_pop() -> void:
	play(pop, -1.0, 0.08)
	_last_pop_msec = Time.get_ticks_msec()


func _play_pop_if_idle() -> void:
	if Time.get_ticks_msec() - _last_pop_msec > _POP_DEBOUNCE_MSEC:
		_play_pop()


func _on_win() -> void:
	play(win, -1.0)


func _on_lose() -> void:
	play(lose, -1.0)


func _on_game_state_changed(_from_state: String, to_state: String) -> void:
	match to_state:
		FSMGameStates.COUNTDOWN:
			play(battle_start, -4.0)
		FSMGameStates.GAME:
			play(go, -3.0)


func _on_node_added(node: Node) -> void:
	_hook_button(node)


func _hook_tree(node: Node) -> void:
	_hook_button(node)
	for child in node.get_children():
		_hook_tree(child)


func _hook_button(node: Node) -> void:
	var button := node as BaseButton
	if button == null or button.get_meta(_BUTTON_META, false):
		return
	button.set_meta(_BUTTON_META, true)
	button.pressed.connect(_on_ui_pressed)


func _on_ui_pressed() -> void:
	play(ui_click, -6.0, 0.04)
