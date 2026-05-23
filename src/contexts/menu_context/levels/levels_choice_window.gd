extends Control

@export var packs_list_container: HBoxContainer
@export var level_container_scene: PackedScene
@export var levelsConfig: LevelsConfig
@export var progress: ProgressController
@export var windows_stack_manager: WindowStackManager
@export var level_selection_window: Control


func _ready() -> void:
	_render_packs_menu()
	level_selection_window.back_button.pressed.connect(windows_stack_manager.close_stacked_window)


func _render_packs_menu() -> void:
	for child in packs_list_container.get_children():
		child.queue_free()
		
	var levels = levelsConfig.levels
	if not levels.has("containers") or not (levels["containers"] is Array):
		push_error("[PacksMenu] Error: Invalid levels configuration data.")
		return

	for container_data in levels["containers"]:
		var container_id: String = container_data.get("container_id", "")
		
		if container_id.is_empty():
			continue
			
		var container_instance = level_container_scene.instantiate()
		packs_list_container.add_child(container_instance)
		
		var is_unlocked: bool = progress.is_container_unlocked(container_id)
		var container = progress.find_container_in_config(container_id)
		container_instance.initialize(container['name'], is_unlocked)
		
		if is_unlocked:
			container_instance.button.pressed.connect(_on_pack_enter_requested.bind(container_id))

func _on_pack_enter_requested(container_id: String) -> void:
	level_selection_window.initialize(container_id)
	windows_stack_manager.open_stacked_window(level_selection_window)
