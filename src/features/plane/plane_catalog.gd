class_name PlaneCatalog
extends RefCounted

## Data for the five player planes. UI and combat read this — do not hardcode stats in windows.
## Planes differ only by `speed_mult` (flight) and `shot_speed_mult` (projectile); no other perks.
## Look: own art column `atlas_column` in `planes_atlas_spaced.png` (cells 288x108, rows
## idle / down / up): 0 pencil (base art), 1 ballpoint pen, 2 marker, 3 ruler, 4 fountain pen —
## columns 1+ built by `tools/generate_plane_variants.py`, already colored (`tint` stays white).
## `flame_offset`: shift of the exhaust flame from its scene position (drawn planes have a nozzle).

const STARTER_ID := "starter"
const ORDER: Array[String] = ["starter", "fast", "green", "red", "gold"]
const CELL_SIZE := Vector2(288, 108)
## SpriteFrames animation -> atlas row (same as `plane_frames.tres`).
const ANIMATION_ROWS: Dictionary = {"idle": 0, "down": 1, "up": 2}

static var _frames_cache: Dictionary = {}

const DEFS: Dictionary = {
	"starter": {
		"id": "starter",
		"flame_offset": Vector2(-11, 0),
		"atlas_column": 1,
		"name": "Фиолетовый",
		"tint": Color(1.0, 1.0, 1.0),
		"speed_mult": 0.65,
		"shot_speed_mult": 1.0,
		"gold_cost": 0,
		"exam_container_id": "",
		"badge": "",
	},
	"fast": {
		"id": "fast",
		"flame_offset": Vector2(0, 0),
		"atlas_column": 0,
		"name": "Быстрый",
		"tint": Color(1.0, 1.0, 1.0),
		"speed_mult": 1.0,
		"shot_speed_mult": 1.1,
		"gold_cost": 1,
		"exam_container_id": "addition",
		"badge": "быстрый",
	},
	"green": {
		"id": "green",
		"flame_offset": Vector2(-11, 0),
		"atlas_column": 2,
		"name": "Зелёный",
		"tint": Color(1.0, 1.0, 1.0),
		"speed_mult": 1.1,
		"shot_speed_mult": 1.2,
		"gold_cost": 5,
		"exam_container_id": "subtraction",
		"badge": "быстрее",
	},
	"red": {
		"id": "red",
		"flame_offset": Vector2(-11, 0),
		"atlas_column": 3,
		"name": "Красный",
		"tint": Color(1.0, 1.0, 1.0),
		"speed_mult": 1.2,
		"shot_speed_mult": 1.35,
		"gold_cost": 10,
		"exam_container_id": "multiplication",
		"badge": "ещё быстрее",
	},
	"gold": {
		"id": "gold",
		"flame_offset": Vector2(-11, 0),
		"atlas_column": 4,
		"name": "Золотой",
		"tint": Color(1.0, 1.0, 1.0),
		"speed_mult": 1.3,
		"shot_speed_mult": 1.5,
		"gold_cost": 20,
		"exam_container_id": "division",
		"badge": "самый быстрый",
	},
}


static func get_def(plane_id: String) -> Dictionary:
	if DEFS.has(plane_id):
		return DEFS[plane_id]
	return DEFS[STARTER_ID]


static func plane_id_for_exam(container_id: String) -> String:
	if container_id.is_empty():
		return ""
	for plane_id in ORDER:
		if String(DEFS[plane_id].get("exam_container_id", "")) == container_id:
			return plane_id
	return ""


static func atlas_texture() -> Texture2D:
	return preload("res://src/features/plane/planes_atlas_spaced.png")


static func frame_texture(plane_id: String, animation: StringName) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = atlas_texture()
	var column := int(get_def(plane_id).get("atlas_column", 0))
	var row := int(ANIMATION_ROWS.get(String(animation), 0))
	tex.region = Rect2(Vector2(column, row) * CELL_SIZE, CELL_SIZE)
	return tex


static func idle_texture(plane_id: String) -> AtlasTexture:
	return frame_texture(plane_id, &"idle")


## Copy of `base` (animation names / loop / speed kept) showing this plane's atlas frames.
## Cached per plane: every plane sprite shares the `plane_frames.tres` layout.
static func sprite_frames(plane_id: String, base: SpriteFrames) -> SpriteFrames:
	var key := String(get_def(plane_id).get("id", STARTER_ID))
	if _frames_cache.has(key):
		return _frames_cache[key]
	var frames := base.duplicate() as SpriteFrames
	for animation in frames.get_animation_names():
		for i in frames.get_frame_count(animation):
			frames.set_frame(animation, i, frame_texture(plane_id, animation), frames.get_frame_duration(animation, i))
	_frames_cache[key] = frames
	return frames


## Places the exhaust flame for `plane_id`; `home` = flame position saved from the scene.
static func flame_position(plane_id: String, home: Vector2) -> Vector2:
	return home + (get_def(plane_id).get("flame_offset", Vector2.ZERO) as Vector2)


## `paint` needs a `plane_body.gdshader` material on the rect (else ignored).
static func apply_preview(rect: TextureRect, plane_id: String, paint: PaintItem = null) -> void:
	if rect == null:
		return
	rect.texture = idle_texture(plane_id)
	var tint := get_def(plane_id).get("tint", Color.WHITE) as Color
	var mat := rect.material as ShaderMaterial
	if mat != null:
		rect.modulate = Color.WHITE
		mat.set_shader_parameter("sprite_tint", tint)
		apply_paint(mat, paint)
	else:
		rect.modulate = tint


## Pushes a `PaintItem` into a `plane_body.gdshader` material. Null item = no pattern.
static func apply_paint(material: Material, item: PaintItem) -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		return
	if item == null:
		mat.set_shader_parameter("paint_pattern", PaintItem.Pattern.NONE)
		return
	mat.set_shader_parameter("paint_pattern", item.pattern)
	mat.set_shader_parameter("paint_color_a", item.color_a)
	mat.set_shader_parameter("paint_color_b", item.color_b)
	mat.set_shader_parameter("paint_cell_px", item.cell_px)
	mat.set_shader_parameter("paint_strength", item.strength)
