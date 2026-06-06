extends HBoxContainer

@export var player: Player
@export var helthSprite: Texture2D


func _ready() -> void:
	player.ev_health_changed.connect(_on_health_changed)
	_updateState()
	
func _exit_tree() -> void:
	player.ev_health_changed.disconnect(_on_health_changed)

func _updateState() -> void:
	var health: int = player.health
	var child_count: int = get_child_count()
	var count: int = health - child_count
	var action = _createHealth if count > 0 else _removeHealth
	for _index in range(abs(count)):
		action.call()
	
func _on_health_changed(_health):
	_updateState()
	
func _createHealth():
	var new_texture_rect = TextureRect.new()
	new_texture_rect.texture = helthSprite
	new_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	new_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	new_texture_rect.custom_minimum_size = Vector2(64, 64)
	add_child(new_texture_rect)
	
	
func _removeHealth():
	var child_count = get_child_count()
	if child_count > 0:
		var last_child = get_child(child_count - 1)
		last_child.queue_free()
