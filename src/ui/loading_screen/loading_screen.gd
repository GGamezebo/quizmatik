extends CanvasLayer

## HFSM loading overlay (`HfsmSceneRegistry`): `update_progress(0..1)` while loading, `fade_out()` when mounted.
## Equipped plane hovers on notebook sky; on fade it flies off right, then the sheet slides up.

const SKY_SCROLL_PARAM := &"scroll_offset"
const GRID_SIZE_PARAM := &"rect_size"

## Shared live profile (same cached `.tres` as AppRoot) → `equipped_plane_id`. Isolated run → starter.
@export var pdata: PData
## Equipped paint / trail on the flyer; null or no profile → catalog defaults.
@export var cosmetics: CosmeticCatalog
@export var sheet: Control
@export var sky: TextureRect
@export var grid: ColorRect
@export var flyer: PlaneFlyer
@export var progress_bar: ProgressBar
@export var status_label: Label
@export var fact_label: Label
## Shown by progress thirds (last one near the end).
@export var status_lines: Array[String] = ["Заводим мотор…", "Проверяем крылья…", "Взлетаем!"]
@export var fact_prefix: String = "А ты знаешь?"
@export_range(0.0, 0.2, 0.001) var sky_scroll_speed: float = 0.015
## Fraction of the bar per second the shown value chases the real one (no jumps on web).
@export var progress_follow_speed: float = 1.8
@export var fly_in_sec: float = 0.5
@export var fly_away_sec: float = 0.55
@export var slide_sec: float = 0.45

var _target_progress: float = 0.0
var _shown_progress: float = 0.0
var _sky_offset: float = 0.0
var _sky_material: ShaderMaterial
var _grid_material: ShaderMaterial
var _leaving: bool = false


func _ready() -> void:
	_sky_material = sky.material as ShaderMaterial
	_grid_material = grid.material as ShaderMaterial
	grid.resized.connect(_on_grid_resized)
	_on_grid_resized()
	var plane_id := pdata.equipped_plane_id if pdata != null else PlaneCatalog.STARTER_ID
	flyer.apply_plane(plane_id)
	_apply_cosmetics()
	fact_label.text = tr(fact_prefix) + "  " + _random_fact()
	_apply_progress()
	_fly_in()


func _apply_cosmetics() -> void:
	if cosmetics == null:
		return
	var equipped: Dictionary = pdata.cosmetics.equipped if pdata != null else {}
	flyer.apply_paint(cosmetics.equipped_item(CosmeticItem.Slot.PAINT, equipped) as PaintItem)
	flyer.apply_trail(cosmetics.equipped_item(CosmeticItem.Slot.TRAIL, equipped) as TrailItem)


func update_progress(value: float) -> void:
	_target_progress = clampf(value, 0.0, 1.0)


func fade_out() -> void:
	if _leaving:
		return
	_leaving = true
	_target_progress = 1.0
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := sheet.get_viewport_rect().size
	var tween := create_tween()
	tween.tween_property(flyer, "position:x", vp.x * 0.5 + 420.0, fly_away_sec) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "offset:y", -vp.y, slide_sec) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sheet, "modulate:a", 0.0, slide_sec) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)


func _process(delta: float) -> void:
	_shown_progress = move_toward(_shown_progress, _target_progress, progress_follow_speed * delta)
	_apply_progress()
	if _sky_material != null:
		_sky_offset = fmod(_sky_offset + sky_scroll_speed * delta, 2.0)
		_sky_material.set_shader_parameter(SKY_SCROLL_PARAM, _sky_offset)


func _apply_progress() -> void:
	progress_bar.value = _shown_progress * 100.0
	if status_lines.is_empty():
		return
	var index := mini(int(_shown_progress * status_lines.size()), status_lines.size() - 1)
	status_label.text = status_lines[index]


func _fly_in() -> void:
	var home_x := flyer.position.x
	flyer.position.x = -sheet.get_viewport_rect().size.x * 0.5 - 260.0
	create_tween().tween_property(flyer, "position:x", home_x, fly_in_sec) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_grid_resized() -> void:
	if _grid_material != null:
		_grid_material.set_shader_parameter(GRID_SIZE_PARAM, grid.size)


func _random_fact() -> String:
	var family := MathFact.FAMILY_MUL if randf() < 0.5 else MathFact.FAMILY_ADD
	return MathFact.display_with_answer(MathFact.make_key(family, randi_range(2, 9), randi_range(2, 9)))
