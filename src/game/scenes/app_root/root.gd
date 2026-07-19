extends IScene

## App-root HFSM scene: shared account/progress/music + RootEvents → HFSM bridge.

@export var root_events: RootEvents

var listener: EventListener = EventListener.new()


func initialize(_data: Dictionary) -> void:
	# sync_hfsm() may already set _hfsm; still must wire RootEvents → HFSM.
	if not _bind_hfsm():
		call_deferred("_bind_hfsm")


func deinit() -> void:
	listener.deinit()
	_hfsm = null


func _bind_hfsm() -> bool:
	if _hfsm == null:
		var host := get_tree().current_scene
		if host == null or not host.has_method("get_hfsm"):
			return false
		_hfsm = host.get_hfsm()
	if _hfsm == null or root_events == null:
		return false
	listener.add(root_events.ev_start_game, _on_ev_start_game)
	listener.add(root_events.ev_exit_game, _on_ev_exit_game)
	listener.add(root_events.ev_return_to_menu, _on_ev_return_to_menu)
	return true


func _on_ev_start_game(data: Dictionary) -> void:
	if _hfsm:
		_hfsm.add_event("ev.start_game", data)


func _on_ev_exit_game(data: Dictionary = {}) -> void:
	if _hfsm:
		_hfsm.add_event("ev.exit_game", data)


func _on_ev_return_to_menu() -> void:
	if _hfsm:
		_hfsm.add_event("ev.return_to_menu")
