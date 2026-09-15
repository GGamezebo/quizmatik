extends Control

@export var pdata: PData
@export var name_label: Label
@export var age_label: Label
@export var gold_label: Label
@export var plane_preview: TextureRect
@export var plane_name_label: Label
@export var plane_button: BaseButton
@export var trophy_button: BaseButton
@export var profiles_list: VBoxContainer
@export var create_button: BaseButton
@export var edit_button: BaseButton
@export var delete_button: BaseButton
@export var create_overlay: ProfileCreateOverlay
@export var delete_dialog: ConfirmDialog
@export var profile_row_scene: PackedScene
@export var root_events: RootEvents

var _pending_delete_id: String = ""
var _edit_mode: bool = false
var _listener: EventListener = EventListener.new()


func _ready() -> void:
	if create_button:
		create_button.pressed.connect(_on_create_pressed)
	if edit_button:
		edit_button.pressed.connect(_on_edit_pressed)
	if delete_button:
		delete_button.pressed.connect(_on_delete_pressed)
	if create_overlay:
		create_overlay.ev_submitted.connect(_on_overlay_submitted)
	if delete_dialog:
		delete_dialog.ev_confirmed.connect(_on_delete_confirmed)
	if root_events != null:
		_listener.add(root_events.ev_profiles_changed, _refresh_deferred)


func _exit_tree() -> void:
	_listener.deinit()


func on_window_enter() -> void:
	_refresh()


func on_window_exit() -> void:
	if create_overlay:
		create_overlay.close()


func _profiles() -> ProfileController:
	return ProfileController.find_in_tree(get_tree())


func _live() -> PData:
	var profiles := _profiles()
	if profiles != null and profiles.pdata != null:
		return profiles.pdata
	return pdata


func _refresh_deferred() -> void:
	call_deferred("_refresh")


func _refresh() -> void:
	var live := _live()
	if live == null:
		return
	var display := live.display_name
	if display.is_empty():
		display = "Пилот"
	if name_label:
		name_label.text = display
	if age_label:
		age_label.text = "Возраст: %d" % live.age
	if gold_label:
		gold_label.text = str(live.gold)
	var plane_id := live.equipped_plane_id
	var def: Dictionary = PlaneCatalog.get_def(plane_id)
	if plane_preview:
		plane_preview.texture = PlaneCatalog.atlas_texture()
		plane_preview.modulate = def.get("tint", Color.WHITE)
	if plane_name_label:
		plane_name_label.text = String(def.get("name", ""))
	_rebuild_list()
	var profiles := _profiles()
	if create_button:
		create_button.disabled = profiles == null or not profiles.can_create()
	if delete_button:
		delete_button.disabled = profiles == null or not profiles.can_delete()


func _rebuild_list() -> void:
	if profiles_list == null or profile_row_scene == null:
		return
	var profiles := _profiles()
	var rows: Array[Dictionary] = []
	var active_id := ""
	if profiles != null:
		rows = profiles.list_summaries()
		active_id = profiles.active_profile_id()
	elif pdata != null:
		rows.append({
			"id": pdata.profile_id,
			"name": pdata.display_name,
			"age": pdata.age,
		})
		active_id = pdata.profile_id
	_ensure_row_count(rows.size())
	for index in range(rows.size()):
		var row: Button = profiles_list.get_child(index) as Button
		var row_data: Dictionary = rows[index]
		var row_id := String(row_data.get("id", ""))
		row.setup(row_id, String(row_data.get("name", "")), int(row_data.get("age", 8)), row_id == active_id)


func _ensure_row_count(count: int) -> void:
	while profiles_list.get_child_count() > count:
		var extra: Node = profiles_list.get_child(profiles_list.get_child_count() - 1)
		profiles_list.remove_child(extra)
		extra.queue_free()
	while profiles_list.get_child_count() < count:
		var row: Button = profile_row_scene.instantiate() as Button
		row.pressed.connect(_on_row_button_pressed.bind(row))
		profiles_list.add_child(row)


func _on_row_button_pressed(row: Button) -> void:
	var profiles := _profiles()
	if profiles == null or row == null:
		return
	var profile_id := String(row.get("profile_id"))
	if profile_id.is_empty():
		return
	profiles.switch_profile(profile_id)


func _on_create_pressed() -> void:
	_edit_mode = false
	if create_overlay:
		create_overlay.open(true, "Новый пилот")


func _on_edit_pressed() -> void:
	_edit_mode = true
	if create_overlay:
		create_overlay.open(true, "Изменить пилота")
		var live := _live()
		if live != null:
			create_overlay.configure(live.display_name, live.gender, live.age)


func _on_overlay_submitted(display_name: String, gender: String, age: int) -> void:
	var profiles := _profiles()
	if profiles == null:
		return
	if _edit_mode:
		profiles.update_identity(display_name, gender, age)
	else:
		profiles.create_profile(display_name, gender, age)
	_edit_mode = false


func _on_delete_pressed() -> void:
	var profiles := _profiles()
	if profiles == null or not profiles.can_delete():
		return
	_pending_delete_id = profiles.active_profile_id()
	if delete_dialog:
		delete_dialog.open(
			"Удалить пилота?",
			"Прогресс этого пилота будет потерян.",
			"Удалить",
			"Отмена",
		)


func _on_delete_confirmed() -> void:
	var profiles := _profiles()
	if profiles == null or _pending_delete_id.is_empty():
		return
	profiles.delete_profile(_pending_delete_id)
	_pending_delete_id = ""
