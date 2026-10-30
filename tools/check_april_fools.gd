extends SceneTree

## Content integration check; no profile files are read or saved.
## godot_console --headless --path . --script tools/check_april_fools.gd

var failures: int = 0


func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var calendar: EventCalendar = load("res://src/common/events/event_calendar.tres")
	var catalog: CosmeticCatalog = load("res://src/common/cosmetics/cosmetic_catalog.tres")
	var event: SeasonalEvent = calendar.get_event("april_fools")
	check(event != null, "April Fools must be registered")
	if event == null:
		quit(1)
		return
	check(event.box_count() == 6, "Six gifts required")
	check(event.completion_gold() == 10, "Repeat wins pay 10 gold")
	var runs: Array[EventWindow] = []
	for window in calendar.windows:
		if window.event_id == event.id:
			runs.append(window)
	check(runs.size() == 11, "First season plus ten repeats required")
	for index in runs.size():
		var window: EventWindow = runs[index]
		check(window.start_date == "%d-04-01" % (2027 + index), "Start date")
		check(window.end_date == "%d-04-16" % (2027 + index), "Inclusive end date")
		check(calendar.active_window(window.start_unix() - 1) == null, "Closed before start")
		check(calendar.active_window(window.start_unix()) == window, "Open on first second")
		check(calendar.active_window(window.end_unix() - 1) == window, "Open through April 16")
		check(calendar.active_window(window.end_unix()) == null, "Closed April 17")
		check(calendar.run_cover(window) == event.cover, "Same cover every year")
		check(calendar.run_banner(window) == event.banner, "Same banner every year")
	for item in event.gifts + [event.cover]:
		check(catalog.get_item(item.id) == item, "Catalog identity: " + item.id)
		check(not calendar.is_released(item.id, runs[0].start_unix() - 1), "Hidden before first season")
		check(calendar.is_released(item.id, runs[0].start_unix()), "On sale at start")
		check(calendar.is_released(item.id, runs[-1].end_unix()), "Still on sale after last season")
	var pdata := PData.new()
	var cosmetics := CosmeticsController.new()
	cosmetics.pdata = pdata
	cosmetics.catalog = catalog
	var events := EventsController.new()
	events.pdata = pdata
	events.calendar = calendar
	events.cosmetics = cosmetics
	for year in runs.size():
		var key: String = runs[year].key()
		check(events.wins(key) == 0, "New year has independent progress")
		for box in 6:
			var result: Dictionary = events.register_win(key)
			check(result.gift_id == event.gift(box).id, "Gift order")
			check(result.gift_refund == (year > 0), "Owned gifts refunded")
			var expected_gold: int = 0 if year == 0 else event.gift(box).gold_cost
			if box == 5:
				check(result.cover_id == event.cover.id, "Sixth box grants cover")
				if year > 0:
					expected_gold += event.cover.gold_cost
			else:
				check(result.cover_id == "", "No early cover")
			check(result.gold == expected_gold, "Refund amount")
		check(events.register_win(key).gold == 10, "Post-completion reward")
	check(pdata.cosmetics.equipped.is_empty(), "Gifts must not equip automatically")
	for wins in [0, 1, 5, 6, 20]:
		var config := EventScenario.build(event, runs[0], wins, null)
		check(config.event_key == runs[0].key() and config.event_id == event.id, "Scenario identity")
		check(config.time_limit_sec == mini(wins + 1, 6) * 60.0, "Chase duration")
		check(config.timed_chase and config.timed_boss_chance == 1.0, "Chase then boss")
	for packed in [event.boss_scene, event.wing_scene, event.cover.scene]:
		var instance: Node = packed.instantiate()
		root.add_child(instance)
		await process_frame
		if instance is BackgroundBase:
			check(instance.battle_music != null and instance.battle_music.get_length() > 30.0, "Comic march")
			check(instance.answer_scene != null, "Jester answers on the April sky")
			var answer: Node = instance.answer_scene.instantiate()
			root.add_child(answer)
			check(answer.get_node("Visual/Sprite2D").texture.get_size() == Vector2(1280, 720), "Answer atlas contract")
			answer.queue_free()
		instance.queue_free()
		await process_frame
	check(event.banner.size == Vector2(672, 160) and event.banner.art.get_size() == Vector2(1344, 320), "Banner size (2x art)")
	events.free()
	cosmetics.free()
	print("APRIL_FOOLS_CHECK: %d failures; eleven seasons, rewards, shop, scenarios, scenes" % failures)
	quit(1 if failures else 0)
