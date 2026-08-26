class_name DailyChallengesPanel
extends Control

## Display-only daily streak card for the main menu.

@export var daily_controller: DailyChallengesController
@export var slots_row: HBoxContainer
@export var slot_scene: PackedScene
@export var title_label: Label
@export var progress_label: Label
## Filled ink stamps assigned by slot index (cycles if fewer than slot count).
@export var stamp_filled_variants: Array[Texture2D] = []
@export var slot_size_max: float = 96.0
@export var slot_size_min: float = 88.0

var _slots: Array[DailySlot] = []
var _event_listener = EventListener.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_event_listener.add(resized, _fit_slot_sizes)
	_build_slots()
	refresh()
	call_deferred("_fit_slot_sizes")


func refresh() -> void:
	var filled: Array = daily_controller.get_slots()
	for index in range(_slots.size()):
		var is_filled: bool = index < filled.size() and bool(filled[index])
		_slots[index].set_filled(is_filled)
	var completed: int = daily_controller.get_completed_count()
	if progress_label:
		progress_label.text = "%d / %d пройдено" % [completed, PData.DAILY_SLOT_COUNT]
	_fit_slot_sizes()


func _exit_tree() -> void:
	_event_listener.deinit()


func _build_slots() -> void:
	for child in slots_row.get_children():
		slots_row.remove_child(child)
		child.free()
	_slots.clear()
	for index in range(PData.DAILY_SLOT_COUNT):
		var slot: DailySlot = slot_scene.instantiate() as DailySlot
		if not stamp_filled_variants.is_empty():
			slot.stamp_filled = stamp_filled_variants[index % stamp_filled_variants.size()]
		slots_row.add_child(slot)
		_slots.append(slot)


func _fit_slot_sizes() -> void:
	if _slots.is_empty() or slots_row == null:
		return
	var sep: float = float(slots_row.get_theme_constant("separation"))
	var count: int = _slots.size()
	var available: float = maxf(slots_row.size.x - sep * float(count - 1), slot_size_min * count)
	var side: float = clampf(available / float(count), slot_size_min, slot_size_max)
	var slot_size := Vector2(side, side)
	for slot in _slots:
		slot.custom_minimum_size = slot_size
		if slot.has_method("_fit_mark"):
			slot.call_deferred("_fit_mark")
		elif slot.has_method("_fit_star"):
			slot.call_deferred("_fit_star")
