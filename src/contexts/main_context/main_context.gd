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

func _process(_delta:float) -> void:
	if not is_loading: return
	
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(target_path, progress)
	
	# Обновляем полоску (progress[0] — это float от 0.0 до 1.0)
	if current_loading_screen:
		current_loading_screen.update_progress(progress[0])
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_on_loading_complete()

func _on_start_game() -> void:
	switch_game_context(game_context_path)
	
func _ev_exit_game() -> void:
	switch_game_context(menu_context_path)
	
func switch_game_context(scene_path: String):
	if is_loading: return
	
	if current_context:
		current_context.queue_free()
	load_start_time = Time.get_unix_time_from_system()
	target_path = scene_path
	is_loading = true
	
	# 1. Создаем экран загрузки
	if current_loading_screen:
		current_loading_screen.queue_free()
	current_loading_screen = loading_screen_scene.instantiate()
	add_child(current_loading_screen)
	#
	# 3. Запрашиваем фоновую загрузку
	ResourceLoader.load_threaded_request(scene_path)
	
func _on_loading_complete():
	is_loading = false
	
	var current_time = Time.get_unix_time_from_system()
	var time_passed = current_time - load_start_time
	
	if time_passed < min_load_time:
		var wait_time = min_load_time - time_passed
		await get_tree().create_timer(wait_time).timeout
	
	# Получаем загруженный ресурс и инстанцируем
	var new_scene_res = ResourceLoader.load_threaded_get(target_path)
	current_context = new_scene_res.instantiate()
	add_child(current_context)
	
	# Убираем экран загрузки с эффектом
	if current_loading_screen:
		current_loading_screen.fade_out()
