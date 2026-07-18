extends HBoxContainer

@export var player: Player
@export var game_config: GameConfig
@export var score: Label
@export var maxScore: Label

func _ready() -> void:
	maxScore.text = str(game_config.questions_count)
	score.text = str(player.score)
	player.ev_score_changed.connect(_on_score_changed)
	
func _on_score_changed(new_score: int) -> void:
	score.text = str(new_score)
	
