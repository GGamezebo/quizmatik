class_name VibrationController
extends Node

## App-root haptics: listens to GameEvents / RootEvents / UI button presses.
## Uses handheld vibrate (mobile/web) + joypad rumble (Steam controllers).

@export var game_events: GameEvents
@export var root_events: RootEvents
@export var enabled: bool = true

@export_group("UI")
@export var ui_duration_ms: int = 45
@export_range(0.0, 1.0) var ui_amplitude: float = 0.45

@export_group("Battle")
@export var shoot_duration_ms: int = 50
@export_range(0.0, 1.0) var shoot_amplitude: float = 0.5
@export var pop_duration_ms: int = 60
@export_range(0.0, 1.0) var pop_amplitude: float = 0.65
@export var correct_duration_ms: int = 70
@export_range(0.0, 1.0) var correct_amplitude: float = 0.55
@export var mistake_duration_ms: int = 140
@export_range(0.0, 1.0) var mistake_amplitude: float = 0.85
@export var countdown_duration_ms: int = 90
@export_range(0.0, 1.0) var countdown_amplitude: float = 0.5
@export var go_duration_ms: int = 60
@export_range(0.0, 1.0) var go_amplitude: float = 0.65
@export var win_duration_ms: int = 320
@export_range(0.0, 1.0) var win_amplitude: float = 0.75

@export_group("Plane crash")
@export var crash_pulse_duration_ms: int = 140
@export_range(0.0, 1.0) var crash_pulse_amplitude: float = 0.9
@export var crash_finale_duration_ms: int = 700
@export_range(0.0, 1.0) var crash_finale_amplitude: float = 1.0
@export var crash_pulse_count: int = 4
@export var crash_pulse_gap_sec: float = 0.15

@export_group("Root flow")
@export var start_game_duration_ms: int = 50
@export_range(0.0, 1.0) var start_game_amplitude: float = 0.35
@export var return_menu_duration_ms: int = 30
@export_range(0.0, 1.0) var return_menu_amplitude: float = 0.25

const _BUTTON_META := "quizmatik_vibrate_hooked"
const _POP_DEBOUNCE_MSEC := 80

var _listener: EventListener = EventListener.new()
var _last_pop_msec: int = -99999
var _crash_token: int = 0


func _ready() -> void:
	if game_events:
		_listener.add(game_events.ev_shoot, _on_shoot)
		_listener.add(game_events.ev_explosion, _on_explosion)
		_listener.add(game_events.ev_correct_answer, _on_correct_answer)
		_listener.add(game_events.ev_mistake, _on_mistake)
		_listener.add(game_events.ev_win, _on_win)
		_listener.add(game_events.ev_lose, _on_lose)
		_listener.add(game_events.ev_game_state_changed, _on_game_state_changed)
	if root_events:
		_listener.add(root_events.ev_start_game, _on_start_game)
		_listener.add(root_events.ev_return_to_menu, _on_return_to_menu)
	get_tree().node_added.connect(_on_node_added)
	_hook_tree(get_tree().root)


func _exit_tree() -> void:
	_crash_token += 1
	_listener.deinit()
	var tree := get_tree()
	if tree and tree.node_added.is_connected(_on_node_added):
		tree.node_added.disconnect(_on_node_added)


func vibrate(duration_ms: int, amplitude: float = 0.5) -> void:
	if not enabled or duration_ms <= 0:
		return
	# Many Android motors ignore very short / weak pulses.
	var ms: int = duration_ms
	var amp: float = clampf(amplitude, 0.0, 1.0)
	if OS.has_feature("mobile") or OS.has_feature("android"):
		ms = maxi(ms, 40)
		if amp > 0.0:
			amp = maxf(amp, 0.35)
	# amplitude -1 = platform default strength (most reliable on Android).
	var handheld_amp: float = amp if amp > 0.0 else -1.0
	Input.vibrate_handheld(ms, handheld_amp)
	_rumble_joypads(amp if amp > 0.0 else 0.6, ms / 1000.0)


func _rumble_joypads(amplitude: float, duration_sec: float) -> void:
	var weak: float = _amp_to_weak(amplitude)
	var strong: float = _amp_to_strong(amplitude)
	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, weak, strong, duration_sec)


func _amp_to_weak(amplitude: float) -> float:
	return clampf(amplitude * 0.55, 0.0, 1.0)


func _amp_to_strong(amplitude: float) -> float:
	return clampf(amplitude, 0.0, 1.0)


func _on_shoot() -> void:
	vibrate(shoot_duration_ms, shoot_amplitude)


func _on_explosion(_answer: Answer, _hit_point: Vector2) -> void:
	_pulse_pop()


func _on_correct_answer() -> void:
	vibrate(correct_duration_ms, correct_amplitude)
	_pulse_pop_if_idle()


func _on_mistake() -> void:
	vibrate(mistake_duration_ms, mistake_amplitude)
	_pulse_pop_if_idle()


func _pulse_pop() -> void:
	vibrate(pop_duration_ms, pop_amplitude)
	_last_pop_msec = Time.get_ticks_msec()


func _pulse_pop_if_idle() -> void:
	if Time.get_ticks_msec() - _last_pop_msec > _POP_DEBOUNCE_MSEC:
		_pulse_pop()


func _on_win() -> void:
	_play_win_pattern()


func _on_lose() -> void:
	_play_crash_pattern()


func _play_win_pattern() -> void:
	_crash_token += 1
	var token: int = _crash_token
	vibrate(80, 0.4)
	await get_tree().create_timer(0.12).timeout
	if token != _crash_token:
		return
	vibrate(100, 0.55)
	await get_tree().create_timer(0.14).timeout
	if token != _crash_token:
		return
	vibrate(win_duration_ms, win_amplitude)


func _play_crash_pattern() -> void:
	_crash_token += 1
	var token: int = _crash_token
	vibrate(220, 1.0)
	for _i in maxi(crash_pulse_count, 0):
		await get_tree().create_timer(crash_pulse_gap_sec).timeout
		if token != _crash_token:
			return
		vibrate(crash_pulse_duration_ms, crash_pulse_amplitude)
	await get_tree().create_timer(crash_pulse_gap_sec).timeout
	if token != _crash_token:
		return
	vibrate(crash_finale_duration_ms, crash_finale_amplitude)


func _on_game_state_changed(_from_state: String, to_state: String) -> void:
	match to_state:
		FSMGameStates.COUNTDOWN:
			vibrate(countdown_duration_ms, countdown_amplitude)
		FSMGameStates.GAME:
			vibrate(go_duration_ms, go_amplitude)


func _on_start_game(_data: Dictionary = {}) -> void:
	vibrate(start_game_duration_ms, start_game_amplitude)


func _on_return_to_menu(_data: Dictionary = {}) -> void:
	vibrate(return_menu_duration_ms, return_menu_amplitude)


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
	vibrate(ui_duration_ms, ui_amplitude)
