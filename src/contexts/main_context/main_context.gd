extends Node

const PATH_PROGRESS = "user://progress.tres"
const PATH_SETTINGS = "user://settings.tres"


@export_file("*.tscn") var game_context_path: String
@export_file("*.tscn") var menu_context_path: String
@export var loading_screen_scene: PackedScene
@export var main_events: MainEvents
@export var min_load_time: float = 0.0

var load_start_time: float = 0.0

var current_context:Node
var current_loading_screen = null
var is_loading: bool = false
var target_path: String = ""

@onready var listener:EventListener = EventListener.new()

func _ready() -> void:
	current_context = $MenuContext
	listener.add(main_events.ev_start_game, _on_start_game)
	listener.add(main_events.ev_exit_game, _ev_exit_game)
	
func _exit_tree() -> void:
	listener.deinit()

func _on_start_game(game_config: GameConfig) -> void:
	var use_loading_screen: bool = true
	var data: Dictionary = {'game_config': game_config}
	switch_game_context(game_context_path, use_loading_screen, data)
	
func _ev_exit_game() -> void:
	switch_game_context(menu_context_path)
	
func switch_game_context(scene_path: String, use_loading_screen: bool = true, data: Dictionary = {}):
	if is_loading: return
	
	if current_context:
		current_context.queue_free()
	load_start_time = Time.get_unix_time_from_system()
	target_path = scene_path
	is_loading = true
	
	if current_loading_screen:
		current_loading_screen.queue_free()
	if use_loading_screen:
		current_loading_screen = loading_screen_scene.instantiate()
		add_child(current_loading_screen)
	
	var scene: PackedScene = await _async_load_scene(scene_path, _update_progress)
	if scene:
		_on_loading_complete(scene, data)
		
func _async_load_scene(path: String, progress_callback: Callable) -> PackedScene:
	ResourceLoader.load_threaded_request(path)
	var progress_state = []
	while true:
		var state: int = ResourceLoader.load_threaded_get_status(path, progress_state)
		var progress: float = progress_state[0]
		progress_callback.call(progress)
		if state == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		else:
			break
		
	return ResourceLoader.load_threaded_get(path)
	
func _on_loading_complete(scene: PackedScene, data: Dictionary):
	is_loading = false
	
	var current_time = Time.get_unix_time_from_system()
	var time_passed = current_time - load_start_time
	
	if time_passed < min_load_time:
		var wait_time = min_load_time - time_passed
		await get_tree().create_timer(wait_time).timeout
	
	current_context = scene.instantiate()
	current_context.initialize(data)
	add_child(current_context)
	
	if current_loading_screen:
		current_loading_screen.fade_out()

func _update_progress(progress: float) -> void:
	if current_loading_screen:
		current_loading_screen.update_progress(progress)
