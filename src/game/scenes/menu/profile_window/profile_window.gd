extends Control

## Pilot ID card (name, gold, cups, difficulty, plane) + pilot switcher cards (max 4).

@export var pdata: PData
@export var name_label: Label
@export var gold_label: Label
@export var trophy_button: Button
@export var photo: TextureRect
@export var plane_preview: TextureRect
@export var plane_name_label: Label
@export var difficulty_picker: DifficultyPicker
@export var edit_button: BaseButton
@export var delete_button: BaseButton
@export var profiles_grid: GridContainer
@export var profiles_count_label: Label
@export var create_card: BaseButton
@export var create_overlay: ProfileCreateOverlay
@export var delete_dialog: ConfirmDialog
## Switching a pilot with stars to / from EASY (other examples) suggests a new pilot instead.
@export var difficulty_change_overlay: DifficultyChangeOverlay
@export var profile_card_scene: PackedScene
@export var root_events: RootEvents
## Equipped look on the ID photo: paint, frame (`polaroid` panel style), sticker.
@export var cosmetics: CosmeticCatalog
@export var polaroid: PanelContainer
@export var sticker: TextureRect

## Delete asks several times; each entry = [title, message with %s = pilot name].
const DELETE_STEPS: Array = [
	["Удалить пилота?", "Весь прогресс пилота «%s» будет потерян: звёзды, кубки, золото и самолёты."],
	["Точно удалить?", "Это нельзя отменить. Прогресс пилота «%s» исчезнет навсегда."],
	["Последний шанс!", "Нажми галочку, только если решение окончательное. Пилот «%s» будет удалён."],
]

var _pending_delete_id: String = ""
var _delete_step: int = 0
var _edit_mode: bool = false
var _cards: Array[ProfileCard] = []
var _listener: EventListener = EventListener.new()


func _ready() -> void:
	if create_card:
		create_card.pressed.connect(_on_create_pressed)
	if edit_button:
		edit_button.pressed.connect(_on_edit_pressed)
	if delete_button:
		delete_button.pressed.connect(_on_delete_pressed)
	if difficulty_picker:
		difficulty_picker.ev_changed.connect(_on_difficulty_changed)
	if create_overlay:
		create_overlay.ev_submitted.connect(_on_overlay_submitted)
	if difficulty_change_overlay:
		difficulty_change_overlay.ev_create_pressed.connect(_on_change_create_pressed)
		difficulty_change_overlay.ev_keep_pressed.connect(_apply_difficulty)
	if delete_dialog:
		delete_dialog.ev_confirmed.connect(_on_delete_confirmed)
		delete_dialog.ev_canceled.connect(_on_delete_canceled)
	if root_events != null:
		_listener.add(root_events.ev_profiles_changed, _refresh_deferred)


func _exit_tree() -> void:
	_listener.deinit()


func on_window_enter() -> void:
	_refresh()


func on_window_exit() -> void:
	if create_overlay:
		create_overlay.close()
	if difficulty_change_overlay:
		difficulty_change_overlay.close()


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
	if name_label:
		name_label.text = ProfileController.display_name_or_default(live.display_name)
	if gold_label:
		gold_label.text = str(live.gold)
	if trophy_button:
		trophy_button.text = str(live.trophies.unlocked.size())
	if difficulty_picker:
		difficulty_picker.set_value(StringName(live.difficulty))
	var profiles := _profiles()
	var plane_id := live.equipped_plane_id
	if profiles != null:
		plane_id = profiles.equipped_plane_id()
	PlaneCatalog.apply_preview(photo, plane_id, _equipped(live, CosmeticItem.Slot.PAINT) as PaintItem)
	PlaneCatalog.apply_preview(plane_preview, plane_id)
	_apply_id_look(live)
	if plane_name_label:
		plane_name_label.text = String(PlaneCatalog.get_def(plane_id).get("name", ""))
	_rebuild_cards()


func _apply_id_look(live: PData) -> void:
	if cosmetics == null:
		return
	var frame := _equipped(live, CosmeticItem.Slot.FRAME) as FrameItem
	if polaroid != null and frame != null and frame.style != null:
		polaroid.add_theme_stylebox_override("panel", frame.style)
	var badge := _equipped(live, CosmeticItem.Slot.STICKER) as StickerItem
	if sticker != null:
		sticker.visible = badge != null and badge.texture != null
		if sticker.visible:
			sticker.texture = badge.texture


func _equipped(live: PData, slot: CosmeticItem.Slot) -> CosmeticItem:
	if cosmetics == null:
		return null
	return cosmetics.equipped_item(slot, live.cosmetics.equipped)


func _rebuild_cards() -> void:
	if profiles_grid == null or profile_card_scene == null:
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
			"difficulty": pdata.difficulty,
			"equipped_plane_id": pdata.equipped_plane_id,
		})
		active_id = pdata.profile_id
	_ensure_card_count(rows.size())
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		var row_id := String(row.get("id", ""))
		_cards[index].setup(
			row_id,
			String(row.get("name", "")),
			String(row.get("difficulty", "normal")),
			String(row.get("equipped_plane_id", PlaneCatalog.STARTER_ID)),
			row_id == active_id,
		)
	if create_card:
		create_card.visible = profiles == null or profiles.can_create()
		profiles_grid.move_child(create_card, -1)
	if delete_button:
		delete_button.visible = profiles == null or profiles.can_delete()
	if profiles_count_label:
		profiles_count_label.text = "%d / %d" % [rows.size(), ProfileController.MAX_PROFILES]


func _ensure_card_count(count: int) -> void:
	while _cards.size() > count:
		var extra: ProfileCard = _cards.pop_back()
		profiles_grid.remove_child(extra)
		extra.queue_free()
	while _cards.size() < count:
		var card := profile_card_scene.instantiate() as ProfileCard
		card.pressed.connect(_on_card_pressed.bind(card))
		profiles_grid.add_child(card)
		_cards.append(card)


func _on_card_pressed(card: ProfileCard) -> void:
	var profiles := _profiles()
	if profiles == null or card == null or card.profile_id.is_empty():
		return
	profiles.switch_profile(card.profile_id)


func _on_difficulty_changed(difficulty: StringName) -> void:
	var live := _live()
	var current: StringName = BattleDifficulty.sanitize(StringName(live.difficulty if live != null else ""))
	var grade_changes: bool = (current == BattleDifficulty.EASY) != (difficulty == BattleDifficulty.EASY)
	if difficulty_change_overlay != null and grade_changes and live != null and live.levels.has_any_stars():
		# Picker stays on the current difficulty until the player decides in the overlay.
		difficulty_picker.set_value(current)
		var profiles := _profiles()
		difficulty_change_overlay.open(current, difficulty, profiles == null or profiles.can_create())
		return
	_apply_difficulty(difficulty)


func _apply_difficulty(difficulty: StringName) -> void:
	if difficulty_picker:
		difficulty_picker.set_value(difficulty)
	var profiles := _profiles()
	if profiles != null:
		profiles.set_difficulty(difficulty)
	elif pdata != null:
		pdata.difficulty = String(difficulty)


func _on_create_pressed() -> void:
	_edit_mode = false
	if create_overlay == null:
		return
	create_overlay.open(true, "Новый пилот")
	var profiles := _profiles()
	if profiles != null:
		create_overlay.configure(profiles.unique_name(""), BattleDifficulty.NORMAL)


## New pilot for the new grade: the usual create overlay, prefilled with that difficulty.
func _on_change_create_pressed(difficulty: StringName) -> void:
	_on_create_pressed()
	if create_overlay != null:
		var profiles := _profiles()
		create_overlay.configure(profiles.unique_name("") if profiles != null else "", difficulty)


func _on_edit_pressed() -> void:
	_edit_mode = true
	if create_overlay == null:
		return
	create_overlay.open(true, "Изменить пилота", false)
	var live := _live()
	if live != null:
		create_overlay.configure(live.display_name, StringName(live.difficulty))


func _on_overlay_submitted(display_name: String, difficulty: StringName) -> void:
	var profiles := _profiles()
	if profiles == null:
		return
	if _edit_mode:
		profiles.rename_profile(display_name)
	else:
		profiles.create_profile(display_name, difficulty)
	_edit_mode = false


func _on_delete_pressed() -> void:
	var profiles := _profiles()
	if profiles == null or not profiles.can_delete():
		return
	_pending_delete_id = profiles.active_profile_id()
	_delete_step = 0
	_open_delete_step()


func _open_delete_step() -> void:
	if delete_dialog == null:
		return
	var live := _live()
	var display := ProfileController.display_name_or_default(live.display_name if live != null else "")
	var step: Array = DELETE_STEPS[_delete_step]
	delete_dialog.open(String(step[0]), tr(String(step[1])) % display, "Удалить", "Отмена")


func _on_delete_confirmed() -> void:
	if _pending_delete_id.is_empty():
		return
	_delete_step += 1
	if _delete_step < DELETE_STEPS.size():
		_open_delete_step()
		return
	var profiles := _profiles()
	if profiles != null:
		profiles.delete_profile(_pending_delete_id)
	_on_delete_canceled()


func _on_delete_canceled() -> void:
	_pending_delete_id = ""
	_delete_step = 0
