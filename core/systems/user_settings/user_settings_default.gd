class_name UserSettingsDefault
extends Resource

const SAVE_PATH: String = "user://settings.cfg"
const VERSION: int = 0

class Meta:
	const SECTION: String = 'Meta'
	const VERSION: String = 'version'

class Audio:
	const SECTION: String = 'Audio'
	const IS_MUSIC_MUTED: String = 'is_music_muted'

var settings: Dictionary = {
	Meta.SECTION: {
		Meta.VERSION: VERSION,
	},
	Audio.SECTION: {
		Audio.IS_MUSIC_MUTED: false,
	},
}

	
var _config: ConfigFile = null

func provide(config: ConfigFile) -> void:
	_config = config
	
func set_setting(section: String, key: String, value) -> void:
	if _config:
		_config.set_value(section, key, value)
		_config.save(SAVE_PATH)

func get_setting(section: String, key: String) -> Variant:
	var default_value = settings[section][key]
	return _config.get_value(section, key, default_value) if _config != null else default_value

func save() -> void:
	if _config:
		_config.save(SAVE_PATH)
