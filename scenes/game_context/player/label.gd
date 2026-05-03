extends Label


func setup(_parent:Node) -> void:
	pass

func update(_delta:float) -> void:
	self.text = str(int(global_position.x))+"\n"+str(Vector2(int(global_position.x), int(global_position.y)))
