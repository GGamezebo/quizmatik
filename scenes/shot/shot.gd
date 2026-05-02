extends Area2D

@export var speed: float = 600.0
@export var eventManager: EventManager
@onready var visibleNotifier = $VisibleOnScreenNotifier2D

func _ready() -> void:
	visibleNotifier.screen_exited.connect(self.on_visible_on_screen_notifier_2d_screen_exited)

func _physics_process(delta: float) -> void:
	position.x += speed * delta

func on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(answer: Answer) -> void:
	if answer.is_in_group("answers"): 
		_ev_explosion(answer)
		queue_free()
		
func _ev_explosion(answer: Answer) -> void:
	if eventManager:
		eventManager.ev_explosion.emit(answer)
		
