class_name BossController
extends RefCounted

## Boss airship (`features/boss`) after the last regular answer: rolled once from `GameConfig.boss_chance`
## (exam = 1, never on timed levels). Flies in (`ev_appeared`) → rounds resume (`ev_ready`); every correct
## answer then knocks off one armor plate (`ev_hit`); armor 0 → it gets angry (`ev_enraged`) and creeps
## toward the plane; shots on its hull (`shoot`, `ev_shot`) bring it down (`ev_defeated` → battle won).
## Staged battles (endless, magister): never rolled — `arm()` + `start()` on `EndlessDirector.ev_boss_due`, again
## after each fall; no angry phase (endless, or `boss_rage_hits` 0: waiting it out would farm time) — the last
## plate brings it down.

signal ev_appeared(armor: int)
signal ev_ready
signal ev_hit(armor_left: int)
signal ev_enraged(hits: int)
signal ev_shot(hits_left: int)
signal ev_defeated

enum Phase { NONE, WAITING, ENTERING, FIGHTING, RAGING, FALLING }

var _area: GameArea
var _scene: PackedScene
var _spawn_parent: Node
var _armor: int = 0
var _rage_hits: int = 0
var _phase: Phase = Phase.NONE
var _boss: BossAirship = null


func _init(game_config: GameConfig, area: GameArea, scene: PackedScene, spawn_parent: Node) -> void:
	_area = area
	_scene = scene
	_spawn_parent = spawn_parent
	_armor = game_config.boss_armor
	_rage_hits = 0 if game_config.endless else maxi(game_config.boss_rage_hits, 0)
	if scene != null and _armor > 0 and not game_config.is_timed() and not game_config.endless 			and randf() < game_config.boss_chance:
		_phase = Phase.WAITING


## Boss node stays (hovering over a lost battle); the scene frees it.
func deinit() -> void:
	if is_instance_valid(_boss):
		_boss.ev_entered.disconnect(_on_entered)
		_boss.ev_hit_landed.disconnect(_on_hit_landed)
		_boss.ev_enraged.disconnect(ev_enraged.emit)
		_boss.ev_destroyed.disconnect(_on_destroyed)
	_boss = null
	_phase = Phase.NONE
	_area = null
	_scene = null
	_spawn_parent = null


## Regular answers done, but the boss is still to come.
func is_waiting() -> bool:
	return _phase == Phase.WAITING


## Endless: queue the next boss (only between bosses).
func arm() -> bool:
	if _scene == null or _armor <= 0 or _phase != Phase.NONE:
		return false
	_phase = Phase.WAITING
	return true


## Boss in place: correct answers go to `hit` instead of the score.
func is_fighting() -> bool:
	return _phase == Phase.FIGHTING


func start() -> void:
	if _phase != Phase.WAITING:
		return
	_phase = Phase.ENTERING
	_boss = _scene.instantiate()
	_boss.initialize(_armor, _area.gameplay_area, _rage_hits)
	_boss.ev_entered.connect(_on_entered)
	_boss.ev_hit_landed.connect(_on_hit_landed)
	_boss.ev_enraged.connect(ev_enraged.emit)
	_boss.ev_destroyed.connect(_on_destroyed)
	_spawn_parent.add_child.call_deferred(_boss)
	ev_appeared.emit(_armor)


## Correct answer during the fight (`from_global` = popped balloon). True = last plate: no more
## questions, the angry shoot-out follows.
func hit(from_global: Vector2) -> bool:
	if _phase != Phase.FIGHTING:
		return false
	if _boss.hit(from_global) > 0:
		return false
	_phase = Phase.FALLING if _rage_hits <= 0 else Phase.RAGING
	return true


## A shot hit some `shot_targets` area; counts only on the angry boss hull.
func shoot(target: Area2D, hit_point: Vector2) -> void:
	if _phase != Phase.RAGING or not is_instance_valid(_boss) or not _boss.is_hitbox(target):
		return
	var left: int = _boss.take_shot(hit_point)
	if left < 0:
		return
	ev_shot.emit(left)
	if left == 0:
		_phase = Phase.FALLING


## Fight rounds: the new balloons fly out of the gondola on strings instead of sliding in from the right.
func release_answers(answers: Array[Answer]) -> void:
	if _phase != Phase.FIGHTING or not is_instance_valid(_boss):
		return
	var origin: Vector2 = _boss.get_launch_point()
	var target_x: float = _boss.get_launch_x()
	for answer in answers:
		answer.launch_from(origin, target_x)
		_boss.tether(answer)


func _on_entered() -> void:
	_phase = Phase.FIGHTING
	ev_ready.emit()


func _on_hit_landed(armor_left: int) -> void:
	ev_hit.emit(armor_left)


func _on_destroyed() -> void:
	_boss = null
	_phase = Phase.NONE
	ev_defeated.emit()
