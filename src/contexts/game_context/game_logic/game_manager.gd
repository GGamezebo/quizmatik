class_name GameManager
extends Node2D

signal ev_selected_lane_changed
signal ev_question_changed

@export var player: Player
@export var area: GameArea
@export var gameConfig: GameConfig
@export var answerScene: PackedScene
@export var game_events: GameEvents
@export var root_events: RootEvents

var fsm:FSM
var time:float = 0.0
var selected_lane: int = 0:
		set(value):
			if selected_lane != value:
				selected_lane = value
				ev_selected_lane_changed.emit()
				
var question: QuizQuestion.Question:
	set(new_question):
		question = new_question
		ev_question_changed.emit(question)

@onready var health:int = gameConfig.health:
	set(new_value):
		if health != new_value:
			health = new_value
			game_events.ev_health_changed.emit(health)
			if health == 0:
				root_events.ev_exit_game.emit()

func _ready() -> void:
	fsm = FSM.new({
		"initial": {"state": CountDown.get_state()},
		"transitions": [
			{"src": CountDown.get_state(), "dst": Game.get_state(), "event": "ev_start_game"},
			{"src": Game.get_state(), "dst": EndGame.get_state(), "event": "ev_end_game"},
			{"src": EndGame.get_state(), "dst": CountDown.get_state(), "event": "ev_restart"},
			{"src": EndGame.get_state(), "dst": Exit.get_state(), "event": "ev_exit"},
		],
		"states": [
			CountDown.new(self), 
			Game.new(self),
			EndGame.new(self),
			Exit.new(self),
		],
	})

func _exit_tree() -> void:
	fsm.deinit()
	
func _process(delta: float) -> void:
	time += delta
	selected_lane = area.getLine(player.position)


class GameState extends FSMState:
	static func get_state() -> String:
		return '' 
		
	var owner: GameManager
	var event_listener = EventListener.new()
	
	func _init(owner: GameManager) -> void:
		super(get_state())
		
		self.owner = owner
		
	func deinit() -> void:
		event_listener.deinit()
		owner = null
		
	func enter(_prev_state: FSMState, _event_data: Dictionary):
		print("<><><> enter", get_state())

		
class CountDown extends GameState:
	static func get_state() -> String:
		return 'CountDown'
		
	func enter(_prev_state: FSMState, _event_data: Dictionary):
		await owner.get_tree().create_timer(1.0).timeout
		add_event('ev_start_game')

class Game extends GameState:
	static func get_state() -> String:
		return 'Game'
	
	var options: Array[Answer] = []
	
	func deinit() -> void:
		for option in options:
			option.queue_free()
		options.clear()
		super.deinit()
	
	func enter(_prev_state: FSMState, _event_data: Dictionary):
		super.enter(_prev_state, _event_data)
		event_listener.add(owner.game_events.ev_explosion, _on_event_manager_ev_explosion)
		event_listener.add(owner.player.ev_player_colladed, _on_player_colladed)
		makeNewRound()
	
	func leave(_event_data: Dictionary) -> void:
		event_listener.deinit()
	
	func _on_event_manager_ev_explosion(answer: Answer) -> void:
		if answer.value == owner.question.correct_answer:
			_kill_all_answers()
		else:
			var index:int = options.find(answer)
			if index != -1:
				owner.health -= 1
				options.remove_at(index)
			answer.take_damage()
			
	func makeNewRound() -> void:
		owner.question = QuizQuestion.generate_question(owner.gameConfig)
		await owner.get_tree().create_timer(1.0).timeout
		_makeAnswers()
			
	func _makeAnswers() -> void:
		var area: GameArea = owner.area
		var question: QuizQuestion.Question = owner.question
		var gameConfig: GameConfig = owner.gameConfig
		var lines = area.getLines()
		for index in range(len(question.options)):
			var option:int = question.options[index]
			var answer:Answer = owner.answerScene.instantiate()
			var line: Rect2 = lines[index]
			var x:float = area.gameplay_area.end.x + 120
			var y:float = line.position.y + line.size.y / 2.0
			answer.position.x = x
			answer.position.y = x
			answer.setup(x, y, option, gameConfig.answer_speed)
			answer.ev_killed.connect(_on_answer_killed)
			options.append(answer)
			owner.owner.add_child.call_deferred(answer)
			
	func _kill_all_answers():
		for option in options:
			option.take_damage()			
				
	func _on_player_colladed(_player:Player, answer: Answer) -> void:
		if answer.value == owner.question.correct_answer:
			_kill_all_answers()
		else:
			var index:int = options.find(answer)
			if index != -1:
				owner.health -= 1
				_kill_all_answers()

	func _on_answer_killed(answer:Answer):
		options.erase(answer)
		if len(options) == 0:
			makeNewRound()
		
class EndGame extends GameState:
	static func get_state() -> String:
		return 'EndGame'

		
class Exit extends GameState:
	static func get_state() -> String:
		return 'Exit'
