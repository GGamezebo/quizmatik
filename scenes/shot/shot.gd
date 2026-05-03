extends Area2D

signal ev_explosion(answer:Answer)

@export var speed: float = 600.0
@onready var visibleNotifier = $VisibleOnScreenNotifier2D


func _ready() -> void:
	visibleNotifier.screen_exited.connect(self._on_visible_on_screen_notifier_2d_screen_exited)

func init(_position:Vector2) -> void:
	self.position = _position
	
func _physics_process(delta: float) -> void:
	position.x += speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(answer: Answer) -> void:
	if answer.is_in_group("answers"): 
		ev_explosion.emit(answer)
		queue_free()
