class_name MistakesController
extends Node

## Per-profile weak examples (`PData.mistakes`): a wrong shot raises the fact's weight, a clean
## correct answer lowers it (0 → forgotten). AppRoot puts `review_facts()` into the battle payload.

const MISS_WEIGHT: int = 2
const MAX_WEIGHT: int = 6
const MAX_FACTS: int = 50
const REVIEW_LIMIT: int = 10

@export var pdata: PData
@export var game_events: GameEvents

var _listener: EventListener = EventListener.new()


static func find_in_tree(tree: SceneTree) -> MistakesController:
	if tree == null:
		return null
	return tree.root.find_child("MistakesController", true, false) as MistakesController


func _ready() -> void:
	_listener.add(game_events.ev_fact_answered, _on_fact_answered)


func _exit_tree() -> void:
	_listener.deinit()


## `MathFact` key → weight for the next battle (heaviest `REVIEW_LIMIT`).
func review_facts() -> Dictionary:
	var weights: Dictionary[String, int] = pdata.mistakes.weights
	var result: Dictionary = {}
	for fact_key in pdata.mistakes.top_keys(REVIEW_LIMIT):
		result[fact_key] = weights[fact_key]
	return result


# Saved by the battle-end force-flush (writes are suppressed during battle anyway).
func _on_fact_answered(fact_key: String, is_correct: bool) -> void:
	var mistakes: PData.MistakesData = pdata.mistakes
	if is_correct:
		if not mistakes.weights.has(fact_key):
			return
		var weight: int = mistakes.weights[fact_key] - 1
		if weight <= 0:
			mistakes.erase(fact_key)
		else:
			mistakes.weights[fact_key] = weight
		return
	add_miss(fact_key)


## One wrong answer on `fact_key` (battle; the dev lab seeds the hard facts board with it).
func add_miss(fact_key: String) -> void:
	var mistakes: PData.MistakesData = pdata.mistakes
	mistakes.weights[fact_key] = mini(mistakes.weights.get(fact_key, 0) + MISS_WEIGHT, MAX_WEIGHT)
	mistakes.misses[fact_key] = mistakes.misses.get(fact_key, 0) + 1
	_trim(mistakes, fact_key)


## Keep at most `MAX_FACTS`: drop the lowest by `top_keys` order, never the fact just missed.
func _trim(mistakes: PData.MistakesData, keep_key: String) -> void:
	if mistakes.weights.size() <= MAX_FACTS:
		return
	var ordered: Array[String] = mistakes.top_keys(mistakes.weights.size())
	ordered.erase(keep_key)
	while mistakes.weights.size() > MAX_FACTS and not ordered.is_empty():
		mistakes.erase(ordered.pop_back())
