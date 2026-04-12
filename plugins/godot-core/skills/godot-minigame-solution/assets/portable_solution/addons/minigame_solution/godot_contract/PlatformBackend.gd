extends Node
class_name MinigamePlatformBackendContract

signal app_show(context: Dictionary)
signal app_hide

const DEFAULT_INSETS := {
	"left": 0.0,
	"top": 0.0,
	"right": 0.0,
	"bottom": 0.0
}

var _launch_context: Dictionary = {}
var _ui_insets: Dictionary = DEFAULT_INSETS.duplicate(true)
var _save_warning_message := ""
var _input_reference_size := Vector2.ZERO

func initialize() -> void:
	pass

func load_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_refresh_default_save_warning()
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_save_warning_message = "Failed to open local save storage."
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_save_warning_message = "Save data is corrupted or unreadable."
		return {}

	_refresh_default_save_warning()
	return parsed

func save_save(path: String, blob: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_save_warning_message = "Local save storage is not available."
		return false

	file.store_string(JSON.stringify(blob))
	file.flush()
	_refresh_default_save_warning()
	return true

func show_rewarded_ad(_placement: String) -> Dictionary:
	return {
		"ok": true,
		"completed": true,
		"error": "",
		"mock": true
	}

func show_interstitial(_placement: String) -> Dictionary:
	return {
		"ok": true,
		"completed": true,
		"error": "",
		"mock": true
	}

func track_event(_name: String, _params: Dictionary = {}) -> void:
	pass

func share(_payload: Dictionary) -> bool:
	return true

func vibrate_short() -> void:
	pass

func get_platform_name() -> String:
	return "unknown"

func get_launch_context() -> Dictionary:
	return _launch_context.duplicate(true)

func get_ui_insets() -> Dictionary:
	return _ui_insets.duplicate(true)

func normalize_input_position(position: Vector2, _viewport_size: Vector2) -> Vector2:
	return position

func login() -> Dictionary:
	return {
		"ok": false,
		"error": "login_unavailable"
	}

func load_subpackage(name: String) -> Dictionary:
	return {
		"ok": true,
		"name": name,
		"loaded": true,
		"error": "",
		"mock": true
	}

func report_scene(scene_id: Variant, dimension: Dictionary = {}, metric: Dictionary = {}, cost_time: Variant = null) -> Dictionary:
	return {
		"ok": true,
		"scene_id": scene_id,
		"dimension": dimension.duplicate(true),
		"metric": metric.duplicate(true),
		"cost_time": cost_time,
		"mock": true
	}

func run_platform_api_probe(_options: Dictionary = {}) -> Dictionary:
	return _finalize_platform_api_probe({
		"probe": _probe_skip("platform_api_probe_unavailable")
	}, {
		"platform": get_platform_name()
	})

func get_save_warning_message() -> String:
	return _save_warning_message

func _refresh_default_save_warning() -> void:
	if OS.get_name() == "Web":
		_save_warning_message = "Browser save persistence depends on container storage policy."
	else:
		_save_warning_message = ""

func _probe_ok(detail: Dictionary = {}) -> Dictionary:
	return {
		"ok": true,
		"skipped": false,
		"error": "",
		"detail": detail.duplicate(true)
	}

func _probe_fail(error: String, detail: Dictionary = {}) -> Dictionary:
	return {
		"ok": false,
		"skipped": false,
		"error": error,
		"detail": detail.duplicate(true)
	}

func _probe_skip(reason: String, detail: Dictionary = {}) -> Dictionary:
	return {
		"ok": false,
		"skipped": true,
		"error": reason,
		"detail": detail.duplicate(true)
	}

func _finalize_platform_api_probe(results: Dictionary, meta: Dictionary = {}) -> Dictionary:
	var normalized_results: Dictionary = {}
	var summary := {
		"passed": 0,
		"failed": 0,
		"skipped": 0
	}
	for key in results.keys():
		var raw_entry: Variant = results.get(key)
		var entry: Dictionary = raw_entry if typeof(raw_entry) == TYPE_DICTIONARY else _probe_fail("invalid_probe_result", {
			"value_type": typeof(raw_entry)
		})
		var normalized := {
			"ok": _probe_truthy(entry.get("ok", false)),
			"skipped": _probe_truthy(entry.get("skipped", false)),
			"error": String(entry.get("error", "")),
			"detail": _probe_detail(entry.get("detail", {}))
		}
		normalized_results[key] = normalized
		if bool(normalized["ok"]):
			summary["passed"] = int(summary["passed"]) + 1
		elif bool(normalized["skipped"]):
			summary["skipped"] = int(summary["skipped"]) + 1
		else:
			summary["failed"] = int(summary["failed"]) + 1

	var report := {
		"ok": int(summary["failed"]) == 0,
		"platform": get_platform_name(),
		"results": normalized_results,
		"summary": summary,
		"timestamp_unix": Time.get_unix_time_from_system()
	}
	for key in meta.keys():
		report[key] = meta[key]
	return report

func _append_probe_results(target: Dictionary, prefix: String, nested_results: Dictionary) -> void:
	for key in nested_results.keys():
		target["%s%s" % [prefix, String(key)]] = _probe_detail(nested_results.get(key, {}))

func _probe_requested(options: Dictionary, call_name: String) -> bool:
	if not options.has("calls"):
		return true
	var calls_variant: Variant = options.get("calls", [])
	if typeof(calls_variant) != TYPE_ARRAY:
		return true
	var calls: Array = calls_variant
	if calls.is_empty():
		return true
	var expected := call_name.strip_edges().to_lower()
	for raw_call in calls:
		if String(raw_call).strip_edges().to_lower() == expected:
			return true
	return false

func _probe_option_bool(options: Dictionary, key: String, default_value: bool = false) -> bool:
	if not options.has(key):
		return default_value
	return _probe_truthy(options.get(key, default_value))

func _probe_option_string(options: Dictionary, key: String, default_value: String = "") -> String:
	if not options.has(key):
		return default_value
	return String(options.get(key, default_value))

func _probe_option_int(options: Dictionary, key: String, default_value: int = 0) -> int:
	if not options.has(key):
		return default_value
	var raw_value: Variant = options.get(key, default_value)
	match typeof(raw_value):
		TYPE_INT:
			return int(raw_value)
		TYPE_FLOAT:
			return int(raw_value)
		TYPE_STRING:
			var text := String(raw_value).strip_edges()
			return int(text) if text.is_valid_int() else default_value
		_:
			return default_value

func _probe_detail(raw_detail: Variant) -> Dictionary:
	return (raw_detail as Dictionary).duplicate(true) if typeof(raw_detail) == TYPE_DICTIONARY else {}

func _probe_truthy(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			var text := String(value).strip_edges().to_lower()
			return text == "true" or text == "1" or text == "yes" or text == "on"
		TYPE_NIL:
			return false
		_:
			return value != null
