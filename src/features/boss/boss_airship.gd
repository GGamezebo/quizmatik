class_name BossAirship
extends Node2D

## Boss airship: flies in from the right, hovers behind the balloons and loses one armor plate per
## `hit()` (a star flies from the popped balloon into the plate). Last plate → it gets angry: turns red,
## creeps slowly up to the plane (stops just short of its nose at `rage_stop_x`) and takes `rage_hits` shots
## on its `hitbox` (`take_shot`) before going down in flames. The rage is pure shooting fun, no threat.
## Plates = editor-placed slots; `initialize(armor)` shows an evenly spread subset.
## Chase level: `setup_chaser(variant)` instead — no fly-in / fight, the battle moves it (`ChaseController`).

## Reached the hover point — the fight can start.
signal ev_entered
## A hit's star reached the boss and knocked a plate off (0 = last one, the rage starts).
signal ev_hit_landed(armor_left: int)
## No armor left: angry, shootable (`hits` shots to go).
signal ev_enraged(hits: int)
## Fell off-screen after the last rage shot.
signal ev_destroyed

@export var visual: Node2D
@export var body: CanvasItem
## Color variants of the hull (output of `tools/generate_boss_variants.py`); one picked at random
## per boss. Empty = keep the editor texture.
@export var body_variants: Array[Texture2D] = []
@export var propeller: Node2D
## Armor plate slots; shown subset is spread evenly over this order.
@export var plates: Array[Node2D] = []
## Star flying from the popped balloon into the plate (`top_level`).
@export var spark: Node2D
@export var explosion_scene: PackedScene

## Shootable hull while angry (group `shot_targets`; physics layer enabled only during the rage).
@export var hitbox: Area2D

@export_group("Rage")
@export var rage_hits: int = 15
## Physics layer bits the hitbox gets while angry (5 = shot targets; never the answers' layer 3).
@export_flags_2d_physics var rage_hitbox_layer: int = 16
## Freezes once its center is this far right of the play area's left edge: hull nose (~220 px left of center)
## stops just short of the plane nose (~405 px global).
@export var rage_stop_x: float = 645.0
## Average creep speed toward the plane, px/s (eases out: slows down as it closes in).
@export var rage_speed: float = 45.0
## Pause (growl + shake) before it starts creeping.
@export var rage_growl_sec: float = 0.8
## Hull tint while angry (body shader `sprite_tint`).
@export var rage_tint: Color = Color(1.0, 0.6, 0.55)
## Slow angry up/down sweep across the lanes.
@export var rage_bob_strength: float = 70.0
@export var rage_bob_speed: float = 0.9
@export var rage_shot_shake: float = 0.45

@export_group("Released balloons")
## Gondola point the balloons fly out of.
@export var hatch: Node2D
## Parent for tether strings (behind the hull).
@export var tethers: Node2D
## One string (editor template `boss_tether.tscn`).
@export var tether_scene: PackedScene
## Released balloons stop this far left of the hatch, then fly on as usual.
@export var launch_inset_x: float = 60.0
## String snaps once its balloon is this far from the hatch.
@export var tether_snap_length: float = 320.0
## String knot below the balloon center (balloon local px, scaled with it).
@export var tether_knot_offset: float = 66.0
@export var tether_sag: float = 26.0

@export_group("Chase")
## Hull nose x in `visual` space (art faces left) — the point that touches the plane when chasing.
@export var nose_x: float = -225.0
## Hull tint while a chaser is close to the plane (`set_menacing`).
@export var menace_tint: Color = Color(1.0, 0.7, 0.66)
## Restless shake kept up while menacing.
@export var menace_shake: float = 0.22

@export_group("Layout")
## Hover point = this far left of the play area's right edge, vertically centered.
@export var hover_inset_x: float = 230.0
## Spawn this far right of the play area (fully off-screen).
@export var spawn_offset_x: float = 420.0

@export_group("Motion")
@export var enter_duration: float = 2.2
@export var spark_duration: float = 0.32
@export var plate_fall_duration: float = 1.0
@export var fall_duration: float = 2.4
@export var fall_explosions: int = 6
@export var bob_speed: float = 1.3
@export var bob_strength: float = 9.0
@export var sway_degrees: float = 1.6
@export var propeller_speed: float = 22.0
@export var shake_strength: float = 10.0
@export var flash_color: Color = Color(1.7, 1.6, 1.5)

var _armor_left: int = 0
var _armor_plates: Array[Node2D] = []
var _play_area: Rect2 = Rect2()
var _time: float = 0.0
var _shake: float = 0.0
var _falling: bool = false
var _raging: bool = false
var _rage_left: int = 0
## `initialize(..., rage_shots <= 0)`: last plate off → it goes down at once, no angry phase.
var _no_rage: bool = false
var _rage_tween: Tween
var _spark_tween: Tween
var _flash_tween: Tween
## Live strings: Line2D → balloon it holds.
var _strings: Dictionary = {}
## Chase level: hull color index into `body_variants` (-1 = random) and the close-in look.
var _variant: int = -1
var _menacing: bool = false
var _tint_tween: Tween


func initialize(armor: int, play_area: Rect2, rage_shots: int) -> void:
	_armor_left = maxi(armor, 1)
	_play_area = play_area
	_no_rage = rage_shots <= 0
	rage_hits = maxi(rage_shots, 1)
	_pick_plates()


## Chase level: one of the chasers, `variant` = hull color (index into `body_variants`). Call before adding it.
func setup_chaser(variant: int) -> void:
	_variant = variant
	_time = randf() * TAU


## Distance from the origin to the hull nose (px, any facing; parent unscaled).
func get_nose_reach() -> float:
	var visual_scale: float = visual.scale.x if visual else 1.0
	return absf(nose_x * visual_scale * scale.x)


## Chasing: closed in on the plane — reddish hull, fast propeller, restless shake (`false` = calm again).
func set_menacing(on: bool) -> void:
	if _menacing == on:
		return
	_menacing = on
	if on:
		_shake = 1.0
	_tween_tint(menace_tint if on else Color.WHITE, 0.35)


func _ready() -> void:
	var sprite := body as Sprite2D
	if sprite and not body_variants.is_empty():
		sprite.texture = body_variants[_variant % body_variants.size()] if _variant >= 0 else body_variants.pick_random()
	if spark:
		spark.visible = false
	if hitbox:
		hitbox.collision_layer = 0
		hitbox.collision_mask = 0
	if _armor_left <= 0:
		# Isolated F6 run: full armor, stays where placed.
		_armor_left = plates.size()
		_pick_plates()
	if _play_area.has_area():
		_enter()


func _process(delta: float) -> void:
	_time += delta
	if propeller:
		propeller.scale.y = cos(_time * propeller_speed * (2.0 if _raging or _menacing else 1.0))
	_update_strings()
	if visual == null or _falling:
		return
	_shake = move_toward(_shake, menace_shake if _menacing else 0.0, delta * 3.0)
	var jitter := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength * _shake
	var bob: float = sin(_time * bob_speed) * bob_strength
	var sway: float = sway_degrees
	if _raging:
		bob = sin(_time * rage_bob_speed) * rage_bob_strength
		sway *= 2.5
	visual.position = Vector2(0.0, bob) + jitter
	visual.rotation = deg_to_rad(sin(_time * bob_speed * 0.7) * sway)


## Knocks one plate off (after the star lands); returns armor left. 0 → the boss goes down.
func hit(from_global: Vector2) -> int:
	if _armor_left <= 0:
		return 0
	_armor_left -= 1
	var left: int = _armor_left
	# More armor than plate slots: early hits only shake the hull, plates go once they match.
	var plate: Node2D = _armor_plates.pop_back() if _armor_plates.size() > left else null
	var target: Vector2 = plate.global_position if plate else global_position
	if spark == null:
		_land_hit(plate, left)
		return left
	if _spark_tween:
		_spark_tween.kill()
	spark.global_position = from_global
	spark.scale = Vector2.ONE
	spark.visible = true
	_spark_tween = create_tween()
	_spark_tween.tween_property(spark, "global_position", target, spark_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_spark_tween.parallel().tween_property(spark, "rotation", spark.rotation + TAU, spark_duration)
	_spark_tween.tween_callback(_land_hit.bind(plate, left))
	return left


## Shot hit `hitbox` while angry; returns shots left (0 → it goes down), -1 = not shootable now.
func take_shot(_hit_point: Vector2) -> int:
	if not _raging:
		return -1
	_rage_left -= 1
	_shake = maxf(_shake, rage_shot_shake)
	_flash()
	if _rage_left > 0:
		return _rage_left
	_raging = false
	hitbox.collision_layer = 0
	if _rage_tween:
		_rage_tween.kill()
	_fall()
	return 0


func is_hitbox(area: Area2D) -> bool:
	return hitbox != null and area == hitbox


## Global point released balloons fly out of.
func get_launch_point() -> Vector2:
	return hatch.global_position if hatch else global_position


## Where released balloons stop before flying on (global x).
func get_launch_x() -> float:
	return get_launch_point().x - launch_inset_x


## Ties a string from the gondola to `balloon`; it snaps when the balloon flies off or dies.
func tether(balloon: Node2D) -> void:
	if tether_scene == null or tethers == null:
		return
	var line: Line2D = tether_scene.instantiate()
	line.visible = false
	tethers.add_child(line)
	_strings[line] = balloon


func _update_strings() -> void:
	if _strings.is_empty():
		return
	var start: Vector2 = tethers.to_local(get_launch_point())
	for line: Line2D in _strings.keys():
		# Freed balloons stay in the dict until the string snaps; a typed assign errors on them.
		if not is_instance_valid(_strings[line]) or _falling:
			_snap(line)
			continue
		var balloon: Node2D = _strings[line]
		if not balloon.is_inside_tree():
			continue
		var knot: Vector2 = balloon.global_position + Vector2(0.0, tether_knot_offset * balloon.scale.y)
		var end: Vector2 = tethers.to_local(knot)
		# Popped balloons fade out — let go of them right away.
		if start.distance_to(end) > tether_snap_length or balloon.modulate.a < 0.95:
			_snap(line)
			continue
		var mid: Vector2 = (start + end) * 0.5 + Vector2(0.0, tether_sag)
		line.points = PackedVector2Array([start, mid, end])
		line.visible = true


## String torn: the loose end curls up and fades.
func _snap(line: Line2D) -> void:
	_strings.erase(line)
	if not line.visible:
		line.queue_free()
		return
	var points: PackedVector2Array = line.points
	if points.size() == 3:
		points[2] = points[1] + (points[2] - points[1]) * 0.35 + Vector2(0.0, 18.0)
		line.points = points
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.35)
	tween.tween_callback(line.queue_free)


func _pick_plates() -> void:
	_armor_plates.clear()
	var count: int = mini(_armor_left, plates.size())
	for plate in plates:
		plate.visible = false
	for i in count:
		var plate: Node2D = plates[floori(float(i) * plates.size() / count)]
		plate.visible = true
		_armor_plates.append(plate)
	_armor_plates.shuffle()


func _enter() -> void:
	var hover := Vector2(_play_area.end.x - hover_inset_x, _play_area.get_center().y)
	position = Vector2(_play_area.end.x + spawn_offset_x, hover.y)
	var tween := create_tween()
	tween.tween_property(self, "position", hover, enter_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(ev_entered.emit)


func _land_hit(plate: Node2D, armor_left: int) -> void:
	if spark:
		spark.visible = false
	var point: Vector2 = plate.global_position if plate else global_position
	_spawn_explosion(point, 1.2)
	_shake = 1.0
	_flash()
	if plate:
		_drop_plate(plate)
	ev_hit_landed.emit(armor_left)
	if armor_left <= 0:
		if _no_rage:
			_fall()
		else:
			_enrage()


func _enrage() -> void:
	_raging = true
	_rage_left = rage_hits
	_shake = 1.0
	if hitbox:
		hitbox.collision_layer = rage_hitbox_layer
	_tween_tint(rage_tint, 0.4)
	ev_enraged.emit(rage_hits)
	var stop_x: float = _play_area.position.x + rage_stop_x
	var distance: float = maxf(position.x - stop_x, 0.0)
	_rage_tween = create_tween()
	_rage_tween.tween_interval(rage_growl_sec)
	_rage_tween.tween_property(self, "position:x", stop_x, distance / maxf(rage_speed, 1.0))		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Arrived: one more angry shudder, then it just hangs there.
	_rage_tween.tween_property(self, "_shake", 0.8, 0.05)


## Hull shader `sprite_tint` from its current value to `to`.
func _tween_tint(to: Color, duration: float) -> void:
	if body == null or not body.material is ShaderMaterial:
		return
	var mat := body.material as ShaderMaterial
	var from: Variant = mat.get_shader_parameter("sprite_tint")
	if _tint_tween:
		_tint_tween.kill()
	_tint_tween = create_tween()
	_tint_tween.tween_method(func(c: Color) -> void: mat.set_shader_parameter("sprite_tint", c),
		from if from is Color else Color.WHITE, to, duration)


func _drop_plate(plate: Node2D) -> void:
	var tween := plate.create_tween().set_parallel(true)
	tween.tween_property(plate, "position", plate.position + Vector2(randf_range(-40.0, 40.0), 360.0), plate_fall_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(plate, "rotation", plate.rotation + randf_range(-2.4, 2.4), plate_fall_duration)
	tween.tween_property(plate, "modulate:a", 0.0, plate_fall_duration * 0.5).set_delay(plate_fall_duration * 0.5)
	tween.chain().tween_callback(plate.hide)


func _flash() -> void:
	if body == null:
		return
	if _flash_tween:
		_flash_tween.kill()
	body.modulate = flash_color
	_flash_tween = create_tween()
	_flash_tween.tween_property(body, "modulate", Color.WHITE, 0.3)


func _fall() -> void:
	_falling = true
	var drop: float = _play_area.end.y - global_position.y + 360.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(-140.0, drop), fall_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if visual:
		tween.tween_property(visual, "rotation", deg_to_rad(-24.0), fall_duration * 0.6)
	tween.tween_property(self, "modulate:a", 0.0, fall_duration * 0.35).set_delay(fall_duration * 0.65)
	var gap: float = fall_duration * 0.6 / float(maxi(fall_explosions, 1))
	for i in fall_explosions:
		tween.tween_callback(_spawn_hull_explosion).set_delay(gap * i)
	tween.chain().tween_callback(_on_fallen)


func _spawn_hull_explosion() -> void:
	var offset := Vector2(randf_range(-190.0, 170.0), randf_range(-70.0, 60.0))
	_spawn_explosion(visual.to_global(offset) if visual else global_position + offset, randf_range(1.2, 1.8))


func _on_fallen() -> void:
	ev_destroyed.emit()
	queue_free()


func _spawn_explosion(global_point: Vector2, size: float) -> void:
	if explosion_scene == null:
		return
	var parent: Node2D = visual if visual else self
	var fx: Node2D = explosion_scene.instantiate()
	if fx.has_method("init"):
		fx.init(parent.to_local(global_point))
	else:
		fx.position = parent.to_local(global_point)
	fx.scale *= size
	parent.add_child(fx)
