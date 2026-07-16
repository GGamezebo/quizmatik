extends Node

const HFSM_CONFIG_PATH := "res://src/common/hfsm/app_hfsm.json"
const AppRoot := preload("res://src/game/contexts/main_context/hfsm/app_root_entity.gd")
const HfsmEntityRegistry := preload("res://src/game/contexts/main_context/hfsm/hfsm_entity_registry.gd")

@export_file("*.tscn") var game_context_path: String
@export_file("*.tscn") var menu_context_path: String
@export_file("*.tscn") var post_battle_context_path: String
@export var loading_screen_scene: PackedScene
@export var main_events: MainEvents
@export var min_load_time: float = 0.0

var current_context: Node = null
var current_loading_screen = null
var is_loading: bool = false
var load_start_time: float = 0.0
var target_path: String = ""
var _mount_token: int = 0

var _hfsm: HFSM
var listener: EventListener = EventListener.new()


func _ready() -> void:
	AppRoot.host = self
	listener.add(main_events.ev_start_game, _on_ev_start_game)
	listener.add(main_events.ev_exit_game, _on_ev_exit_game)
	listener.add(main_events.ev_return_to_menu, _on_ev_return_to_menu)
	# Defer past main-scene dependency settle; threaded Menu load during boot races shared deps.
	_start_hfsm_when_ready()


func _start_hfsm_when_ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_hfsm = HFSM.new(
		HfsmLoader.load_tree(HFSM_CONFIG_PATH),
		HfsmEntityRegistry.build(),
	)


func _exit_tree() -> void:
	listener.deinit()
	release_current_context()
	AppRoot.host = null
	_hfsm = null


func get_hfsm() -> HFSM:
	return _hfsm


func _on_ev_start_game(data: Dictionary) -> void:
	if _hfsm:
		_hfsm.add_event("ev.start_game", data)


func _on_ev_exit_game(data: Dictionary = {}) -> void:
	if _hfsm:
		_hfsm.add_event("ev.exit_game", data)


func _on_ev_return_to_menu() -> void:
	if _hfsm:
		_hfsm.add_event("ev.return_to_menu")


## Used by HFSM context entities. Fire-and-forget async mount.
func mount_context(scene_path: String, data: Dictionary = {}, use_loading_screen: bool = true) -> void:
	_mount_context_async(scene_path, data, use_loading_screen)


func release_current_context() -> void:
	_mount_token += 1
	if current_context == null:
		return
	if current_context.has_method("deinit"):
		current_context.deinit()
	current_context.queue_free()
	current_context = null


func _mount_context_async(scene_path: String, data: Dictionary, use_loading_screen: bool) -> void:
	_mount_token += 1
	var token: int = _mount_token

	load_start_time = Time.get_unix_time_from_system()
	target_path = scene_path
	is_loading = true

	if current_loading_screen:
		current_loading_screen.queue_free()
		current_loading_screen = null

	if use_loading_screen:
		current_loading_screen = loading_screen_scene.instantiate()
		add_child(current_loading_screen)
		if current_context:
			if current_context.has_method("deinit"):
				current_context.deinit()
			current_context.queue_free()
			current_context = null

	var scene: PackedScene = await _async_load_scene(scene_path, _update_progress)
	if token != _mount_token:
		is_loading = false
		return

	if not use_loading_screen and current_context:
		if current_context.has_method("deinit"):
			current_context.deinit()
		current_context.queue_free()
		current_context = null

	if scene == null:
		is_loading = false
		push_error("[MainContext] Failed to load context scene: %s" % scene_path)
		return

	await _finish_mount(scene, data, token)


func _async_load_scene(path: String, progress_callback: Callable) -> PackedScene:
	# Resolve uid:// to res:// — threaded loads of uid paths are flaky during main-scene boot.
	var resolved: String = path
	if path.begins_with("uid://"):
		var id := ResourceUID.text_to_id(path)
		if id != ResourceUID.INVALID_ID:
			var uid_path := ResourceUID.get_id_path(id)
			if not uid_path.is_empty():
				resolved = uid_path

	# Prefer sync load when no progress UI is needed (caller still awaits this).
	# Threaded load of Menu during cold start races ProgressController / background deps.
	if current_loading_screen == null:
		progress_callback.call(1.0)
		return load(resolved) as PackedScene

	var err: Error = ResourceLoader.load_threaded_request(resolved)
	if err != OK:
		push_error("[MainContext] load_threaded_request failed (%s): %s" % [error_string(err), resolved])
		return load(resolved) as PackedScene

	var progress_state: Array = []
	var state: int = ResourceLoader.THREAD_LOAD_IN_PROGRESS
	while state == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		state = ResourceLoader.load_threaded_get_status(resolved, progress_state)
		if progress_state.size() > 0:
			progress_callback.call(progress_state[0])
		if state == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame

	if state == ResourceLoader.THREAD_LOAD_LOADED:
		return ResourceLoader.load_threaded_get(resolved) as PackedScene

	push_warning("[MainContext] Threaded load status %s for %s; trying sync load" % [state, resolved])
	return load(resolved) as PackedScene


func _finish_mount(scene: PackedScene, data: Dictionary, token: int) -> void:
	if token != _mount_token:
		is_loading = false
		return

	var current_time := Time.get_unix_time_from_system()
	var time_passed := current_time - load_start_time

	if time_passed < min_load_time:
		await get_tree().create_timer(min_load_time - time_passed).timeout

	if token != _mount_token:
		is_loading = false
		return

	is_loading = false
	current_context = scene.instantiate()
	add_child(current_context)
	if current_context.has_method("initialize"):
		current_context.initialize(data)

	if current_loading_screen:
		current_loading_screen.fade_out()
		current_loading_screen = null


func _update_progress(progress: float) -> void:
	if current_loading_screen:
		current_loading_screen.update_progress(progress)
