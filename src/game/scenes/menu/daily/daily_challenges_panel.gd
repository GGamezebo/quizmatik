class_name DailyChallengesPanel
extends VBoxContainer

## Non-interactive daily slots column for the main menu.
## Slot size shrinks to fit the available height so the panel is never clipped.

@export var daily_controller: DailyChallengesController
@export var slots_row: VBoxContainer
@export var slot_scene: PackedScene
@export var title_label: Label
@export var slot_size_max: float = 72.0
@export var slot_size_min: float = 36.0

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
	if title_label:
		title_label.text = "Дейлики\n%d / %d" % [
			daily_controller.get_completed_count(),
			PData.DAILY_SLOT_COUNT,
		]
	_fit_slot_sizes()


func _exit_tree() -> void:
	_event_listener.deinit()
	

func _build_slots() -> void:
	for child in slots_row.get_children():
		slots_row.remove_child(child)
		child.free()
	_slots.clear()
	for _index in range(PData.DAILY_SLOT_COUNT):
		var slot: DailySlot = slot_scene.instantiate() as DailySlot
		slots_row.add_child(slot)
		_slots.append(slot)


func _fit_slot_sizes() -> void:
	if _slots.is_empty():
		return
	var title_h: float = 0.0
	if title_label:
		title_h = title_label.get_combined_minimum_size().y
	var panel_sep: float = float(get_theme_constant("separation"))
	var slot_sep: float = float(slots_row.get_theme_constant("separation"))
	var slots_count: int = _slots.size()
	var reserved: float = title_h + panel_sep + slot_sep * max(slots_count - 1, 0)
	var available: float = max(size.y - reserved, slot_size_min * slots_count)
	var side: float = clampf(available / float(slots_count), slot_size_min, slot_size_max)
	# Keep square slots within column width too.
	side = minf(side, maxf(size.x, slot_size_min))
	var slot_size := Vector2(side, side)
	for slot in _slots:
		slot.custom_minimum_size = slot_size
	if title_label:
		var font_size: int = int(clampf(side * 0.38, 16.0, 24.0))
		title_label.add_theme_font_size_override("font_size", font_size)
