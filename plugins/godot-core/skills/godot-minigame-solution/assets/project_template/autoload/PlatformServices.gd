extends Node

signal rewarded_ad_requested(placement: String)
signal interstitial_requested(placement: String)
signal app_show(context: Dictionary)
signal app_hide
signal platform_api_probe_completed(report: Dictionary)

const SAVE_PATH := "user://save_v1.json"
const WebPlatformBackendScript := preload("res://platform/web_mock/WebPlatformBackend.gd")
const DouyinPlatformBackendScript := preload("res://platform/douyin/DouyinPlatformBackend.gd")
const WeChatPlatformBackendScript := preload("res://platform/wechat/WeChatPlatformBackend.gd")

var last_events: Array[Dictionary] = []
var last_platform_api_probe_report: Dictionary = {}
var save_warning_message := ""

var _backend = null
var _initialized := false
var _resolved_platform_name := ""

func _ready() -> void:
	pass

func initialize() -> void:
	_ensure_backend()
	if _initialized:
		return
	await _backend.initialize()
	_sync_warning_message()
	_initialized = true

func load_save() -> Dictionary:
	_ensure_backend()
	var data: Dictionary = _backend.load_save(SAVE_PATH)
	_sync_warning_message()
	return data

func save_save(blob: Dictionary) -> bool:
	_ensure_backend()
	var ok: bool = _backend.save_save(SAVE_PATH, blob)
	_sync_warning_message()
	return ok

func show_rewarded_ad(placement: String) -> Dictionary:
	_ensure_backend()
	emit_signal("rewarded_ad_requested", placement)
	var result: Dictionary = await _backend.show_rewarded_ad(placement)
	return result

func show_interstitial(placement: String) -> Dictionary:
	_ensure_backend()
	emit_signal("interstitial_requested", placement)
	return await _backend.show_interstitial(placement)

func track_event(name: String, params: Dictionary = {}) -> void:
	_ensure_backend()
	last_events.append({
		"name": name,
		"params": params.duplicate(true),
		"timestamp": Time.get_unix_time_from_system()
	})
	if OS.is_debug_build():
		print("TRACK ", name, " ", JSON.stringify(params))
	if last_events.size() > 128:
		last_events.pop_front()
	_backend.track_event(name, params)

func share(payload: Dictionary) -> bool:
	_ensure_backend()
	return _backend.share(payload)

func vibrate_short() -> void:
	_ensure_backend()
	_backend.vibrate_short()

func get_safe_area() -> Rect2:
	var viewport_size := get_viewport().get_visible_rect().size
	var insets := get_ui_insets()
	return Rect2(
		Vector2(float(insets.get("left", 0.0)), float(insets.get("top", 0.0))),
		Vector2(
			maxf(0.0, viewport_size.x - float(insets.get("left", 0.0)) - float(insets.get("right", 0.0))),
			maxf(0.0, viewport_size.y - float(insets.get("top", 0.0)) - float(insets.get("bottom", 0.0)))
		)
	)

func get_platform_name() -> String:
	_ensure_backend()
	return _backend.get_platform_name()

func get_launch_context() -> Dictionary:
	_ensure_backend()
	return _backend.get_launch_context()

func get_ui_insets() -> Dictionary:
	_ensure_backend()
	return _backend.get_ui_insets()

func normalize_input_position(position: Vector2, viewport_size: Vector2 = Vector2.ZERO) -> Vector2:
	_ensure_backend()
	var resolved_viewport_size := viewport_size
	if resolved_viewport_size == Vector2.ZERO:
		resolved_viewport_size = get_viewport().get_visible_rect().size
	return _backend.normalize_input_position(position, resolved_viewport_size)

func login() -> Dictionary:
	_ensure_backend()
	return await _backend.login()

func load_subpackage(name: String) -> Dictionary:
	_ensure_backend()
	return await _backend.load_subpackage(name)

func report_scene(scene_id: Variant, dimension: Dictionary = {}, metric: Dictionary = {}, cost_time: Variant = null) -> Dictionary:
	_ensure_backend()
	return await _backend.report_scene(scene_id, dimension, metric, cost_time)

func run_platform_api_probe(options: Dictionary = {}) -> Dictionary:
	_ensure_backend()
	var merged_options := build_launch_platform_api_probe_options()
	for key in options.keys():
		merged_options[key] = options[key]
	var report: Dictionary = await _backend.run_platform_api_probe(merged_options)
	last_platform_api_probe_report = report.duplicate(true)
	emit_signal("platform_api_probe_completed", last_platform_api_probe_report)
	if OS.is_debug_build():
		print("[godot-platform] api probe ", JSON.stringify(last_platform_api_probe_report))
	return last_platform_api_probe_report.duplicate(true)

func should_auto_run_platform_api_probe() -> bool:
	var query := _get_launch_query()
	return _query_flag(query, "api_probe") or _query_flag(query, "platform_api_probe")

func build_launch_platform_api_probe_options() -> Dictionary:
	var query := _get_launch_query()
	var options: Dictionary = {}
	var calls_csv := _query_string(query, "api_probe_calls", _query_string(query, "platform_api_probe_calls", ""))
	if not calls_csv.is_empty():
		var calls: Array[String] = []
		for raw_call in calls_csv.split(",", false):
			var call_name := String(raw_call).strip_edges().to_lower()
			if not call_name.is_empty():
				calls.append(call_name)
		if not calls.is_empty():
			options["calls"] = calls
	options["allow_ui"] = _query_flag(query, "api_probe_ui") or _query_flag(query, "platform_api_probe_ui")
	options["request_url"] = _query_string(query, "api_probe_request_url", _query_string(query, "platform_api_probe_request_url", ""))
	options["socket_url"] = _query_string(query, "api_probe_socket_url", _query_string(query, "platform_api_probe_socket_url", ""))
	options["subpackage_name"] = _query_string(query, "api_probe_subpackage", _query_string(query, "platform_api_probe_subpackage", ""))
	options["report_scene_id"] = _query_string(query, "api_probe_scene_id", _query_string(query, "platform_api_probe_scene_id", ""))
	options["rewarded_placement"] = _query_string(query, "api_probe_rewarded_placement", "revive")
	options["share_query"] = _query_string(query, "api_probe_share_query", "platform_api_probe=1")
	options["share_path"] = _query_string(query, "api_probe_share_path", "")
	options["temp_path"] = _query_string(query, "api_probe_temp_path", "user://platform_api_probe.json")
	var timeout_text := _query_string(query, "api_probe_timeout_ms", "1500")
	options["timeout_ms"] = int(timeout_text) if timeout_text.is_valid_int() else 1500
	return options

func _ensure_backend() -> void:
	if _backend != null:
		return
	var backend_script: GDScript = _resolve_backend_script()
	_debug_log_backend_resolution(backend_script)
	_backend = backend_script.new()
	add_child(_backend)
	_backend.app_show.connect(_handle_app_show)
	_backend.app_hide.connect(_handle_app_hide)
	_sync_warning_message()

func _resolve_backend_script() -> GDScript:
	var platform_name := _resolve_platform_name()
	if platform_name == "douyin_minigame":
		return DouyinPlatformBackendScript
	if platform_name == "wechat_minigame":
		return WeChatPlatformBackendScript
	return WebPlatformBackendScript

func _resolve_platform_name() -> String:
	if not _resolved_platform_name.is_empty():
		return _resolved_platform_name
	if OS.has_feature("wechat_minigame"):
		_resolved_platform_name = "wechat_minigame"
		return _resolved_platform_name
	if OS.has_feature("douyin_minigame") or OS.has_feature("tt"):
		_resolved_platform_name = "douyin_minigame"
		return _resolved_platform_name
	var tt_node := _get_tt_node()
	if tt_node != null and tt_node.has_method("is_run_in_tt") and _is_truthy(tt_node.call("is_run_in_tt")):
		_resolved_platform_name = "douyin_minigame"
		return _resolved_platform_name
	_resolved_platform_name = "web_mock"
	return _resolved_platform_name

func _handle_app_show(context: Dictionary) -> void:
	emit_signal("app_show", context)

func _handle_app_hide() -> void:
	emit_signal("app_hide")

func _sync_warning_message() -> void:
	if _backend == null:
		save_warning_message = ""
		return
	save_warning_message = _backend.get_save_warning_message()

func _is_tt_runtime() -> bool:
	return _resolve_platform_name() == "douyin_minigame"

func _is_wechat_runtime() -> bool:
	return _resolve_platform_name() == "wechat_minigame"

func _get_tt_node() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root.get_node_or_null("tt")
	return null

func _get_wechat_bridge():
	if OS.get_name() != "Web":
		return null
	if _resolve_platform_name() != "wechat_minigame":
		return null
	return JavaScriptBridge.get_interface("godotWx")

func _has_wechat_bridge_interface() -> bool:
	return _resolve_platform_name() == "wechat_minigame"

func _has_tt_bridge_interface() -> bool:
	return _resolve_platform_name() == "douyin_minigame"

func _debug_log_backend_resolution(backend_script: GDScript) -> void:
	if not OS.is_debug_build():
		return
	var tt_node := _get_tt_node()
	var tt_autoload_ready := false
	if tt_node != null and tt_node.has_method("is_run_in_tt"):
		tt_autoload_ready = _is_truthy(tt_node.call("is_run_in_tt"))
	print(
		"[godot-platform] resolve backend=",
		_backend_label(backend_script),
		" runtime=",
		_resolve_platform_name(),
		" os=",
		OS.get_name(),
		" tt_autoload=",
		tt_autoload_ready,
		" tt_interface=",
		_has_tt_bridge_interface(),
		" wx_interface=",
		_has_wechat_bridge_interface()
	)

func _backend_label(backend_script: GDScript) -> String:
	if backend_script == DouyinPlatformBackendScript:
		return "douyin_minigame"
	if backend_script == WeChatPlatformBackendScript:
		return "wechat_minigame"
	return "web_mock"

func _is_truthy(value: Variant) -> bool:
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

func _get_launch_query() -> Dictionary:
	var context := get_launch_context()
	if typeof(context.get("query", {})) == TYPE_DICTIONARY:
		return (context.get("query", {}) as Dictionary).duplicate(true)
	return {}

func _query_flag(query: Dictionary, key: String) -> bool:
	return _is_truthy(query.get(key, false))

func _query_string(query: Dictionary, key: String, default_value: String = "") -> String:
	if not query.has(key):
		return default_value
	return String(query.get(key, default_value))
