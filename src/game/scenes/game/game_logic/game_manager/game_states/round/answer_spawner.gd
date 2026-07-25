class_name AnswerSpawner
extends RefCounted

var _area: GameArea
var _answer_scene: PackedScene
var _spawn_parent: Node

func _init(area: GameArea, answer_scene: PackedScene, spawn_parent: Node) -> void:
	_area = area
	_answer_scene = answer_scene
	_spawn_parent = spawn_parent

func deinit() -> void:
	_area = null
	_answer_scene = null
	_spawn_parent = null

func spawn(question: QuizQuestion.Question, speed: float) -> Array[Answer]:
	var spawned: Array[Answer] = []
	var lines: Array = _area.getLines()

	for index in range(question.options.size()):
		var option_value: int = question.options[index]
		var answer: Answer = _answer_scene.instantiate()
		var line: Rect2 = lines[index]
		var x: float = _area.gameplay_area.end.x + 120.0
		var y: float = line.position.y + line.size.y / 2.0
		answer.initialize(x, y, option_value, speed, _area.gameplay_area, line.size.y)
		spawned.append(answer)
		_spawn_parent.add_child.call_deferred(answer)

	return spawned
