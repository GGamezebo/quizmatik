extends AnimatedSprite2D
class_name Explosion

func init(_position:Vector2) -> void:
	self.position = _position
	self.animation_finished.connect(self.queue_free)
