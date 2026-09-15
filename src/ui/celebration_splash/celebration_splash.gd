class_name CelebrationSplash
extends CanvasLayer

## Queued full-screen celebrations: valley unlock, new plane, daily gold.
## Not on the window stack. Hold while exam trophy dialog is up.

const KIND_VALLEY := "valley"
const KIND_PLANE := "plane"
const KIND_DAILY_GOLD := "daily_gold"
const FADE_DURATION: float = 0.22

@export var root_events: RootEvents
@export var screen: Control
@export var title_label: Label
@export var message_label: Label
@export var art_rect: TextureRect
@export var confirm_button: BaseButton
@export var levels_config: LevelsConfig

var _queue: Array[Dictionary] = []
var _busy: bool = false
var _held: bool = false
var _listener: EventListener = EventListener.new()


func _ready() -> void:
	hide()
	layer = 15
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if root_events != null:
		_listener.add(root_events.ev_show_celebration, _on_show_celebration)
		_listener.add(root_events.ev_celebration_hold, _on_hold)
		_listener.add(root_events.ev_celebration_unhold, _on_unhold)


func _exit_tree() -> void:
	_listener.deinit()


func enqueue(kind: String, payload: Dictionary = {}) -> void:
	_queue.append({"kind": kind, "payload": payload})
	_try_show_next()


func _on_show_celebration(kind: String, payload: Dictionary = {}) -> void:
	enqueue(kind, payload)


func _on_hold() -> void:
	_held = true


func _on_unhold() -> void:
	_held = false
	_try_show_next()


func _try_show_next() -> void:
	if _busy or _held or _queue.is_empty():
		return
	var item: Dictionary = _queue.pop_front()
	_present(String(item.get("kind", "")), item.get("payload", {}) as Dictionary)


func _present(kind: String, payload: Dictionary) -> void:
	_busy = true
	match kind:
		KIND_VALLEY:
			_present_valley(String(payload.get("container_id", "")))
		KIND_PLANE:
			_present_plane(String(payload.get("plane_id", PlaneCatalog.STARTER_ID)))
		KIND_DAILY_GOLD:
			_present_daily_gold()
		_:
			_busy = false
			_try_show_next()
			return
	screen.modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)


func _present_valley(container_id: String) -> void:
	title_label.text = "Долина открыта"
	message_label.text = _container_name(container_id)
	art_rect.modulate = Color.WHITE
	art_rect.texture = LevelPackArt.get_art(container_id)


func _present_plane(plane_id: String) -> void:
	var def: Dictionary = PlaneCatalog.get_def(plane_id)
	title_label.text = "У тебя новый самолёт!"
	message_label.text = String(def.get("name", ""))
	PlaneCatalog.apply_preview(art_rect, plane_id)


func _present_daily_gold() -> void:
	title_label.text = "Молодец! +1 золотая"
	message_label.text = "Награда за ежедневную серию 5/5"
	art_rect.texture = preload("res://assets/ui/stamps/stamp_sun.png")
	art_rect.modulate = Color.WHITE


func _container_name(container_id: String) -> String:
	if levels_config == null or container_id.is_empty():
		return container_id
	var container: Dictionary = levels_config.find_container_in_config(container_id)
	return String(container.get("name", container_id))


func _on_confirm_pressed() -> void:
	hide()
	_busy = false
	_try_show_next()
