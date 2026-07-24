extends IScene

## App-root HFSM scene: shared account/progress/music + RootEvents → HFSM bridge.

@export var root_events: RootEvents
@export var progress_controller: ProgressController
@export var daily_challenges_controller: DailyChallengesController

var _listener: EventListener = EventListener.new()


func initialize(_data: Dictionary) -> void:
	_listener.add(root_events.ev_start_game, _on_ev_start_game)
	_listener.add(root_events.ev_exit_game, _on_ev_exit_game)
	_listener.add(root_events.ev_return_to_menu, _on_ev_return_to_menu)

func deinit() -> void:
	_listener.deinit()
	super.deinit()

func _on_ev_start_game(data: Dictionary) -> void:
	add_event("ev.start_game", data)

func _on_ev_exit_game(data: Dictionary = {}) -> void:
	_apply_battle_result(data)
	add_event("ev.exit_game", data)

func _on_ev_return_to_menu(data: Dictionary = {}) -> void:
	add_event("ev.open_menu", data)

func _apply_battle_result(data: Dictionary) -> void:
	var is_win: bool = data['is_win']
	var stars: int = data['stars']
	var game_config: GameConfig = data['game_config']
	var battle_info = game_config.battle_info
	if is_win:
		daily_challenges_controller.register_win()
		if battle_info:
			progress_controller.post_battle(
				battle_info,
				stars
			)
