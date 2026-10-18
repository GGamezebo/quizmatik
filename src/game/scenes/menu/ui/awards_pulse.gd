extends Node

## Main-menu achievements button: pulses while the hall of fame has an award not seen yet
## (`ProgressController.has_unseen_awards`; the trophy room marks them seen on enter).
## Re-checks on `ev_profiles_changed` and when the button is shown again (back from a window).

@export var root_events: RootEvents
@export var progress: ProgressController
@export var button: Control
@export var pulse: UiPulse

var _listener: EventListener = EventListener.new()


func _ready() -> void:
	if root_events:
		_listener.add(root_events.ev_profiles_changed, _refresh)
	if button:
		button.visibility_changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	_listener.deinit()


func _refresh() -> void:
	pulse.set_active(button != null and button.is_visible_in_tree() and progress != null \
			and progress.has_unseen_awards())
