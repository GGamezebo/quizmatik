extends Control

## Touch-scheme HUD hints, visual only — input stays in `AirPlane` (left half drag = move,
## right half tap = shoot). Shown only for `AirPlane.is_touch_scheme()`.
## Shoot icon "presses" on every `ev_shoot` (tap anywhere on the right half), dims while
## `ev_lock_shoot`; move pill lights up while a finger steers. Fades out on win / lose.

@export var game_events: GameEvents
@export var air_plane: AirPlane
@export var shoot_icon: Control
@export var move_icon: Control
@export_range(0.0, 1.0) var idle_alpha: float = 0.45
@export_range(0.0, 1.0) var active_alpha: float = 0.9
@export_range(0.0, 1.0) var locked_alpha: float = 0.15
@export var press_scale: float = 0.8
@export var press_seconds: float = 0.06
@export var release_seconds: float = 0.22

var _listener: EventListener = EventListener.new()
var _locked: bool = false
var _press_tween: Tween
var _shoot_flash: float = 0.0


func _ready() -> void:
	visible = AirPlane.is_touch_scheme()
	if not visible:
		set_process(false)
		return
	for icon: Control in [shoot_icon, move_icon]:
		if icon:
			icon.pivot_offset = icon.size / 2.0
			icon.modulate.a = idle_alpha
	if game_events:
		_listener.add(game_events.ev_shoot, _on_shoot)
		_listener.add(game_events.ev_lock_shoot, _on_lock_shoot)
		_listener.add(game_events.ev_win, _fade_out)
		_listener.add(game_events.ev_lose, _fade_out)


func _exit_tree() -> void:
	_listener.deinit()


func _process(delta: float) -> void:
	_shoot_flash = maxf(_shoot_flash - delta / release_seconds, 0.0)
	if shoot_icon:
		var base: float = locked_alpha if _locked else idle_alpha
		shoot_icon.modulate.a = lerpf(base, active_alpha, _shoot_flash)
	if move_icon and air_plane:
		var target: float = active_alpha if air_plane.has_movement_touch() else idle_alpha
		move_icon.modulate.a = move_toward(move_icon.modulate.a, target, delta * 4.0)


func _on_shoot() -> void:
	_shoot_flash = 1.0
	if shoot_icon == null:
		return
	if _press_tween:
		_press_tween.kill()
	_press_tween = create_tween()
	_press_tween.tween_property(shoot_icon, "scale", Vector2.ONE * press_scale, press_seconds)
	_press_tween.tween_property(shoot_icon, "scale", Vector2.ONE, release_seconds) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_lock_shoot(locked: bool) -> void:
	_locked = locked


func _fade_out() -> void:
	set_process(false)
	create_tween().tween_property(self, "modulate:a", 0.0, 0.3)
