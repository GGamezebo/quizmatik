class_name EventCalendar
extends Resource

## Seasonal events config: what each event is (`events`, by `SeasonalEvent.id`) and when it runs (`windows`, UTC,
## one per year). A window whose event has no content yet is skipped (never shown). Event look items go on sale
## in the shop with the first window of their event and stay there for good (`is_released`).

@export var events: Array[SeasonalEvent] = []
@export var windows: Array[EventWindow] = []


## UTC unix seconds now.
static func now_unix() -> int:
	return int(Time.get_unix_time_from_system())


## Run open at `unix` (-1 = now) whose event has content; null = no event.
func active_window(unix: int = -1) -> EventWindow:
	var at: int = now_unix() if unix < 0 else unix
	for window in windows:
		if window != null and window.contains(at) and get_event(window.event_id) != null:
			return window
	return null


func get_event(event_id: String) -> SeasonalEvent:
	for event in events:
		if event != null and event.id == event_id:
			return event
	return null


## Run of progress key `key` (`EventWindow.key()`); null = unknown.
func find_window(key: String) -> EventWindow:
	for window in windows:
		if window != null and window.key() == key:
			return window
	return null


## First start of the event's runs (unix); -1 = never scheduled.
func first_start(event_id: String) -> int:
	var first: int = -1
	for window in windows:
		if window != null and window.event_id == event_id:
			var start: int = window.start_unix()
			if first < 0 or start < first:
				first = start
	return first


## Shop sells the item at `unix` (-1 = now): not an event item, or its event has started at least once.
func is_released(item_id: String, unix: int = -1) -> bool:
	var at: int = now_unix() if unix < 0 else unix
	for event in events:
		if event != null and event.has_item(item_id):
			var start: int = first_start(event.id)
			return start >= 0 and at >= start
	return true


## Battle backgrounds of the event covers among `owned` item ids (borrowed now and then by regular battles).
func owned_backgrounds(owned: Array) -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	for event in events:
		if event != null and event.cover != null and event.cover.scene != null and owned.has(event.cover.id):
			scenes.append(event.cover.scene)
	return scenes
