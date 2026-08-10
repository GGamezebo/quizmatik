class_name YandexContext
extends HfsmBoundEntity

## Yandex Games SDK hooks (init, Game Ready, ads). Nested under WEB.

var music_player: AudioStreamPlayer = null


func _init(data: Dictionary = {}) -> void:
	print("YandexContext _init")
	music_player = data.get("music_player") as AudioStreamPlayer
