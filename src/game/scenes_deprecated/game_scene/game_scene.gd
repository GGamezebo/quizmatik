extends IScene


static func NAME() -> String:
	return "GameScene"

var data: Dictionary = {}

func _init(_data: Dictionary = {}) -> void:
	self.data = _data
	print("GameScene _init", _data)

func _ready() -> void:
	print("GameScene _ready")
	if _is_isolated_run():
		initialize({})

func initialize(_data: Dictionary) -> void:
	print("initialize")

func deinit() -> void:
	print("deinit")

func on_event(_event_name: String, _data: Dictionary) -> void:
	pass
	
func _is_isolated_run() -> bool:
	return get_tree().current_scene == self
