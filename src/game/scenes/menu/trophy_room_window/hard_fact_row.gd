extends HBoxContainer

@export var rank_label: Label
@export var example_label: Label
@export var misses_label: Label
@export var misses_format: String = "ошибок: %d"


func initialize(rank: int, example_text: String, misses: int) -> void:
	rank_label.text = "%d." % rank
	example_label.text = example_text
	misses_label.text = tr(misses_format) % misses
