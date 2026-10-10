class_name HeartController
extends RefCounted

## Endless battle extra life: `spawn` sends one heart balloon down a random lane ahead of the answers
## (on `EndlessDirector.ev_heart_due`, only while hurt). Popping / ramming it → `ev_collected`;
## hits never reach `CombatResolver`. Missed → the next one comes on the next due.

signal ev_collected

const SPAWN_OFFSET_X: float = 120.0

var _area: GameArea
var _scene: PackedScene
var _spawn_parent: Node
var _speed_mult: float = 1.0
var _balloon: HeartBalloon = null
var _paused: bool = false


func _init(game_config: GameConfig, area: GameArea, scene: PackedScene, spawn_parent: Node) -> void:
	_area = area
	_scene = scene
	_spawn_parent = spawn_parent
	_speed_mult = game_config.bonus_gold_speed_mult


func deinit() -> void:
	if is_instance_valid(_balloon):
		_balloon.queue_free()
	_balloon = null
	_area = null
	_scene = null
	_spawn_parent = null


## False when there is nothing to spawn (no scene / lanes, or one still flying).
func spawn(answer_speed: float) -> bool:
	if _scene == null or is_instance_valid(_balloon):
		return false
	var lines: Array = _area.getLines()
	if lines.is_empty():
		return false
	var lane: int = randi() % lines.size()
	var line: Rect2 = lines[lane]
	var balloon: HeartBalloon = _scene.instantiate()
	var x: float = _area.gameplay_area.end.x + SPAWN_OFFSET_X
	var y: float = line.position.y + line.size.y / 2.0
	balloon.initialize(x, y, 0, answer_speed * _speed_mult, _area.gameplay_area, line.size.y)
	balloon.lane_index = lane
	balloon.frozen = _paused
	_balloon = balloon
	_spawn_parent.add_child.call_deferred(balloon)
	return true


## True when `answer` is the heart balloon (popped + collected, or already dying) — skip combat.
func try_collect(answer: Answer) -> bool:
	if not answer is HeartBalloon:
		return false
	var balloon := answer as HeartBalloon
	if balloon.is_hittable():
		balloon.take_damage(true)
		ev_collected.emit()
	return true


func set_paused(paused: bool) -> void:
	_paused = paused
	if is_instance_valid(_balloon):
		_balloon.frozen = paused


func update_acceleration(acceleration: float) -> void:
	if is_instance_valid(_balloon):
		_balloon.set_acceleration(acceleration)
