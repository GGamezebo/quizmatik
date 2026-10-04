class_name MenuCover
extends Node

## Main menu background = the active profile's equipped cover (`CoverItem`).
## Sits before `host` in the tree: sets its variant before the host mounts (no crossfade on open),
## later profile / cover changes crossfade via `BackgroundHost.force_variant`.

@export var host: BackgroundHost
@export var pdata: PData
@export var catalog: CosmeticCatalog
@export var root_events: RootEvents

var _listener: EventListener = EventListener.new()


func _ready() -> void:
	var scene := _cover_scene()
	if host != null and scene != null:
		host.variants = [scene]
		host.pick_random = false
		host.fixed_variant_index = 0
	if root_events != null:
		_listener.add(root_events.ev_profiles_changed, _apply)


func _exit_tree() -> void:
	_listener.deinit()


func _apply() -> void:
	var scene := _cover_scene()
	if host != null and scene != null:
		host.force_variant(scene)


func _cover_scene() -> PackedScene:
	if catalog == null or pdata == null:
		return null
	var cover := catalog.equipped_item(CosmeticItem.Slot.COVER, pdata.cosmetics.equipped) as CoverItem
	return cover.scene if cover != null else null
