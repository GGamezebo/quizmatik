extends IScene

## First-run tutorial context — HFSM state `App/Tutorial` (parallel to Menu/Battle).
## Entered on `ev.open_tutorial` (AppRoot, when the active profile hasn't finished it); leaves itself via
## `ev.close_tutorial`. Other scenes only mark UI with `UiAnchor` in `tutorial_anchors.tres`;
## all tutorial rules, texts and persistence live here.

@export var progress: ProgressController
@export var menu_pointer: AnchorPointer
@export var battle_coach: BattleCoach


func _ready() -> void:
	battle_coach.ev_goal_reached.connect(_on_goal_reached)
	battle_coach.ev_finished.connect(_on_finished)
	super._ready()


func initialize(_data: Dictionary) -> void:
	menu_pointer.set_enabled(true)


func deinit() -> void:
	menu_pointer.set_enabled(false)
	battle_coach.stop()
	super.deinit()


func on_event(event_name: String, _data: Dictionary) -> void:
	match event_name:
		"ev.start_game":
			menu_pointer.set_enabled(false)
			battle_coach.stop()
		"ev.exit_game":
			battle_coach.stop()
		"ev.open_menu":
			menu_pointer.set_enabled(true)


func _on_goal_reached() -> void:
	progress.complete_tutorial()


func _on_finished() -> void:
	add_event("ev.close_tutorial")
