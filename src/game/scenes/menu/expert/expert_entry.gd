class_name ExpertEntry
extends Control

## Level grid badge (right of the 20 levels, mirrors the record clock): the valley's expert trial. Shown once the valley
## exam is passed (`ProgressController.is_expert_unlocked`); the whole badge pulses until the trial is passed, then the
## caption turns golden. Starts `ExpertScenario.build(expert_config, …)`: 5 min of «? ⊕ ? = N» through the valley's
## levels. The first battle is coached by the tutorial context (`ExpertCoach`). The grid calls `set_valley`.

@export var root_events: RootEvents
@export var progress: ProgressController
@export var expert_config: GameConfig
@export var button: BaseButton
@export var caption: Label
@export var caption_text: String = "Эксперт"
@export var caption_done_text: String = "Ты эксперт!"
@export var caption_done_color: Color = Color(0.72, 0.48, 0.08)
## Pulses the whole badge button (its wrapper box; the button itself keeps its hover scale) until passed.
@export var pulse: UiPulse

var _listener: EventListener = EventListener.new()
var _valley_id: String = ""
var _caption_color: Color


func _ready() -> void:
	button.pressed.connect(_on_pressed)
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


func set_valley(container_id: String) -> void:
	_valley_id = container_id
	_refresh()


func _refresh() -> void:
	var unlocked: bool = progress != null and not _valley_id.is_empty() and progress.is_expert_unlocked(_valley_id)
	button.visible = unlocked
	var done: bool = unlocked and progress.is_expert(_valley_id)
	if caption:
		caption.visible = unlocked
		caption.text = caption_done_text if done else caption_text
		caption.add_theme_color_override("font_color", caption_done_color if done else _caption_color)
	if pulse:
		pulse.set_active(unlocked and not done and is_visible_in_tree())


func _on_pressed() -> void:
	var difficulty := StringName(progress.pdata.difficulty)
	var config: GameConfig = ExpertScenario.build(expert_config, progress.levels_config, _valley_id, difficulty)
	root_events.ev_start_game.emit({"custom_battle": config})
