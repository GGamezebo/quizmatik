extends HBoxContainer

@export var player: Player
@export var heart_scene: PackedScene


var _animate_new: bool = false


func _ready() -> void:
	player.ev_health_changed.connect(_on_health_changed)
	_update_state()
	_animate_new = true


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
	var heart: Control = heart_scene.instantiate()
	add_child(heart)
	if _animate_new:
		_pop_in.call_deferred(heart)


## Restored heart (streak heal) pops in.
func _pop_in(heart: Control) -> void:
	if not is_instance_valid(heart):
		return
	heart.pivot_offset = heart.size / 2.0
	heart.scale = Vector2.ZERO
	var tween := heart.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(heart, "scale", Vector2.ONE, 0.35)


func _remove_health() -> void:
	var child_count := get_child_count()
	if child_count > 0:
		get_child(child_count - 1).queue_free()
