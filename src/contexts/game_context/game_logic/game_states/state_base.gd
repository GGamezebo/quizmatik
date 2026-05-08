class_name StateBase
extends FSMState

static func get_state() -> String:
	return '' 
	
var game_mamager: GameManager
var event_listener = EventListener.new()

func _init() -> void:
	super(get_state())
	
func initialize(_game_mamager: GameManager) -> void:
	self.game_mamager = _game_mamager
	
func deinit() -> void:
	event_listener.deinit()
	game_mamager = null
