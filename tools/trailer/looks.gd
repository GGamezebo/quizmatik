extends SceneTree

## Trailer take: cosmetic beats on real valley / cover art (PlaneFlyer, trails, ink, polaroid).
## Not loaded by the game. Run via `record.py looks`. Env: TRAILER_LOCALE, TRAILER_MUTE_MUSIC.

const FLYER_SCENE := "res://src/features/plane/plane_flyer.tscn"
const SHOT_SCENE := "res://src/features/shot/shot.tscn"
const VIEW := Vector2(1280, 720)

var catalog: CosmeticCatalog
var host: BackgroundHost
var flyer: PlaneFlyer
var shot_root: Node2D
var photo_layer: CanvasLayer
var photo_panel: Panel
var photo_flyer: PlaneFlyer
var photo_sticker: TextureRect
var _beats: Array[Dictionary] = []
var _beat := 0
var _beat_start := 0.0
var _t := 0.0
var _shot_marks: Array[float] = []
var _shots_done := 0


func _initialize() -> void:
	_locale_and_audio()
	catalog = load("res://src/common/cosmetics/cosmetic_catalog.tres")
	_beats = _build_beats()
	host = BackgroundHost.new()
	host.pick_random = false
	host.crossfade_seconds = 0.0
	host.idle_color_amount = 0.72
	host.sky_scroll_speed = 0.012
	host.variants = [ValleyBackgroundArt.get_scene("multiplication")]
	root.add_child(host)

	flyer = (load(FLYER_SCENE) as PackedScene).instantiate() as PlaneFlyer
	flyer.scale = Vector2(1.45, 1.45)
	flyer.z_index = 5
	flyer.position = Vector2(-160, 360)
	root.add_child(flyer)
	shot_root = Node2D.new()
	shot_root.z_index = 8
	root.add_child(shot_root)
	_build_photo()
	_apply_beat(_beats[0])
	print("TRAILER LOOKS beats %d end %.2f" % [_beats.size(), _end_at()])


func _locale_and_audio() -> void:
	if OS.get_environment("TRAILER_LOCALE") != "":
		TranslationServer.set_locale(OS.get_environment("TRAILER_LOCALE"))
	for i in AudioServer.bus_count:
		AudioServer.set_bus_mute(i, false)
	if OS.get_environment("TRAILER_MUTE_MUSIC") == "1":
		var music_bus := AudioServer.get_bus_index("Music")
		if music_bus >= 0:
			AudioServer.set_bus_mute(music_bus, true)


func _build_beats() -> Array[Dictionary]:
	# ~140 BPM: one look per beat, so the 6 s customization block can show the whole closet.
	return [
		{"dur": 0.46, "plane": "fast", "paint": "paint_none", "trail": "trail_pencil"},
		{"dur": 0.46, "plane": "starter", "paint": "paint_stripes", "trail": "trail_dash"},
		{"dur": 0.46, "plane": "green", "paint": "paint_dots", "trail": "trail_colored"},
		{"dur": 0.46, "plane": "red", "paint": "paint_checker", "trail": "trail_crayon"},
		{"dur": 0.46, "plane": "gold", "paint": "paint_stars", "trail": "trail_confetti"},
		{"dur": 0.50, "plane": "fast", "paint": "paint_rainbow", "trail": "trail_rainbow"},
		{"dur": 0.78, "kind": "ink", "plane": "gold", "paint": "paint_stars", "trail": "trail_rainbow",
			"shots": ["shot_rainbow", "shot_hearts", "shot_gold"]},
		{"dur": 0.50, "kind": "photo", "frame": "frame_gold", "sticker": "sticker_star", "plane": "gold"},
		{"dur": 0.46, "kind": "cover", "cover": "cover_space", "plane": "fast", "paint": "paint_stars", "trail": "trail_rainbow"},
		{"dur": 0.46, "kind": "cover", "cover": "cover_candy_kingdom", "plane": "green", "paint": "paint_rainbow", "trail": "trail_rainbow"},
		{"dur": 0.46, "kind": "cover", "cover": "cover_balloon_world", "plane": "gold", "paint": "paint_watercolor", "trail": "trail_confetti"},
		{"dur": 3.0, "kind": "loop", "plane": "fast", "paint": "paint_none", "trail": "trail_rainbow"},
	]


func _build_photo() -> void:
	photo_layer = CanvasLayer.new()
	photo_layer.layer = 20
	photo_layer.visible = false
	root.add_child(photo_layer)
	photo_panel = Panel.new()
	photo_panel.position = Vector2(430, 110)
	photo_panel.size = Vector2(420, 500)
	photo_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo_layer.add_child(photo_panel)
	var vpc := SubViewportContainer.new()
	vpc.position = Vector2(36, 36)
	vpc.size = Vector2(348, 400)
	vpc.stretch = true
	vpc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo_panel.add_child(vpc)
	var vp := SubViewport.new()
	vp.size = Vector2i(348, 400)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vpc.add_child(vp)
	var paper := ColorRect.new()
	paper.color = Color(1.0, 0.96, 0.9)
	paper.size = Vector2(348, 400)
	vp.add_child(paper)
	photo_flyer = (load(FLYER_SCENE) as PackedScene).instantiate() as PlaneFlyer
	photo_flyer.position = Vector2(230, 210)
	photo_flyer.scale = Vector2(0.95, 0.95)
	vp.add_child(photo_flyer)
	photo_sticker = TextureRect.new()
	photo_sticker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo_sticker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	photo_sticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo_sticker.position = Vector2(250, 330)
	photo_sticker.size = Vector2(130, 130)
	photo_panel.add_child(photo_sticker)


func _process(delta: float) -> bool:
	_t += delta
	if _beat >= _beats.size():
		return true
	var beat: Dictionary = _beats[_beat]
	var local := _t - _beat_start
	var dur := float(beat["dur"])
	_animate(beat, clampf(local / dur, 0.0, 1.0), local)
	if local >= dur:
		_beat += 1
		_beat_start = _t
		if _beat >= _beats.size():
			return true
		_apply_beat(_beats[_beat])
	return _t > _end_at() + 0.05


func _end_at() -> float:
	var total := 0.0
	for beat in _beats:
		total += float(beat["dur"])
	return total


func _apply_beat(beat: Dictionary) -> void:
	var kind := str(beat.get("kind", "fly"))
	print("TRAILER %.2f %s" % [_t, kind if kind != "fly" else str(beat.get("plane", ""))])
	_clear_shots()
	photo_layer.visible = kind == "photo"
	flyer.visible = kind != "photo"
	if kind == "cover":
		var cover := catalog.get_item(str(beat["cover"])) as CoverItem
		if cover != null and cover.scene != null:
			host.force_variant(cover.scene)
	elif kind == "loop":
		host.force_variant(ValleyBackgroundArt.get_scene("multiplication"))
	_apply_look(flyer, str(beat.get("plane", "fast")), str(beat.get("paint", "")), str(beat.get("trail", "")))
	if kind == "photo":
		_apply_look(photo_flyer, str(beat.get("plane", "fast")), "paint_stars", "trail_rainbow")
		if photo_flyer.trail != null:
			photo_flyer.trail.clear()
		var frame := catalog.get_item(str(beat.get("frame", ""))) as FrameItem
		if frame != null and frame.style != null:
			photo_panel.add_theme_stylebox_override("panel", frame.style)
		var sticker := catalog.get_item(str(beat.get("sticker", ""))) as StickerItem
		photo_sticker.texture = sticker.texture if sticker != null else null
	if kind == "ink":
		_shot_marks = [0.06, 0.32, 0.56]
		_shots_done = 0
	else:
		_shot_marks = []
		_shots_done = 0


func _apply_look(target: PlaneFlyer, plane_id: String, paint_id: String, trail_id: String) -> void:
	if target == null:
		return
	target.apply_plane(plane_id)
	if paint_id != "":
		target.apply_paint(catalog.get_item(paint_id) as PaintItem)
	if trail_id != "":
		target.apply_trail(catalog.get_item(trail_id) as TrailItem)
	if target.trail != null:
		target.trail.clear()


func _animate(beat: Dictionary, u: float, local: float) -> void:
	var kind := str(beat.get("kind", "fly"))
	if kind == "loop":
		var angle := lerpf(-0.4, TAU - 0.4, u)
		var tangent := Vector2(-sin(angle), cos(angle))
		flyer.position = Vector2(640, 360) + Vector2(cos(angle), sin(angle) * 0.62) * 210.0
		flyer.rotation = tangent.angle()
		return
	flyer.rotation = 0.0
	if kind == "photo":
		return
	var eased := u * u * (3.0 - 2.0 * u)
	flyer.position = Vector2(lerpf(-180.0, 1100.0, eased), 348.0 + sin(u * TAU) * 28.0)
	if kind == "ink":
		_spawn_due_shots(beat, local)


func _spawn_due_shots(beat: Dictionary, local: float) -> void:
	var ids: Array = beat.get("shots", [])
	while _shots_done < _shot_marks.size() and _shots_done < ids.size() and local >= _shot_marks[_shots_done]:
		_spawn_shot(str(ids[_shots_done]))
		_shots_done += 1


func _spawn_shot(item_id: String) -> void:
	var style := catalog.get_item(item_id) as ShotItem
	var shot := (load(SHOT_SCENE) as PackedScene).instantiate() as Area2D
	shot.scale = Vector2(0.42, 0.42)
	shot.collision_layer = 0
	shot.collision_mask = 0
	shot.set("monitoring", false)
	shot.set("monitorable", false)
	if style != null:
		shot.modulate = style.shot_tint
		shot.connect("ev_ink_drip", _on_ink.bind(style))
	shot_root.add_child(shot)
	var nozzle := flyer.get_node_or_null("Body/Nozzle") as Node2D
	shot.global_position = nozzle.global_position if nozzle != null else flyer.global_position


func _on_ink(pos: Vector2, style: ShotItem) -> void:
	host.spawn_ink_blot(pos, style)


func _clear_shots() -> void:
	for child in shot_root.get_children():
		child.queue_free()
