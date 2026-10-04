class_name CosmeticCard
extends Button

## One look item in the hangar paint tab. Press (or focus) = try on; buying happens in the page.

signal ev_selected(item: CosmeticItem)

@export var plane_preview: TextureRect
@export var swatch: CosmeticSwatch
@export var icon_rect: TextureRect
@export var frame_panel: PanelContainer
@export var frame_photo: TextureRect
@export var name_label: Label
@export var cost_row: Control
@export var cost_label: Label
@export var status_label: Label

var item: CosmeticItem = null


func _ready() -> void:
	toggle_mode = true
	pressed.connect(_on_pressed)
	focus_entered.connect(_on_pressed)


## `plane_id` = equipped plane (paint preview tint).
func setup(new_item: CosmeticItem, plane_id: String, owned: bool, equipped: bool) -> void:
	item = new_item
	name_label.text = item.title
	plane_preview.visible = item is PaintItem
	swatch.visible = item is TrailItem or item is ShotItem
	frame_panel.visible = item is FrameItem
	icon_rect.visible = item is StickerItem or item is CoverItem
	if item is PaintItem:
		PlaneCatalog.apply_preview(plane_preview, plane_id, item as PaintItem)
	elif swatch.visible:
		swatch.set_item(item)
	elif item is FrameItem:
		var style := (item as FrameItem).style
		if style != null:
			frame_panel.add_theme_stylebox_override("panel", style)
		PlaneCatalog.apply_preview(frame_photo, plane_id)
	else:
		icon_rect.texture = item.icon
	set_state(owned, equipped)


func set_state(owned: bool, equipped: bool) -> void:
	cost_row.visible = not owned
	cost_label.text = str(item.gold_cost)
	status_label.visible = owned
	status_label.text = "✓ надето" if equipped else "есть"


func _on_pressed() -> void:
	if item != null:
		button_pressed = true
		ev_selected.emit(item)
