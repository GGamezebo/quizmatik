extends Control

const SAVE_PATH = "user://training_settings.json"
const BLACK_LIST = [
		"RefCounted", 
		"Resource", 
		"GDScript", 
		"Built-in Scripts"
	]

@export var config: GameConfig
@export var params_container: VBoxContainer


func _ready():
	if config:
		var result: Dictionary = ResourceUtils.load_json(SAVE_PATH)
		match int(result["status"]):
			ResourceUtils.JsonLoadStatus.OK:
				print("load config: ", SAVE_PATH)
				ResourceUtils.apply_dict(config, result["data"])
			ResourceUtils.JsonLoadStatus.CORRUPT:
				var bak: Dictionary = ResourceUtils.load_json(ResourceUtils.bak_path(SAVE_PATH))
				if int(bak["status"]) == ResourceUtils.JsonLoadStatus.OK:
					print("load config from bak: ", ResourceUtils.bak_path(SAVE_PATH))
					ResourceUtils.apply_dict(config, bak["data"])
					ResourceUtils.save_json(SAVE_PATH, ResourceUtils.resource_to_dict(config), false)
				else:
					push_error("Training settings corrupt, keeping scene defaults: %s" % SAVE_PATH)
		regenerate_ui()

func _save_config_to_disk():
	if config:
		ResourceUtils.save_json(SAVE_PATH, ResourceUtils.resource_to_dict(config))
	
func regenerate_ui():
	# Clear old parameter rows
	for child in params_container.get_children():
		child.queue_free()

	var properties = config.get_property_list()
	
	for prop in properties:
		if prop.usage & PROPERTY_USAGE_CATEGORY:
			if prop.name.ends_with(".gd") or prop.name in BLACK_LIST:
				continue
			_create_category_label(prop.name)
			continue
		
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			_create_editor_row(prop.name, prop.type)

func _create_category_label(cat_name: String):
	var label = Label.new()
	label.text = "\n— " + cat_name.to_upper() + " —"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.YELLOW)
	params_container.add_child(label)

func _create_editor_row(prop_name: String, type: int):
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var label = Label.new()
	label.text = prop_name.capitalize().replace("_", " ") + ":"
	label.custom_minimum_size.x = 250
	hbox.add_child(label)

	var current_value = config.get(prop_name)
	
	# Custom editor for the operations bitfield (not a plain TYPE_INT)
	if prop_name == "allowed_operations":
		var flags_container = VBoxContainer.new() # Checkbox list container
		
		# UI labels and matching bit masks from GameConfig.Operations
		var operations_data = [
			{"name": "Addition", "value": GameConfig.Operations.ADDITION},
			{"name": "Subtraction", "value": GameConfig.Operations.SUBTRACTION},
			{"name": "Multiplication", "value": GameConfig.Operations.MULTIPLICATION},
			{"name": "Division", "value": GameConfig.Operations.DIVISION}
		]
		
		for op in operations_data:
			var check_box = CheckBox.new()
			check_box.text = op["name"]
			
			# Check whether this bit is set in the current config value
			check_box.button_pressed = (current_value & op["value"]) != 0
			
			# Update the bit mask when toggled
			check_box.toggled.connect(func(is_checked):
				var flags = config.get(prop_name)
				if is_checked:
					flags |= op["value"]  # Set bit (bitwise OR)
				else:
					flags &= ~op["value"] # Clear bit (bitwise AND NOT)
				
				config.set(prop_name, flags)
				_save_config_to_disk()
			)
			flags_container.add_child(check_box)
		
		hbox.add_child(flags_container)
		params_container.add_child(hbox)
		return # Skip the generic type handler below

	if prop_name == "answer_speed_round_coeffs":
		_create_answer_speed_round_coeffs_editor(prop_name, current_value)
		return
		
	# Generic handler for other property types
	match type:
		TYPE_INT, TYPE_FLOAT:
			var spin_box = SpinBox.new()
			spin_box.step = 0.1 if type == TYPE_FLOAT else 1.0
			spin_box.allow_greater = true
			spin_box.allow_lesser = true
			spin_box.value = current_value

			spin_box.value_changed.connect(func(val): 
				config.set(prop_name, val)
				_save_config_to_disk()
			)
			hbox.add_child(spin_box)
			
		TYPE_BOOL:
			var check_box = CheckBox.new()
			check_box.button_pressed = current_value
			check_box.toggled.connect(func(val): 
				config.set(prop_name, val)
				_save_config_to_disk()
			)
			hbox.add_child(check_box)

	params_container.add_child(hbox)


func _create_answer_speed_round_coeffs_editor(prop_name: String, current_value: Dictionary) -> void:
	var section = VBoxContainer.new()

	var header = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	var label = Label.new()
	label.text = "Answer speed round coeffs:"
	label.custom_minimum_size.x = 250
	header.add_child(label)
	section.add_child(header)

	var entries_box = VBoxContainer.new()
	section.add_child(entries_box)

	var sorted_rounds: Array = current_value.keys()
	sorted_rounds.sort()
	for round_key in sorted_rounds:
		_add_answer_speed_round_coeff_row(
			entries_box,
			prop_name,
			int(round_key),
			float(current_value[round_key])
		)

	var add_button = Button.new()
	add_button.text = "+ Add round coeff"
	add_button.pressed.connect(func():
		var coeffs: Dictionary = config.get(prop_name)
		var next_round: int = 1
		while coeffs.has(next_round):
			next_round += 1
		_add_answer_speed_round_coeff_row(entries_box, prop_name, next_round, 1.0)
		_sync_answer_speed_round_coeffs(entries_box, prop_name)
	)
	section.add_child(add_button)
	params_container.add_child(section)


func _add_answer_speed_round_coeff_row(
	entries_box: VBoxContainer,
	prop_name: String,
	round_num: int,
	coeff: float
) -> void:
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	var round_label = Label.new()
	round_label.text = "After round:"
	round_label.custom_minimum_size.x = 90
	row.add_child(round_label)

	var round_spin = SpinBox.new()
	round_spin.name = "RoundSpin"
	round_spin.min_value = 1
	round_spin.step = 1
	round_spin.allow_lesser = false
	round_spin.value = round_num
	row.add_child(round_spin)

	var coeff_label = Label.new()
	coeff_label.text = "Coeff:"
	coeff_label.custom_minimum_size.x = 50
	row.add_child(coeff_label)

	var coeff_spin = SpinBox.new()
	coeff_spin.name = "CoeffSpin"
	coeff_spin.min_value = 0.1
	coeff_spin.max_value = 5.0
	coeff_spin.step = 0.1
	coeff_spin.allow_greater = true
	coeff_spin.value = coeff
	row.add_child(coeff_spin)

	var remove_button = Button.new()
	remove_button.text = "X"
	remove_button.pressed.connect(func():
		row.queue_free()
		_sync_answer_speed_round_coeffs.call_deferred(entries_box, prop_name)
	)
	row.add_child(remove_button)

	round_spin.value_changed.connect(func(_value): _sync_answer_speed_round_coeffs(entries_box, prop_name))
	coeff_spin.value_changed.connect(func(_value): _sync_answer_speed_round_coeffs(entries_box, prop_name))

	entries_box.add_child(row)


func _sync_answer_speed_round_coeffs(entries_box: VBoxContainer, prop_name: String) -> void:
	var new_dict: Dictionary = {}
	for row in entries_box.get_children():
		if not row is HBoxContainer:
			continue
		var round_spin: SpinBox = row.get_node("RoundSpin")
		var coeff_spin: SpinBox = row.get_node("CoeffSpin")
		var round_num: int = int(round_spin.value)
		if round_num > 0:
			new_dict[round_num] = coeff_spin.value
	config.set(prop_name, new_dict)
	_save_config_to_disk()


func _on_reset_setting_pressed() -> void:
	ResourceUtils.update_resource(config, GameConfig.new())
	_save_config_to_disk()
	regenerate_ui()
