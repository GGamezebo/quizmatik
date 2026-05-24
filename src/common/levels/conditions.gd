class_name LevelsContainerConditions


static func is_unlocked_by_default(_progress: PDataProgress, _args: Array) -> bool:
	return true
	
static func is_unlocked_by_exam(_progress: PDataProgress, _args: Array) -> bool:
	var container_id: String = _args[0]
	return _progress.progress['levels'].get(container_id, {}).get('exam_passed', false)
