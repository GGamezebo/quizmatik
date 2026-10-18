extends Control

## Main-menu clock (left side): shown once endless is unlocked
## (`ProgressController.is_endless_unlocked`); starts the endless battle (`endless_config`).
## Caption under it = the profile's best endless time. `pulse` (UiPulse) runs while shown.

@export var root_events: RootEvents
@export var progress: ProgressController
@export var endless_config: GameConfig
@export var button: BaseButton
@export var best_label: Label
@export var best_format: String = "Рекорд %s"
## Pulses the whole clock button (its wrapper box; the button itself keeps its hover scale) while shown.
@export var pulse: UiPulse

var _listener: EventListener = EventListener.new()


func _ready() -> void:
	button.pressed.connect(_on_pressed)
	visibility_changed.connect(_refresh)
	if root_events:
		_listener.add(root_events.ev_profiles_changed, _refresh)
	_refresh()


func _exit_tree() -> void:
	_listener.deinit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()


func _refresh() -> void:
	var unlocked: bool = progress != null and progress.is_endless_unlocked()
	button.visible = unlocked
	var best: int = progress.pdata.statistics.endless_best_sec if progress != null else 0
	best_label.visible = unlocked and best > 0
	if best_label.visible:
		best_label.text = tr(best_format) % ProgressStatistics.format_clock(best)
	pulse.set_active(unlocked and is_visible_in_tree())


func _on_pressed() -> void:
	root_events.ev_start_game.emit({"custom_battle": endless_config})
