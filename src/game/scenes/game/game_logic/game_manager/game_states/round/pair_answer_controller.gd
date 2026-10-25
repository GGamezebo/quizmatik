class_name PairAnswerController
extends RefCounted

## Expert «? + ? = 9» rounds (`GameConfig.hidden_pair`): the first shot balloon fills the left blank, the second the
## right one — only then the verdict (`Question.is_pair_solution`: any pair that solves it). Picks start over with
## every question; once decided, later hits of that round are ignored.

enum Hit { IGNORED, PICKED, SOLVED, WRONG }

var _active: bool = false
var _question: QuizQuestion.Question = null
var _picks: int = 0
var _first: int = 0


func _init(game_config: GameConfig) -> void:
	_active = game_config.hidden_pair


func deinit() -> void:
	_active = false
	_question = null


func is_active() -> bool:
	return _active


## A balloon of the current round was shot (`value` on it).
func pick(question: QuizQuestion.Question, value: int) -> Hit:
	if not _active or question == null or question.pair.is_empty():
		return Hit.IGNORED
	if question != _question:
		_question = question
		_picks = 0
	_picks += 1
	match _picks:
		1:
			_first = value
			return Hit.PICKED
		2:
			return Hit.SOLVED if question.is_pair_solution(_first, value) else Hit.WRONG
	return Hit.IGNORED


## Round decided without a second pick (ram, balloon flew away): later hits of it are ignored.
func cancel(question: QuizQuestion.Question) -> void:
	_question = question
	_picks = 2
