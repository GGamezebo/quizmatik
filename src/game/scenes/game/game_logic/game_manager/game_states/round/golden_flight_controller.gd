class_name GoldenFlightController
extends RefCounted

## «Золотой полёт» (`GameConfig.golden_flight`): every correct answer releases a fast coin balloon in another
## lane; catching it (shot or ram) = +1 gold. Time up → `start_choice()`: one standing golden balloon per lane
## with hidden gold (`golden_choice_gold`); coins already flying keep going (drawn above the choices);
## the first one hit is revealed, the rest show what they held → `ev_finished` once no coin is left.
## Hits never reach combat.

signal ev_collected(amount: int)
signal ev_choice_started
## The pick is revealed — the battle can end.
signal ev_finished

const SPAWN_OFFSET_X: float = 120.0
const CHOICE_SPAWN_OFFSET_X: float = 120.0
## Choice balloons stop this far left of the play area's right edge.
const CHOICE_STOP_INSET_X: float = 300.0
## Lets the last answers fade out first.
const CHOICE_DELAY_SEC: float = 1.1
const REVEAL_SEC: float = 2.4
## Coin balloons fly over the standing choice balloons of the same lane.
const COIN_Z_INDEX: int = 1

var _area: GameArea
var _coin_scene: PackedScene
var _choice_scene: PackedScene
var _spawn_parent: Node
var _tree: SceneTree
var _active: bool = false
var _speed_mult: float = 1.0
var _choice_gold: Array[int] = []
var _coins: Array[BonusBalloon] = []
var _choices: Array[GoldenChoiceBalloon] = []
var _picked: bool = false
var _paused: bool = false


func _init(game_config: GameConfig, area: GameArea, coin_scene: PackedScene, choice_scene: PackedScene, spawn_parent: Node, tree: SceneTree) -> void:
	_area = area
	_coin_scene = coin_scene
	_choice_scene = choice_scene
	_spawn_parent = spawn_parent
	_tree = tree
	_active = game_config.golden_flight and coin_scene != null
	_speed_mult = game_config.golden_coin_speed_mult
	_choice_gold = game_config.golden_choice_gold.duplicate()


func deinit() -> void:
	for balloon in _coins:
		if is_instance_valid(balloon):
			balloon.queue_free()
	for balloon in _choices:
		if is_instance_valid(balloon):
			balloon.queue_free()
	_coins.clear()
	_choices.clear()
	_active = false
	_area = null
	_spawn_parent = null
	_tree = null


func is_active() -> bool:
	return _active


func set_paused(paused: bool) -> void:
	_paused = paused
	for balloon in _coins:
		if is_instance_valid(balloon):
			balloon.frozen = paused


func update_acceleration(acceleration: float) -> void:
	for balloon in _coins:
		if is_instance_valid(balloon):
			balloon.set_acceleration(acceleration)


## Correct answer popped in `from_lane` → a coin balloon in another lane.
func on_correct(from_lane: int, answer_speed: float) -> void:
	if not _active or not _choices.is_empty():
		return
	var lines: Array[Rect2] = _area.getLines()
	if lines.is_empty():
		return
	var lanes: Array[int] = []
	for i in lines.size():
		if i != from_lane:
			lanes.append(i)
	if lanes.is_empty():
		lanes.append(from_lane)
	var lane: int = lanes.pick_random()
	var balloon: BonusBalloon = _coin_scene.instantiate()
	balloon.initialize(_area.gameplay_area.end.x + SPAWN_OFFSET_X, lines[lane].get_center().y, 0,
		answer_speed * _speed_mult, _area.gameplay_area, lines[lane].size.y)
	balloon.lane_index = lane
	balloon.frozen = _paused
	balloon.z_index = COIN_Z_INDEX
	balloon.ev_killed.connect(_on_coin_gone)
	_coins.append(balloon)
	_spawn_parent.add_child.call_deferred(balloon)


## Time is up: the choice balloons slide in and stand still until one is hit.
func start_choice() -> void:
	if not _active or not _choices.is_empty() or _choice_scene == null:
		return
	ev_choice_started.emit()
	await _tree.create_timer(CHOICE_DELAY_SEC, false).timeout
	if _area == null:
		return
	var lines: Array[Rect2] = _area.getLines()
	var gold: Array[int] = _choice_gold.duplicate()
	gold.shuffle()
	for lane in mini(lines.size(), gold.size()):
		var balloon: GoldenChoiceBalloon = _choice_scene.instantiate()
		var lane_y: float = lines[lane].get_center().y
		balloon.initialize(_area.gameplay_area.end.x + CHOICE_SPAWN_OFFSET_X, lane_y, 0,
			0.0, _area.gameplay_area, lines[lane].size.y)
		balloon.launch_from(Vector2(_area.gameplay_area.end.x + CHOICE_SPAWN_OFFSET_X, lane_y),
			_area.gameplay_area.end.x - CHOICE_STOP_INSET_X)
		balloon.lane_index = lane
		balloon.gold_amount = gold[lane]
		balloon.frozen = true
		_choices.append(balloon)
		_spawn_parent.add_child.call_deferred(balloon)


## True when `answer` belongs to the golden flight (collected or ignored) — skip combat.
func try_collect(answer: Answer) -> bool:
	if not _active:
		return false
	if answer is GoldenChoiceBalloon and answer in _choices:
		_pick(answer as GoldenChoiceBalloon)
		return true
	if answer is BonusBalloon and answer in _coins:
		var coin := answer as BonusBalloon
		if coin.is_hittable():
			coin.take_damage(true)
			ev_collected.emit(coin.gold_amount)
		return true
	return false


func _on_coin_gone(balloon: Answer) -> void:
	_coins.erase(balloon)


func _pick(picked: GoldenChoiceBalloon) -> void:
	if _picked or not picked.is_hittable():
		return
	_picked = true
	picked.reveal(true)
	ev_collected.emit(picked.gold_amount)
	for balloon in _choices:
		if balloon != picked and is_instance_valid(balloon):
			balloon.reveal(false)
	await _tree.create_timer(REVEAL_SEC, false).timeout
	# Coins still in the air finish their flight (caught or gone) before the battle ends.
	while _active and not _coins.is_empty():
		await _tree.process_frame
	if _active:
		ev_finished.emit()
