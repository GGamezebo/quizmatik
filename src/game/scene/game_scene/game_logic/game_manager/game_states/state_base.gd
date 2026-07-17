class_name StateBase
extends FSMState

static func get_state() -> String:
	return '' 
	
var game_manager: GameManager
var event_listener = EventListener.new()

func _init() -> void:
	super(get_state())
	
func initialize(_game_manager: GameManager) -> void:
	self.game_manager = _game_manager
	
func deinit() -> void:
	event_listener.deinit()
	game_manager = null
