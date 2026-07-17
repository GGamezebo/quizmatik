extends HfsmBoundEntity

## Root HFSM context. Holds the MainScene host for mounting scenes.

static func NAME() -> String:
	return "AppRoot"

## Set by MainScene before HFSM.new(...)
static var host: Node = null


static func require_host() -> Node:
	assert(host != null, "AppRootEntity.host must be set before HFSM starts")
	return host


func deinit() -> void:
	pass
