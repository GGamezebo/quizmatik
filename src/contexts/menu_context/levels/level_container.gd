extends PanelButton


func initialize(pack_name: String, is_unlocked: bool) -> void:
	text = pack_name
	disabled = not is_unlocked
