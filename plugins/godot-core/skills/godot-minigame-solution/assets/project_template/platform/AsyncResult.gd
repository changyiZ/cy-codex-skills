extends RefCounted
class_name PlatformAsyncResult

signal resolved(result: Dictionary)

var _is_resolved := false

func finish(result: Dictionary) -> void:
	if _is_resolved:
		return
	_is_resolved = true
	emit_signal("resolved", result.duplicate(true))
