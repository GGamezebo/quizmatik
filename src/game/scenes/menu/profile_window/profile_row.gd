extends Button

var profile_id: String = ""


func setup(id: String, display_name: String, age: int, is_active: bool) -> void:
	profile_id = id
	var label := display_name
	if label.is_empty():
		label = "Пилот"
	text = "%s · %d" % [label, age]
	disabled = is_active
	modulate = Color(1, 1, 1, 1) if is_active else Color(1, 1, 1, 0.92)
