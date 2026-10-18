extends Node

## Main-menu shop button: pulses while the active profile can afford something not owned yet
## (a plane from `PlaneCatalog` or a look item from `catalog`). Re-checks on `ev_profiles_changed`
## (gold / purchases / profile switch) and when the button is shown again.

@export var root_events: RootEvents
@export var pdata: PData
@export var catalog: CosmeticCatalog
@export var button: Control
@export var pulse: UiPulse

var _listener: EventListener = EventListener.new()


func _ready() -> void:
	if root_events:
		_listener.add(root_events.ev_profiles_changed, _refresh)
	if button:
		button.visibility_changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	_listener.deinit()


func _refresh() -> void:
	pulse.set_active(button != null and button.is_visible_in_tree() and _can_buy_anything())


func _can_buy_anything() -> bool:
	if pdata == null:
		return false
	for plane_id in PlaneCatalog.ORDER:
		var cost := int(PlaneCatalog.get_def(plane_id).get("gold_cost", 0))
		if cost > 0 and cost <= pdata.gold and not pdata.unlocked_planes.has(plane_id):
			return true
	return catalog != null and catalog.has_affordable(pdata.gold, pdata.cosmetics.owned)
