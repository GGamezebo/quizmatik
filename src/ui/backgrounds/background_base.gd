class_name BackgroundBase
extends IScene

## Shared scroll / paint / ink logic for every background variant.
## Variant .tscn files only supply art (TextureRect, particles, sky_textures).

const SCROLL_OFFSET_PARAM := &"scroll_offset"
const NEXT_TEXTURE_PARAM := &"next_texture"
const COLOR_AMOUNT_PARAM := &"color_amount"
const MIRROR_SEAMLESS_PARAM := &"mirror_seamless"

## Sky drift in texture widths per second. 0 keeps the sky static (menu, post battle).
@export_range(0.0, 0.2, 0.001) var sky_scroll_speed: float = 0.0
## Classic sky: scroll through a mirrored copy so left/right edges never seam.
@export var mirror_seamless: bool = false
## Pool of skies. Drawn without replacement until the deck is empty, then reshuffled.
## Empty → scroll the TextureRect texture against itself (or mirrored if mirror_seamless).
@export var sky_textures: Array[Texture2D] = []
## Battle: paint fills in with each correct answer (score / questions_count).
@export var paint_from_score: bool = false
@export var player: Player
@export var game_config: GameConfig
## Menu: paint fills in with completed daily slots (0..DAILY_SLOT_COUNT).
@export var paint_from_daily: bool = false
@export var daily_controller: DailyChallengesController
## Seconds to ease color after each correct answer / daily change.
@export_range(0.15, 2.0, 0.05) var paint_tween_seconds: float = 0.65
## Ease-in power for paint clarity: 1 = linear; higher = stays soft longer, pops at the end.
@export_range(1.0, 5.0, 0.1) var paint_curve_power: float = 2.8
## Clarity when not driven by score/dailies — keep soft so UI stays readable.
@export_range(0.0, 1.0, 0.01) var idle_color_amount: float = 0.1
## Fountain-pen ink stains left while shots fly (battle). Safe empty default for menu.
@export var ink_blot_scene: PackedScene
@export_range(8, 300, 1) var max_ink_blots: int = 140

@onready var _sky: TextureRect = $TextureRect
@onready var _ink_layer: Node2D = $InkLayer

var _sky_material: ShaderMaterial = null
var _scroll_offset: float = 0.0
var _deck: Array[Texture2D] = []
var _current_sky: Texture2D = null
var _next_sky: Texture2D = null
var _color_amount: float = 0.0
var _color_target: float = 0.0
var _paint_tween: Tween = null


func _ready() -> void:
	_sky_material = _sky.material as ShaderMaterial
	if _sky_material != null:
		# Instance-local copy so menu/battle don't share color_amount.
		_sky_material = _sky_material.duplicate() as ShaderMaterial
		_sky.material = _sky_material
		_sky_material.set_shader_parameter(MIRROR_SEAMLESS_PARAM, mirror_seamless)
	_bootstrap_skies()
	if paint_from_score:
		_color_amount = 0.0
		_color_target = 0.0
		_apply_color_amount()
		call_deferred("_bind_paint_score")
	elif paint_from_daily:
		_color_amount = idle_color_amount
		_color_target = idle_color_amount
		_apply_color_amount()
		call_deferred("_bind_paint_daily")
	else:
		_color_amount = idle_color_amount
		_color_target = idle_color_amount
		_apply_color_amount()
	get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()


func apply_host_config(config: Dictionary) -> void:
	## Called by BackgroundHost before add_child so _ready sees the values.
	if config.has("sky_scroll_speed"):
		sky_scroll_speed = config["sky_scroll_speed"]
	if config.has("mirror_seamless"):
		mirror_seamless = config["mirror_seamless"]
	if config.has("paint_from_score"):
		paint_from_score = config["paint_from_score"]
	if config.has("player"):
		player = config["player"]
	if config.has("game_config"):
		game_config = config["game_config"]
	if config.has("paint_from_daily"):
		paint_from_daily = config["paint_from_daily"]
	if config.has("daily_controller"):
		daily_controller = config["daily_controller"]
	if config.has("paint_tween_seconds"):
		paint_tween_seconds = config["paint_tween_seconds"]
	if config.has("paint_curve_power"):
		paint_curve_power = config["paint_curve_power"]
	if config.has("idle_color_amount"):
		idle_color_amount = config["idle_color_amount"]
	if config.has("ink_blot_scene") and config["ink_blot_scene"] != null:
		ink_blot_scene = config["ink_blot_scene"]
	if config.has("max_ink_blots"):
		max_ink_blots = config["max_ink_blots"]


func _bind_paint_score() -> void:
	if player == null:
		player = _find_player()
	if player == null:
		push_warning("BackgroundBase: paint_from_score on, but Player not found")
		return
	if not player.ev_score_changed.is_connected(_on_score_changed):
		player.ev_score_changed.connect(_on_score_changed)
	if game_config != null and not game_config.changed.is_connected(_on_game_config_changed):
		game_config.changed.connect(_on_game_config_changed)
	_set_color_target_from_score(player.score)
	_color_amount = _color_target
	_apply_color_amount()


func _bind_paint_daily() -> void:
	if daily_controller == null:
		push_warning("BackgroundBase: paint_from_daily on, but DailyChallengesController not set")
		return
	if not daily_controller.ev_daily_changed.is_connected(_on_daily_changed):
		daily_controller.ev_daily_changed.connect(_on_daily_changed)
	_set_color_target_from_daily()
	_color_amount = _color_target
	_apply_color_amount()


func _find_player() -> Player:
	var root := get_tree().current_scene
	if root == null:
		return null
	return root.find_child("Player", true, false) as Player


func _process(delta: float) -> void:
	if _sky_material == null or is_zero_approx(sky_scroll_speed):
		return
	_scroll_offset += sky_scroll_speed * delta
	# Mirror loop period is 2 (normal + flipped); sketch deck advances every 1 width.
	var period := 2.0 if mirror_seamless else 1.0
	while _scroll_offset >= period:
		_scroll_offset -= period
		if not mirror_seamless:
			_advance_sky()
	_sky_material.set_shader_parameter(SCROLL_OFFSET_PARAM, _scroll_offset)
	_ink_layer.position.x -= sky_scroll_speed * _sky.size.x * delta


func _on_score_changed(new_score: int) -> void:
	_set_color_target_from_score(new_score)
	_tween_paint_to_target()


func _on_game_config_changed() -> void:
	if player != null:
		_set_color_target_from_score(player.score)


func _on_daily_changed() -> void:
	_set_color_target_from_daily()
	_tween_paint_to_target()


func _set_color_target_from_score(score: int) -> void:
	if game_config == null or game_config.questions_count <= 0:
		_color_target = 1.0 if score > 0 else 0.0
		return
	var linear := clampf(float(score) / float(game_config.questions_count), 0.0, 1.0)
	_color_target = pow(linear, paint_curve_power)


func _set_color_target_from_daily() -> void:
	if daily_controller == null:
		_color_target = idle_color_amount
		return
	var linear := clampf(
		float(daily_controller.get_completed_count()) / float(PData.DAILY_SLOT_COUNT),
		0.0,
		1.0,
	)
	if is_zero_approx(linear):
		_color_target = idle_color_amount
		return
	_color_target = pow(linear, paint_curve_power)


func _tween_paint_to_target() -> void:
	if _sky_material == null:
		return
	if _paint_tween != null and _paint_tween.is_valid():
		_paint_tween.kill()
	_paint_tween = create_tween()
	_paint_tween.set_ease(Tween.EASE_OUT)
	_paint_tween.set_trans(Tween.TRANS_SINE)
	_paint_tween.tween_method(
		_set_color_amount_live,
		_color_amount,
		_color_target,
		paint_tween_seconds,
	)


func _set_color_amount_live(value: float) -> void:
	_color_amount = value
	_apply_color_amount()


func _apply_color_amount() -> void:
	if _sky_material != null:
		_sky_material.set_shader_parameter(COLOR_AMOUNT_PARAM, _color_amount)


func _bootstrap_skies() -> void:
	if sky_textures.is_empty():
		_current_sky = _sky.texture
		_next_sky = _sky.texture
		_apply_sky_pair()
		return
	_reshuffle_deck()
	_current_sky = _take_from_deck()
	_next_sky = _take_from_deck()
	_apply_sky_pair()


func _advance_sky() -> void:
	if sky_textures.is_empty():
		return
	_current_sky = _next_sky
	_next_sky = _take_from_deck()
	_apply_sky_pair()


func _take_from_deck() -> Texture2D:
	if _deck.is_empty():
		_reshuffle_deck()
	if _deck.is_empty():
		return _current_sky if _current_sky != null else _sky.texture
	var tex: Texture2D = _deck.pop_back()
	if tex == _current_sky and not _deck.is_empty():
		var other: Texture2D = _deck.pop_back()
		_deck.append(tex)
		return other
	return tex


func _reshuffle_deck() -> void:
	_deck.clear()
	for tex in sky_textures:
		if tex != null:
			_deck.append(tex)
	_deck.shuffle()


func _apply_sky_pair() -> void:
	if _current_sky != null:
		_sky.texture = _current_sky
	if _sky_material == null:
		return
	_sky_material.set_shader_parameter(MIRROR_SEAMLESS_PARAM, mirror_seamless)
	if _next_sky != null:
		_sky_material.set_shader_parameter(NEXT_TEXTURE_PARAM, _next_sky)
	_sky_material.set_shader_parameter(SCROLL_OFFSET_PARAM, _scroll_offset)
	_sky_material.set_shader_parameter(COLOR_AMOUNT_PARAM, _color_amount)


func spawn_ink_blot(global_pos: Vector2) -> void:
	if ink_blot_scene == null or _ink_layer == null:
		return
	while _ink_layer.get_child_count() >= max_ink_blots:
		var oldest: Node = _ink_layer.get_child(0)
		_ink_layer.remove_child(oldest)
		oldest.queue_free()
	var blot: InkBlot = ink_blot_scene.instantiate() as InkBlot
	if blot == null:
		return
	_ink_layer.add_child(blot)
	blot.setup(_ink_layer.to_local(global_pos))


func _fit_to_viewport() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_sky.position = Vector2.ZERO
	_sky.size = viewport_size

	for child in get_children():
		if child is GPUParticles2D:
			child.position = Vector2(viewport_size.x + 520.0, viewport_size.y * 0.5)
