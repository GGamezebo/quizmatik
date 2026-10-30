class_name EventsController
extends Node

## Seasonal events of the active profile (`PData.events`, keys = `EventWindow.key()`): the run open now
## (`calendar`), won event battles → gift boxes, boxes the menu banner already showed flying off.
## Gifts go through `cosmetics` (`CosmeticsController.grant`); gold from `register_win` is granted by AppRoot.
## Menu / post-battle copies only read (and mark shown boxes); only AppRoot's copy registers wins.

@export var pdata: PData
@export var calendar: EventCalendar
## Grants gifts (AppRoot sibling); empty in read-only copies.
@export var cosmetics: CosmeticsController
@export var root_events: RootEvents


## AppRoot's copy (the one that grants gifts); null outside the app.
static func find_in_tree(tree: SceneTree) -> EventsController:
	if tree == null:
		return null
	for node in tree.root.find_children("*", "EventsController", true, false):
		var events := node as EventsController
		if events != null and events.cosmetics != null:
			return events
	return null


## Run open now with content; null = no event (`unix` -1 = now).
func active_window(unix: int = -1) -> EventWindow:
	return calendar.active_window(unix) if calendar != null else null


func event_of(window: EventWindow) -> SeasonalEvent:
	if window == null or calendar == null:
		return null
	return calendar.get_event(window.event_id)


## Won event battles of run `key`.
func wins(key: String) -> int:
	return int(pdata.events.wins.get(key, 0))


func opened_boxes(window: EventWindow) -> int:
	var event := event_of(window)
	if event == null:
		return 0
	return mini(wins(window.key()), event.box_count())


## Opened boxes the menu banner already showed flying off (never more than opened).
func shown_boxes(window: EventWindow) -> int:
	if window == null:
		return 0
	return mini(int(pdata.events.shown.get(window.key(), 0)), opened_boxes(window))


## The banner played the fly-off of every opened box.
func mark_boxes_shown(window: EventWindow) -> void:
	if window == null or shown_boxes(window) >= opened_boxes(window):
		return
	pdata.events.shown[window.key()] = opened_boxes(window)
	_save()


## Chase timer (minutes) of the next battle of this run.
func chase_minutes(window: EventWindow) -> int:
	var event := event_of(window)
	if event == null:
		return 0
	return event.chase_minutes(wins(window.key()))


## Won event battle of run `key`: the next box opens. Its gift is granted (already owned → its price in gold);
## the last box also gives the cover (owned → its price). Every box open already → `completion_gold()`.
## Returns {} for an unknown run, else {"event_id", "box" (opened index, -1 = none left), "gift_id", "gift_refund",
## "cover_id", "cover_refund", "gold" (total gold for AppRoot to grant)}.
func register_win(key: String) -> Dictionary:
	var window: EventWindow = calendar.find_window(key) if calendar != null else null
	var event := event_of(window)
	if event == null:
		return {}
	var won: int = wins(key)
	pdata.events.wins[key] = won + 1
	var result := {
		"event_id": event.id,
		"box": -1,
		"gift_id": "",
		"gift_refund": false,
		"cover_id": "",
		"cover_refund": false,
		"gold": 0,
	}
	if won >= event.box_count():
		result["gold"] = event.completion_gold()
		_save()
		return result
	result["box"] = won
	var gift := event.gift(won)
	if gift != null:
		result["gift_id"] = gift.id
		if not _grant(gift):
			result["gift_refund"] = true
			result["gold"] = gift.gold_cost
	if won + 1 == event.box_count() and event.cover != null:
		result["cover_id"] = event.cover.id
		if not _grant(event.cover):
			result["cover_refund"] = true
			result["gold"] = int(result["gold"]) + event.cover.gold_cost
	_save()
	return result


## Dev lab: the run starts over — no wins, every box closed, its gifts and cover taken back (bought ones too),
## so the boxes give items again instead of coins.
func reset_run(key: String) -> void:
	pdata.events.wins.erase(key)
	pdata.events.shown.erase(key)
	var event := event_of(calendar.find_window(key) if calendar != null else null)
	if event != null and cosmetics != null:
		for item in event.gifts + [event.cover]:
			cosmetics.revoke(item)
	_save()


func _grant(item: CosmeticItem) -> bool:
	return cosmetics != null and cosmetics.grant(item)


func _save() -> void:
	if root_events != null:
		root_events.ev_save_progress.emit()
