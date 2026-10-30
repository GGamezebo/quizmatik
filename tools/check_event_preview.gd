extends SceneTree

## Verify the dev picker drives the shared calendar and main-menu banner without profile saves.
func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var calendar: EventCalendar = load("res://src/common/events/event_calendar.tres")
	var real: EventWindow = calendar.active_window()
	var pdata := PData.new()
	var cosmetics := CosmeticsController.new()
	cosmetics.pdata = pdata
	var events := EventsController.new()
	events.name = "PreviewEvents"
	events.calendar = calendar
	events.pdata = pdata
	events.cosmetics = cosmetics
	root.add_child(events)
	var lab: Control = load("res://src/dev/training_room_lab/training_room_lab_window.tscn").instantiate()
	lab.root_events = null
	for child in lab.find_children("*", "", true, false):
		child.set_block_signals(true)
	root.add_child(lab)
	for child in lab.find_children("*", "", true, false):
		child.set_block_signals(false)
	var picker: OptionButton = lab.event_picker
	assert(picker != null and picker.item_count > 20)
	var selected: int = -1
	for index in picker.item_count:
		if picker.get_item_metadata(index) == "new_year:2026-12-25":
			selected = index
	assert(selected >= 0)
	picker.select(selected)
	picker.item_selected.emit(selected)
	assert(calendar.active_window().key() == "new_year:2026-12-25")
	assert(calendar.active_window(Time.get_unix_time_from_datetime_string("2026-11-01T00:00:00")).event_id == "halloween")
	assert(calendar.active_window().contains(calendar.current_unix()))
	var progress := ProgressController.new()
	progress.pdata = pdata
	var entry: EventEntry = load("res://src/game/scenes/menu/event/event_entry.tscn").instantiate()
	entry.events = events
	entry.progress = progress
	entry.root_events = RootEvents.new()
	root.add_child(entry)
	await process_frame
	assert(entry.visible)
	assert(entry.title_label.text == "Новый год")
	assert(entry.banner.texture == calendar.get_event("new_year").banner.art)
	var starts: Array[Dictionary] = []
	entry.root_events.ev_start_game.connect(func(data: Dictionary) -> void: starts.append(data))
	entry.button.pressed.emit()
	assert(starts.size() == 1 and starts[0].custom_battle.event_key == "new_year:2026-12-25")
	# Annual look override is honored by the same menu instance.
	assert(calendar.set_debug_window("halloween:2027-10-25"))
	entry.refresh()
	assert(entry.banner.texture == calendar.run_banner(calendar.active_window()).art)
	assert(not calendar.set_debug_window("april_fools:2027-04-01"))
	assert(calendar.active_window().key() == "halloween:2027-10-25")
	picker.select(0)
	picker.item_selected.emit(0)
	assert(calendar.debug_window() == null and calendar.active_window() == real)
	entry.refresh()
	assert(not entry.visible) # Fresh pilot: normal first-flight gate restored.
	entry.queue_free()
	lab.queue_free()
	events.queue_free()
	await process_frame
	progress.free()
	cosmetics.free()
	print("EVENT_PREVIEW_CHECK: picker, dates, banner, annual look, calendar reset passed")
	quit()
