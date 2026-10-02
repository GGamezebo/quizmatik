class_name BonusController
extends RefCounted

## At most one golden bonus balloon per battle: rolled once from `GameConfig.bonus_gold_chance`,
## spawned at the start of a random round ahead of the answers. Hits never reach `CombatResolver`.

signal ev_collected(amount: int)

const SPAWN_OFFSET_X: float = 120.0

var _area: GameArea
var _scene: PackedScene
var _spawn_parent: Node
var _speed_mult: float = 1.0
## Round (player score) that gets the balloon; -1 = no bonus this battle.
var _target_score: int = -1
var _balloon: BonusBalloon = null
var _paused: bool = false


func _init(game_config: GameConfig, area: GameArea, scene: PackedScene, spawn_parent: Node) -> void:
	_area = area
	_scene = scene
	_spawn_parent = spawn_parent
	_speed_mult = game_config.bonus_gold_speed_mult
	if scene != null and randf() < game_config.bonus_gold_chance:
		_target_score = randi_range(1, maxi(1, game_config.questions_count - 2))


func deinit() -> void:
	if is_instance_valid(_balloon):
		_balloon.queue_free()
	_balloon = null
	_area = null
	_scene = null
	_spawn_parent = null


func on_round_started(score: int, answer_speed: float) -> void:
	if _target_score < 0 or score != _target_score:
		return
	_target_score = -1
	_spawn(answer_speed * _speed_mult)


## True when `answer` is the bonus balloon (popped + collected, or already dying) — skip combat.
func try_collect(answer: Answer) -> bool:
	if not answer is BonusBalloon:
		return false
	var balloon := answer as BonusBalloon
	if balloon.is_hittable():
		balloon.take_damage(true)
		ev_collected.emit(balloon.gold_amount)
	return true


func set_paused(paused: bool) -> void:
	_paused = paused
	if is_instance_valid(_balloon):
		_balloon.frozen = paused


func update_acceleration(acceleration: float) -> void:
	if is_instance_valid(_balloon):
		_balloon.set_acceleration(acceleration)


func _spawn(speed: float) -> void:
	var lines: Array = _area.getLines()
	if lines.is_empty():
		return
	var lane: int = randi() % lines.size()
	var line: Rect2 = lines[lane]
	var balloon: BonusBalloon = _scene.instantiate()
	var x: float = _area.gameplay_area.end.x + SPAWN_OFFSET_X
	var y: float = line.position.y + line.size.y / 2.0
	balloon.initialize(x, y, 0, speed, _area.gameplay_area, line.size.y)
	balloon.lane_index = lane
	balloon.frozen = _paused
	_balloon = balloon
	_spawn_parent.add_child.call_deferred(balloon)
