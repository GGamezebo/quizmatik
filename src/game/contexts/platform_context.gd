class_name PlatformContext
extends HfsmBoundEntity

## Base for HFSM platform contexts. Payload of AppRoot `ev.open_platform`
## (`root_events`, `platform_services`, `music_player`) is forwarded unchanged to nested platform states.

var data: Dictionary = {}
var root_events: RootEvents = null
var services: PlatformServices = null


func _init(p_data: Dictionary = {}) -> void:
	data = p_data
	root_events = data.get("root_events") as RootEvents
	services = data.get("platform_services") as PlatformServices


## HFSM is bound only after `_init` → `add_event` works from `_enter` on, never from `_init`.
func sync_hfsm(hfsm: HFSM) -> void:
	super.sync_hfsm(hfsm)
	_enter()


## Override: platform setup + open nested platform states.
func _enter() -> void:
	pass


func open_child(event_name: String) -> void:
	add_event(event_name, data)


## Opens the store's `*Shop` child (ads + purchases). The single monetization kill switch:
## export feature `no_monetization` (tester presets) → no shop, no `App/Monetization`, no offers.
func open_shop(extra: Dictionary = {}) -> void:
	if OS.has_feature("no_monetization"):
		return
	add_event("ev.open_shop", data.merged(extra))


## Shop contexts: mount game-side `App/Monetization` (pacing, limits, paywall UI).
func open_monetization() -> void:
	add_event("ev.open_monetization", data)
