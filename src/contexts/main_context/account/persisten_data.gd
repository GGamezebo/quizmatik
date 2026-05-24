extends Node

@export var _user_settings: UserSettings
@export var _progress: PDataProgress
@export var main_event: MainEvents

func _ready() -> void:
	_load_resource(_user_settings)
	_load_resource(_progress)
	main_event.ev_reset_account_progress.connect(_on_reset_account_progress)
	print("Data system initialized successfully.")

func _load_resource(resource: Resource) -> void:
	if ResourceLoader.exists(resource.SAVE_PATH):
		var saved_res = ResourceLoader.load(resource.SAVE_PATH)
		if saved_res:
			ResourceUtils.update_resource(resource, saved_res)
			print("Resource is loaded ", resource.SAVE_PATH)
		else:
			ResourceUtils.hard_reset_resource(resource.SAVE_PATH, resource, resource.get_script().new())
	else:
		print("Resource is not found ", resource.SAVE_PATH)

func _on_reset_account_progress() -> void:
	ResourceUtils.hard_reset_resource(_progress.SAVE_PATH, _progress, _progress.get_script().new())
