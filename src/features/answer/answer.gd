extends Area2D

class_name Answer

signal ev_killed(answer:Answer)

@export var label: Label
@export var animation_time: float = 1.0
@export var dead_animation_scale: float = 1.5
@export_color_no_alpha var right_color: Color = Color.GREEN
@export_color_no_alpha var wrong_color: Color = Color.RED

var value: int = 0:
	set(new_value):
		value = new_value
		label.text = str(value)
		
var speed = 50
var _acceleration = GameConfig.PLAYER_ACCELERATION_DEFAULT


func _process(delta):
	position.x -= speed * _acceleration * delta
	
	if position.x < -100:
		queue_free()
		
	$Sprite2D.rotation += delta


func setup(x:float, y:float, new_value:int, _speed:float) -> void:
	self.position = Vector2(x, y)
	self.value = new_value
	self.speed = _speed
	
func set_acceleration(acceleration: float) -> void:
	_acceleration = acceleration

func _disable_collision():
	collision_layer = 0
	collision_mask = 0

func take_damage():
	self._disable_collision()
	
	var tween = create_tween().set_parallel(true)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, animation_time)
	# Slight scale up
	tween.tween_property(self, "scale", scale * dead_animation_scale, animation_time)
	# Drift upward
	tween.tween_property(self, "position:y", position.y, animation_time)
   	
   	# Free after the animation finishes
	tween.chain().tween_callback(queue_free)

func _exit_tree() -> void:
	ev_killed.emit(self)
	
func right() -> void:
	label.label_settings.font_color = right_color
	
func fail() -> void:
	label.label_settings.font_color = wrong_color
