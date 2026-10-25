class_name ValleyEndlessEntry
extends EndlessEntry

## Level grid clock (left of the 20 levels): the valley record battle. Shown once the valley exam is passed
## (`ProgressController.is_valley_record_unlocked`); same rules as the menu clock, but examples of the
## valley's one operation only (`ValleyRecordScenario`) and its own record. The grid calls `set_valley`.

var _valley_id: String = ""


func set_valley(container_id: String) -> void:
	_valley_id = container_id
	_refresh()


func _is_unlocked() -> bool:
	return not _valley_id.is_empty() and progress.is_valley_record_unlocked(_valley_id)


func _best_sec() -> int:
	return progress.pdata.statistics.endless_best(_valley_id)


func _battle_config() -> GameConfig:
	var operation: int = progress.levels_config.get_record_operation(_valley_id)
	return ValleyRecordScenario.build(super(), _valley_id, operation)
