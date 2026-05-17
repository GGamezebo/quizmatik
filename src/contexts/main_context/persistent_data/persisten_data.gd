extends Node

@export var _user_settings: UserSettings
@export var _progress: PDataProgress

func _ready() -> void:
	load_resource(_user_settings)
	load_resource(_progress)
	print("Data system initialized successfully.")

func load_resource(resource: Resource) -> void:
	if ResourceLoader.exists(resource.SAVE_PATH):
		var saved_res = ResourceLoader.load(resource.SAVE_PATH)
		if saved_res:
			ResourceUtils.update_resource(resource, saved_res)
			print("Resource is loaded ", resource.SAVE_PATH)
	else:
		print("Resource is not found ", resource.SAVE_PATH)
