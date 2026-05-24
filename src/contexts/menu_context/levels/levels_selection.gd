extends Control

@export var main_events: MainEvents
@export var grid_container: GridContainer
@export var level_button: PackedScene
@export var levels: LevelsConfig
@export var pdata: PDataProgress
@export var container_id: String
@export var progress: ProgressController
@export var back_button: Button

func initialize(_container_id: String) -> void:
	container_id = _container_id
	_populate_levels_grid()

func _ready() -> void:
	_populate_levels_grid()

func _populate_levels_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	
	var container = levels.find_container_in_config(container_id)
	
	for level in container["levels"]:
		var lvl_id: int = level["level_id"]
		var btn = level_button.instantiate()
		btn.initialize(lvl_id, false, 0)
		grid_container.add_child(btn)
		
		var is_unlocked: bool = progress.is_level_unlocked(container_id, lvl_id)
		var stars: int = progress.get_level_stars(container_id, lvl_id)
		btn.set_params(is_unlocked, stars)
		if is_unlocked:
			btn.pressed.connect(_on_level_selected.bind(container_id, lvl_id))
#
func _on_level_selected(_container_id: String, level_id: int) -> void:
	print("Loading gameplay for: ", _container_id, " | Level: ", level_id)
	var data = {'container_id': _container_id, "level_id": level_id}
	main_events.ev_start_game.emit(data)
#
