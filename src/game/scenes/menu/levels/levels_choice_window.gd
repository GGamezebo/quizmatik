extends Control

@export var packs_list_container: HBoxContainer
@export var packs_scroll: ScrollContainer
@export var scroll_track: TextureRect
@export var scroll_fill: TextureRect
@export var level_container_scene: PackedScene
@export var levelsConfig: LevelsConfig
@export var progress: ProgressController
@export var windows_stack_manager: WindowStackManager
@export var level_selection_window: Control

const CARD_WIDTH := 300.0
const CARD_GAP := 30.0


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	if packs_scroll != null:
		packs_scroll.get_h_scroll_bar().value_changed.connect(_on_scroll_changed)
		packs_scroll.resized.connect(_on_scroll_changed)
	_update_window()


func on_window_enter() -> void:
	_update_window()


func _update_window() -> void:
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
		var container: Dictionary = levelsConfig.find_container_in_config(container_id)
		var completed_count := _count_completed_levels(container_id)
		var total_count := _total_levels(container)
		container_instance.initialize(
			container_id,
			container["name"],
			is_unlocked,
			completed_count,
			total_count,
		)

		if is_unlocked:
			progress.mark_container_seen(container_id)
			container_instance.hit_button.pressed.connect(_on_pack_enter_requested.bind(container_id))

	call_deferred("_on_scroll_changed")


func _count_completed_levels(container_id: String) -> int:
	var container_config: Dictionary = levelsConfig.find_container_in_config(container_id)
	if container_config.is_empty():
		return 0

	var completed: Dictionary = {}
	if progress.pdata.levels.containers.has(container_id):
		completed = progress.pdata.levels.containers[container_id].completed_levels

	var count := 0
	for level in container_config["levels"]:
		var level_id: int = level["level_id"]
		if completed.has(level_id) and completed[level_id].stars >= 1:
			count += 1
	return count


func _total_levels(container: Dictionary) -> int:
	var levels_list: Variant = container.get("levels", [])
	if levels_list is Array:
		return levels_list.size()
	return 0


func _on_pack_enter_requested(container_id: String) -> void:
	level_selection_window.initialize(container_id)
	windows_stack_manager.open_stacked_window(level_selection_window)


func open_level_select(container_id: String) -> void:
	windows_stack_manager.open_stacked_window(self)
	_on_pack_enter_requested(container_id)


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_update_window()


func _on_scroll_changed(_value: float = 0.0) -> void:
	if scroll_track == null or scroll_fill == null or packs_scroll == null:
		return

	var content_width := packs_list_container.get_combined_minimum_size().x
	var viewport_width := packs_scroll.size.x
	if content_width <= viewport_width:
		scroll_fill.visible = false
		scroll_track.visible = false
		return

	scroll_fill.visible = true
	scroll_track.visible = true

	var track_width := scroll_track.size.x
	var fill_ratio := clampf(viewport_width / content_width, 0.12, 1.0)
	var fill_width := track_width * fill_ratio
	var scroll_ratio := 0.0
	var h_bar := packs_scroll.get_h_scroll_bar()
	if h_bar != null and h_bar.max_value > h_bar.min_value:
		scroll_ratio = (h_bar.value - h_bar.min_value) / (h_bar.max_value - h_bar.min_value)
	var fill_x := (track_width - fill_width) * scroll_ratio

	scroll_fill.size.x = fill_width
	scroll_fill.position.x = fill_x
