extends Node

const Meta = user_settings.Meta
@export var user_settings: UserSettings

var config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	user_settings.provide(config)
	_init_config()
	
func _exit_tree() -> void:
	config.provide(null)

func _init_config() -> void:
	var error = config.load(user_settings.SAVE_PATH)
	
	if error != OK:
		_create_default_config()
		return
	
	var saved_version: int = config.get_value(Meta.SECTION, Meta.VERSION, 0)
	
	if saved_version < user_settings.VERSION:
		_apply_migrations(config, saved_version)


## Создание конфига на основе данных из .tres файла
func _create_default_config() -> void:
	var default_user_settings: Dictionary = user_settings.settings
	
	for section_name in default_user_settings:
		var section_data: Dictionary = default_user_settings[section_name]
		
		for setting_key in section_data:
			var value = section_data[setting_key]
			config.set_value(section_name, setting_key, value)
	
	var error = config.save(user_settings.SAVE_PATH)
	if error == OK:
		print("Default config successfully created from .tres template.")

func _apply_migrations(_config: ConfigFile, _from_version: int) -> void:
	print("migration")
