extends MarginContainer

@export var button: Button

func initialize(text: String, is_unlocked: bool) -> void:
	button.text = text
	button.disabled = not is_unlocked
