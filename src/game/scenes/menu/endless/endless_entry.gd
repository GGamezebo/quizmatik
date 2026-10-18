extends Control

## Main-menu clock (left side): shown once endless is unlocked
## (`ProgressController.is_endless_unlocked`); starts the endless battle (`endless_config`).
## Caption under it = the profile's best endless time. `pulse` (UiPulse) runs while shown.
## First battle: `rules_overlay` (endless rules) with a start button; its start marks
## `ProgressController.ENDLESS_RULES_STEP` and launches the battle.

@export var root_events: RootEvents
@export var progress: ProgressController
@export var endless_config: GameConfig
## EASY profile (grade 1: ± within 20, × / ÷ tables 2-5); empty → `endless_config`.
@export var easy_endless_config: GameConfig
@export var rules_overlay: RulesOverlay
@export var button: BaseButton
@export var best_label: Label
@export var best_format: String = "Рекорд %s"
## Pulses the whole clock button (its wrapper box; the button itself keeps its hover scale) while shown,
## until the best time reaches `calm_best_sec` — then never again.
@export var pulse: UiPulse
@export var calm_best_sec: int = 300

var _listener: EventListener = EventListener.new()


func _ready() -> void:
	button.pressed.connect(_on_pressed)
	if rules_overlay:
		rules_overlay.ev_start_pressed.connect(_on_rules_start)
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
	pulse.set_active(unlocked and best < calm_best_sec and is_visible_in_tree())


func _on_pressed() -> void:
	if rules_overlay != null and progress != null 			and not progress.is_tutorial_step_done(ProgressController.ENDLESS_RULES_STEP):
		rules_overlay.open(true)
		return
	_start()


func _on_rules_start() -> void:
	if progress != null:
		progress.complete_tutorial_step(ProgressController.ENDLESS_RULES_STEP)
	_start()


func _start() -> void:
	var easy: bool = easy_endless_config != null and progress != null and progress.is_easy_difficulty()
	var config: GameConfig = easy_endless_config if easy else endless_config
	root_events.ev_start_game.emit({"custom_battle": config})
