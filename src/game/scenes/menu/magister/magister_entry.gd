extends Control

## Main-menu magister cap (right of the daily scroll, mirrors the endless clock): shown once every valley expert trial is
## passed (`ProgressController.is_magister_unlocked`); pulses while shown; starts the magister trial
## (`magister_config`: 10 min countdown, squares / roots, boss every 2 min). Caption turns golden after the award.
## First trial: `rules_overlay` (squares, roots, rules) with a start button; its start marks
## `ProgressController.MAGISTER_RULES_STEP` and launches the battle.

@export var root_events: RootEvents
@export var progress: ProgressController
@export var magister_config: GameConfig
@export var rules_overlay: RulesOverlay
## EASY profile (grade 1): all four operations (± within 20, × / ÷ tables 2-5) instead of squares / roots,
## with its own rules card. Empty → the normal ones.
@export var easy_magister_config: GameConfig
@export var easy_rules_overlay: RulesOverlay
@export var button: BaseButton
@export var caption: Label
@export var caption_text: String = "Магистр"
@export var caption_done_text: String = "Ты магистр!"
@export var caption_done_color: Color = Color(0.72, 0.48, 0.08)
## Pulses the whole cap button (its wrapper box; the button itself keeps its hover scale) while shown, until the trial is passed.
@export var pulse: UiPulse

var _listener: EventListener = EventListener.new()
var _caption_color: Color


func _ready() -> void:
	button.pressed.connect(_on_pressed)
	for overlay in [rules_overlay, easy_rules_overlay]:
		if overlay:
			(overlay as RulesOverlay).ev_start_pressed.connect(_on_rules_start)
	visibility_changed.connect(_refresh)
	if caption:
		_caption_color = caption.get_theme_color("font_color")
	if root_events:
		_listener.add(root_events.ev_profiles_changed, _refresh)
	_refresh()


func _exit_tree() -> void:
	_listener.deinit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()


func _refresh() -> void:
	var unlocked: bool = progress != null and progress.is_magister_unlocked()
	button.visible = unlocked
	var done: bool = unlocked and progress.is_magister()
	if caption:
		caption.visible = unlocked
		caption.text = caption_done_text if done else caption_text
		caption.add_theme_color_override("font_color", caption_done_color if done else _caption_color)
	if pulse:
		pulse.set_active(unlocked and not done and is_visible_in_tree())


func _on_pressed() -> void:
	var overlay: RulesOverlay = easy_rules_overlay if _is_easy() and easy_rules_overlay != null else rules_overlay
	if overlay != null and progress != null \
			and not progress.is_tutorial_step_done(ProgressController.MAGISTER_RULES_STEP):
		overlay.open(true)
		return
	_start()


func _on_rules_start() -> void:
	if progress != null:
		progress.complete_tutorial_step(ProgressController.MAGISTER_RULES_STEP)
	_start()


func _start() -> void:
	var config: GameConfig = easy_magister_config if _is_easy() and easy_magister_config != null else magister_config
	root_events.ev_start_game.emit({"custom_battle": config})


func _is_easy() -> bool:
	return progress != null and progress.is_easy_difficulty()
