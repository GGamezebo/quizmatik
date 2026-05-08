extends Node

# User file paths
const PATH_PROGRESS = "user://progress.tres"
const PATH_SETTINGS = "user://settings.tres"

# References to default resources (assign them in the Autoload inspector)
@export var default_progress: PDataProgress # Your ProgressResource script
@export var default_settings: PDataSettings # Your SettingsResource script

# Current data objects used throughout the game
var progress: PDataProgress
var settings: PDataSettings

func _ready() -> void:
	# Start initialization when the application launches
	_initialize_configs()

func _initialize_configs() -> void:
	# 1. Handle PROGRESS data
	progress = _load_or_create(PATH_PROGRESS, default_progress)
	
	# 2. Handle SETTINGS data
	settings = _load_or_create(PATH_SETTINGS, default_settings)
	
	print("Data system initialized successfully.")

## Universal function to load an existing file or create a new one
func _load_or_create(path: String, default: Resource) -> Resource:
	if FileAccess.file_exists(path):
		var loaded_res = load(path)
		if loaded_res:
			print("Existing file loaded: ", path)
			return loaded_res
	
	# If file is missing or corrupted:
	print("File not found, creating new one at: ", path)
	var new_res: Resource
	
	if default:
		# Create a copy of the default resource to avoid modifying the master file
		new_res = default.duplicate()
	else:
		# If default resource is not assigned in the inspector, create a blank object
		new_res = Resource.new() 
		push_warning("Default resource for " + path + " is not assigned!")

	# Save to disk immediately so the file physically appears in user://
	var err = ResourceSaver.save(new_res, path)
	if err != OK:
		print("Error creating file: ", err)
		
	return new_res

## Manual save functions (call these after making changes)
func save_progress() -> void:
	ResourceSaver.save(progress, PATH_PROGRESS)

func save_settings() -> void:
	ResourceSaver.save(settings, PATH_SETTINGS)

func save_all() -> void:
	save_progress()
	save_settings()
