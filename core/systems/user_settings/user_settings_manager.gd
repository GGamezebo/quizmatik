extends Node

const Meta = UserSettingsDefault.Meta

@export var _user_settings: UserSettingsDefault

var _config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	_user_settings.provide(_config)
	_init_config()

func _init_config() -> void:
	var error = _config.load(_user_settings.SAVE_PATH)
	
	if error != OK:
		_create_default_config()
		return
	
	var saved_version: int = _config.get_value(Meta.SECTION, Meta.VERSION, 0)
	if saved_version < _user_settings.VERSION:
		_apply_migrations(saved_version)

## create default config on the base of .tres files
func _create_default_config() -> void:
	var default_user_settings: Dictionary = _user_settings.settings
	
	for section_name in default_user_settings:
		var section_data: Dictionary = default_user_settings[section_name]
		
		for setting_key in section_data:
			var value = section_data[setting_key]
			_config.set_value(section_name, setting_key, value)
	
	var error = _config.save(_user_settings.SAVE_PATH)
	if error == OK:
		print("Default config successfully created from .tres template.")

func _apply_migrations(_from_version: int) -> void:
	print("migration")
