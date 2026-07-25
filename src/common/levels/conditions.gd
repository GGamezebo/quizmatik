class_name LevelsContainerConditions


static func is_unlocked_by_default(_progress: PData, _args: Array) -> bool:
	return true

static func is_unlocked_by_exam(_progress: PData, _args: Array) -> bool:
	var container_id: String = _args[0]
	if not _progress.levels.containers.has(container_id):
		return false
	return _progress.levels.containers[container_id].exam_passed
