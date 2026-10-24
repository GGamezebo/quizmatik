class_name HardFactsOverlay
extends CanvasLayer

## Full list of weak examples (overlay, not a stacked window). Closes on back button, tap on the dim, `ui_cancel`.

signal ev_closed

@export var screen: Control
@export var dim: Control
@export var rows_list: VBoxContainer
@export var scroll: ScrollContainer
@export var close_button: BaseButton
@export var row_scene: PackedScene

const FADE_DURATION: float = 0.22
const LAYOUT_SETTLE_FRAMES: int = 2

var _fade: Tween


func _ready() -> void:
	hide()
	close_button.pressed.connect(close)
	dim.gui_input.connect(_on_dim_gui_input)


## `rows` = `[{ "text": "7 × 8 = 56", "misses": 5 }, …]`, already ordered.
func open(rows: Array) -> void:
	for child in rows_list.get_children():
		rows_list.remove_child(child)
		child.free()
	for index in rows.size():
		var row_data: Dictionary = rows[index]
		var row: Control = row_scene.instantiate()
		row.initialize(index + 1, String(row_data.get("text", "")), int(row_data.get("misses", 1)))
		rows_list.add_child(row)
	scroll.scroll_vertical = 0
	screen.modulate.a = 0.0
	show()
	# New rows + the autowrapped subtitle take a couple of frames to lay out — stay transparent till then.
	for i in LAYOUT_SETTLE_FRAMES:
		await get_tree().process_frame
	if not visible:
		return
	if _fade != null:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(screen, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not visible:
		return
	hide()
	ev_closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_dim_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null and mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
		close()
