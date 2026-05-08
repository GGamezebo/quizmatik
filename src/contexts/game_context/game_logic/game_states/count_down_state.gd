class_name CountDownState
extends StateBase

static func get_state() -> String:
	return 'CountDown'
	
func enter(_prev_state: FSMState, _event_data: Dictionary):
	await game_mamager.get_tree().create_timer(1.0).timeout
	if game_mamager == null:
		return
	add_event('ev_start_game')
