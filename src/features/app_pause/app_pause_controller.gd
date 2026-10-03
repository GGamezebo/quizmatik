class_name AppPauseController
extends Node

## App-root background pause: app hidden / unfocused → pause SceneTree + mute Master; back → restore.
## Sources: engine focus/pause notifications + RootEvents.ev_app_visibility_changed (platform contexts, e.g. web tab hidden).

@export var root_events: RootEvents
@export var master_bus: StringName = &"Master"

var _listener: EventListener = EventListener.new()
var _is_backgrounded: bool = false
var _was_paused: bool = false
var _was_muted: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if root_events != null:
		_listener.add(root_events.ev_app_visibility_changed, _on_visibility_changed)

func _exit_tree() -> void:
	_listener.deinit()
	_set_backgrounded(false)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_set_backgrounded(true)
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_set_backgrounded(false)

func _on_visibility_changed(is_visible: bool) -> void:
	_set_backgrounded(not is_visible)

func _set_backgrounded(value: bool) -> void:
	if value == _is_backgrounded or not is_inside_tree():
		return
	_is_backgrounded = value
	var bus_idx: int = AudioServer.get_bus_index(master_bus)
	if value:
		# Remember prior state so we never un-pause / un-mute what someone else set.
		_was_paused = get_tree().paused
		_was_muted = bus_idx >= 0 and AudioServer.is_bus_mute(bus_idx)
		get_tree().paused = true
		if bus_idx >= 0:
			AudioServer.set_bus_mute(bus_idx, true)
	else:
		get_tree().paused = _was_paused
		if bus_idx >= 0:
			AudioServer.set_bus_mute(bus_idx, _was_muted)
