extends HBoxContainer

@export var player: Player
@export var heart_scene: PackedScene


func _ready() -> void:
	player.ev_health_changed.connect(_on_health_changed)
	_update_state()


func _exit_tree() -> void:
	player.ev_health_changed.disconnect(_on_health_changed)


func _update_state() -> void:
	var health: int = player.health
	var child_count: int = get_child_count()
	var count: int = health - child_count
	var action := _create_health if count > 0 else _remove_health
	for _index in range(abs(count)):
		action.call()


func _on_health_changed(_health: int) -> void:
	_update_state()


func _create_health() -> void:
	if heart_scene == null:
		return
	add_child(heart_scene.instantiate())


func _remove_health() -> void:
	var child_count := get_child_count()
	if child_count > 0:
		get_child(child_count - 1).queue_free()
