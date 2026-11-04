class_name EventCalendar
extends Resource

## Seasonal events config: what each event is (`events`, by `SeasonalEvent.id`) and when it runs (`windows`, UTC,
## one per year). A window whose event has no content yet is skipped (never shown). Event look items go on sale
## in the shop with the first window of their event and stay there for good (`is_released`).

@export var events: Array[SeasonalEvent] = []
@export var windows: Array[EventWindow] = []

## Dev-only preview (editor / `dev_lab` export, `DevBuild`), shared by calendar readers; never saved.
var _debug_window_key: String = ""


func debug_window() -> EventWindow:
	return find_window(_debug_window_key) if DevBuild.is_enabled() else null


func set_debug_window(key: String) -> bool:
	if not DevBuild.is_enabled():
		return false
	var window := find_window(key)
	if not key.is_empty() and (window == null or get_event(window.event_id) == null):
		return false
	_debug_window_key = key
	return true


## Preview uses a time inside the selected run; explicit historical queries stay real.
func current_unix() -> int:
	var window := debug_window()
	return clampi(now_unix(), window.start_unix(), window.end_unix() - 1) if window != null else now_unix()


## UTC unix seconds now.
static func now_unix() -> int:
	return int(Time.get_unix_time_from_system())


## Run open at `unix` (-1 = now) whose event has content; null = no event.
func active_window(unix: int = -1) -> EventWindow:
	if unix < 0 and debug_window() != null:
		return debug_window()
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


## Background of run `window`: its own `EventWindow.cover`, else its event's `cover`.
func run_cover(window: EventWindow) -> CoverItem:
	if window == null:
		return null
	if window.cover != null:
		return window.cover
	var event := get_event(window.event_id)
	return event.cover if event != null else null


## Menu button look of run `window`: its own `EventWindow.banner`, else its event's `banner`.
func run_banner(window: EventWindow) -> EventBanner:
	if window == null:
		return null
	if window.banner != null:
		return window.banner
	var event := get_event(window.event_id)
	return event.banner if event != null else null


## Event background with id `item_id` (an event's `cover` or a run's own one); null = none.
func find_cover(item_id: String) -> CoverItem:
	for cover in _covers():
		if cover.id == item_id:
			return cover
	return null


## Shop sells the item at `unix` (-1 = now): not an event item, or its event has started at least once
## (a run's own background: that run has started).
func is_released(item_id: String, unix: int = -1) -> bool:
	var at: int = now_unix() if unix < 0 else unix
	var run_start: int = -1
	for window in windows:
		if window != null and window.cover != null and window.cover.id == item_id:
			var start: int = window.start_unix()
			if run_start < 0 or start < run_start:
				run_start = start
	if run_start >= 0:
		return at >= run_start
	for event in events:
		if event != null and event.has_item(item_id):
			var start: int = first_start(event.id)
			return start >= 0 and at >= start
	return true


## Battle backgrounds of the event covers among `owned` item ids (borrowed now and then by regular battles).
func owned_backgrounds(owned: Array) -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	for cover in _covers():
		if cover.scene != null and owned.has(cover.id):
			scenes.append(cover.scene)
	return scenes


## Every event background once: events' `cover`, then runs' own ones.
func _covers() -> Array[CoverItem]:
	var covers: Array[CoverItem] = []
	for event in events:
		if event != null and event.cover != null and not covers.has(event.cover):
			covers.append(event.cover)
	for window in windows:
		if window != null and window.cover != null and not covers.has(window.cover):
			covers.append(window.cover)
	return covers
