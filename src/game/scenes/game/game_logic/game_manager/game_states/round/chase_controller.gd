class_name ChaseController
extends RefCounted

## Chase level (`GameConfig.chase`): three airships chase the plane from the left — the royal chief in front at
## the plane's height, two regular ones further back above / below; every hull a different color, all flipped to
## face right. Answers slide in and stand still (`release_answers`). The plane pulls ahead to `START_SHARE` of the
## play area as they fly in; each correct answer moves it one step toward `FINISH_SHARE` (the middle: the last one
## gets it there → win fly-off) and knocks the chasers back so the gap grows by `ANSWER_GAP_PX` in all. They fly in
## `chase_head_start` gaps behind, then creep at `ANSWER_GAP_PX / (chase_answer_px / answer_speed)` px/s: one
## answer buys that many seconds. Chief nose reaches the plane tail → `ev_caught`. The world drains to gray behind
## them (`ev_drain`: follows at once, heals slowly); closer than `DANGER_GAPS` → `ev_danger(true)` (red hulls,
## tense music), back past `CALM_GAPS` → `false`. `finish(won)`: they fall back and the color returns, or the chief
## rams the plane and the world goes gray.

signal ev_started
signal ev_caught
signal ev_danger(close: bool)
## Screen x left of which the world is gray; `duration` > 0 = ease there (battle end).
signal ev_drain(edge_x: float, duration: float)

const ENTRY_SEC: float = 2.6
## Plane spot (share of the play-area width) during the first question / after the last answer.
const START_SHARE: float = 0.35
const FINISH_SHARE: float = 0.55
## Gap one correct answer wins (plane step + knock-back of the chasers), px.
const ANSWER_GAP_PX: float = 90.0
## They never fall further back than this many gaps (always in sight; a fast pilot banks at most that much).
const MAX_GAPS: float = 1.8
const CHIEF_SCALE: float = 0.55
const WING_SCALE: float = 0.42
## Wings hang this far behind the chief (px, center to center), at these shares of the play-area height.
const WING_BACK_X: float = 55.0
const WING_Y_SHARES: Array[float] = [0.12, 0.9]
## Wings lean this share of the way toward the chief's height.
const WING_FOLLOW: float = 0.3
## A wing closer than this to the chief's height tucks further back (× `WING_TUCK`) so it peeks out behind it.
const WING_TUCK_SEP: float = 110.0
const WING_TUCK: float = 1.5
## Wings are further away: a bit darker, drawn under the chief.
const WING_MODULATE := Color(0.84, 0.85, 0.9)
## Chief eases toward the plane's height (exponential rate per second).
const FOLLOW_RATE: float = 1.6
## Hull sits above the art center (gondola below): lines the hull up with the plane.
const CHIEF_Y_OFFSET: float = 20.0
## Plane eases to its new spot / chasers to their knock-back (exponential rate per second).
const PLANE_RATE: float = 4.0
const KNOCK_RATE: float = 3.5
## Plane tail = center − half its sprite width × this: the exhaust flame tip (behind the sprite cell).
const TAIL_SHARE: float = 1.25
const DANGER_GAPS: float = 0.9
const CALM_GAPS: float = 1.5
## Stays tense at least this long (no music flip-flop).
const DANGER_HOLD_SEC: float = 3.0
## Gray edge trails this far behind the chief nose (negative = ahead of it); colors come back at this rate when they fall back.
const DRAIN_BEHIND_NOSE: float = -50.0
const DRAIN_HEAL_RATE: float = 0.5
## Edge this far past the screen = fully colored / fully gray.
const DRAIN_OFF_PX: float = 500.0
const DRAIN_RESTORE_SEC: float = 1.8
const DRAIN_FILL_SEC: float = 1.1
## Answers stop this far left of the play area's right edge.
const STAND_INSET_X: float = 190.0
const ANSWER_SPAWN_OFFSET_X: float = 120.0
const RETREAT_PX: float = 900.0
const RETREAT_SEC: float = 2.6
const STRIKE_SEC: float = 0.5

var _config: GameConfig
var _area: GameArea
var _plane: AirPlane
var _player: Player
var _chief_scene: PackedScene
var _wing_scene: PackedScene
var _spawn_parent: Node
var _active: bool = false
var _paused: bool = false
var _finished: bool = false
var _caught: bool = false
var _chief: BossAirship = null
var _wings: Array[BossAirship] = []
var _plane_x: float = 0.0
var _score: int = 0
## Chief nose, screen x = fly-in / creep position − eased knock-back.
var _front_x: float = 0.0
var _creep_x: float = 0.0
var _knock_x: float = 0.0
var _knock_target: float = 0.0
var _drain_x: float = 0.0
var _chief_y: float = 0.0
var _entry_left: float = 0.0
var _entry_from: float = 0.0
var _entry_to: float = 0.0
var _close: bool = false
var _close_for: float = 0.0


func _init(
	game_config: GameConfig,
	area: GameArea,
	plane: AirPlane,
	player: Player,
	chief_scene: PackedScene,
	wing_scene: PackedScene,
	spawn_parent: Node
) -> void:
	_config = game_config
	_area = area
	_plane = plane
	_player = player
	_chief_scene = chief_scene if chief_scene != null else wing_scene
	_wing_scene = wing_scene if wing_scene != null else chief_scene
	_spawn_parent = spawn_parent
	_active = game_config.chase and _chief_scene != null


## Airships stay where they are (retreating / over the crashed plane); the scene frees them.
func deinit() -> void:
	_active = false
	_chief = null
	_wings.clear()
	_config = null
	_area = null
	_plane = null
	_player = null
	_chief_scene = null
	_wing_scene = null
	_spawn_parent = null


func set_paused(paused: bool) -> void:
	_paused = paused


## The chasers fly in from the left edge (call once the battle starts).
func start() -> void:
	if not _active or _chief != null:
		return
	_plane_x = _plane.position.x
	_score = _player.score
	_chief_y = _plane.global_position.y + CHIEF_Y_OFFSET
	_chief = _spawn(_chief_scene.instantiate(), CHIEF_SCALE, randi(), -1)
	# Wings: two different hulls out of the regular palette (the chief's royal one differs anyway).
	var hulls: Array = []
	for i in WING_Y_SHARES.size():
		var wing: BossAirship = _wing_scene.instantiate()
		if hulls.is_empty():
			hulls = range(maxi(wing.body_variants.size(), WING_Y_SHARES.size()))
			hulls.shuffle()
		wing.modulate = WING_MODULATE
		_wings.append(_spawn(wing, WING_SCALE, hulls[i], -2))
	_entry_to = _plane_target_x() - _tail_offset() - ANSWER_GAP_PX * _config.chase_head_start
	_entry_from = _area.gameplay_area.position.x - _chief.get_nose_reach() * 2.6 - WING_BACK_X
	_creep_x = _entry_from
	_front_x = _entry_from
	_drain_x = _front_x - DRAIN_BEHIND_NOSE
	_entry_left = ENTRY_SEC
	_place()
	ev_drain.emit(_drain_x, 0.0)
	ev_started.emit()


func update(delta: float) -> void:
	if not _active or _finished or _chief == null:
		return
	if _player.score > _score:
		# The plane's step covers part of the won gap; the chasers fall back for the rest.
		_knock_target += maxf(ANSWER_GAP_PX - _step(), 0.0) * float(_player.score - _score)
		_score = _player.score
	_plane_x = lerpf(_plane_x, _plane_target_x(), 1.0 - exp(-PLANE_RATE * delta))
	_plane.position.x = _plane_x
	_knock_x = lerpf(_knock_x, _knock_target, 1.0 - exp(-KNOCK_RATE * delta))
	if not _paused:
		if _entry_left > 0.0:
			_entry_left = maxf(_entry_left - delta, 0.0)
			var t: float = 1.0 - _entry_left / ENTRY_SEC
			_creep_x = lerpf(_entry_from, _entry_to, 1.0 - pow(1.0 - t, 3.0))
		else:
			_creep_x += _speed() * delta
	_front_x = _creep_x - _knock_x
	var lag: float = _tail_x() - ANSWER_GAP_PX * MAX_GAPS - _front_x
	if lag > 0.0 and _entry_left <= 0.0:
		_creep_x += lag
		_front_x += lag
	_chief_y = lerpf(_chief_y, _plane.global_position.y + CHIEF_Y_OFFSET, 1.0 - exp(-FOLLOW_RATE * delta))
	_place()
	var drain_target: float = _front_x - DRAIN_BEHIND_NOSE
	_drain_x = drain_target if drain_target > _drain_x else lerpf(_drain_x, drain_target, 1.0 - exp(-DRAIN_HEAL_RATE * delta))
	ev_drain.emit(_drain_x, 0.0)
	var gap: float = _tail_x() - _front_x
	_update_danger(gap, delta)
	if gap <= 0.0 and not _caught:
		_caught = true
		ev_caught.emit()


## Chase rounds: the balloons slide in and wait to be shot (never fly at the plane).
func release_answers(answers: Array[Answer]) -> void:
	if not _active:
		return
	var area: Rect2 = _area.gameplay_area
	for answer in answers:
		answer.speed = 0.0
		answer.launch_from(Vector2(area.end.x + ANSWER_SPAWN_OFFSET_X, answer.position.y), area.end.x - STAND_INSET_X)


## Battle over: won → the chasers fall back and the color returns; lost → the chief rams the plane, all gray.
func finish(won: bool) -> void:
	if not _active or _finished or _chief == null:
		return
	_finished = true
	if won:
		ev_drain.emit(-DRAIN_OFF_PX, DRAIN_RESTORE_SEC)
		for airship in _all():
			airship.set_menacing(false)
			var tween := airship.create_tween()
			tween.tween_property(airship, "position:x", airship.position.x - RETREAT_PX, RETREAT_SEC)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		return
	ev_drain.emit(_area.gameplay_area.end.x + DRAIN_OFF_PX, DRAIN_FILL_SEC)
	for airship in _all():
		airship.set_menacing(true)
	var strike_x: float = _plane.global_position.x - _chief.get_nose_reach() * 0.55
	var strike := _chief.create_tween().set_parallel(true)
	strike.tween_property(_chief, "position", Vector2(strike_x, _plane.global_position.y + CHIEF_Y_OFFSET), STRIKE_SEC)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for wing in _wings:
		strike.tween_property(wing, "position:x", wing.position.x + WING_BACK_X * 0.6, STRIKE_SEC * 1.6)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _spawn(airship: BossAirship, size: float, hull: int, z: int) -> BossAirship:
	airship.setup_chaser(hull)
	airship.scale = Vector2(-size, size)
	airship.z_index = z
	_spawn_parent.add_child.call_deferred(airship)
	return airship


func _place() -> void:
	_chief.position = Vector2(_front_x - _chief.get_nose_reach(), _chief_y)
	var area: Rect2 = _area.gameplay_area
	for i in _wings.size():
		var base_y: float = area.position.y + area.size.y * WING_Y_SHARES[i]
		var y: float = lerpf(base_y, _chief_y, WING_FOLLOW)
		var tuck: float = maxf(WING_TUCK_SEP - absf(y - _chief_y), 0.0) * WING_TUCK
		_wings[i].position = Vector2(_chief.position.x - WING_BACK_X - tuck, y)


func _update_danger(gap: float, delta: float) -> void:
	_close_for += delta
	var close: bool = _close
	if not _close and _entry_left <= 0.0 and gap < ANSWER_GAP_PX * DANGER_GAPS:
		close = true
	elif _close and gap > ANSWER_GAP_PX * CALM_GAPS and _close_for >= DANGER_HOLD_SEC:
		close = false
	if close == _close:
		return
	_close = close
	_close_for = 0.0
	for airship in _all():
		airship.set_menacing(close)
	ev_danger.emit(close)


func _all() -> Array[BossAirship]:
	var all: Array[BossAirship] = []
	for airship in [_chief] + _wings:
		if is_instance_valid(airship):
			all.append(airship)
	return all


## Plane spot for the current score: `START_SHARE` → `FINISH_SHARE` (the middle — shots fly right, balloons stay there).
func _plane_target_x() -> float:
	var area: Rect2 = _area.gameplay_area
	var progress: float = clampf(float(_player.score) / float(maxi(_config.questions_count, 1)), 0.0, 1.0)
	return area.position.x + area.size.x * lerpf(START_SHARE, FINISH_SHARE, progress)


func _step() -> float:
	return _area.gameplay_area.size.x * (FINISH_SHARE - START_SHARE) / float(maxi(_config.questions_count, 1))


## Creep speed: one won gap per «answer time» (`chase_answer_px` of balloon flight at `answer_speed`).
func _speed() -> float:
	var answer_sec: float = _config.chase_answer_px / maxf(_config.answer_speed, 1.0)
	return ANSWER_GAP_PX / maxf(answer_sec, 0.1)


func _tail_offset() -> float:
	return _plane.get_size().x * 0.5 * TAIL_SHARE


func _tail_x() -> float:
	return _plane.global_position.x - _tail_offset()
