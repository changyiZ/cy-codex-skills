extends "res://platform/PlatformBackend.gd"
class_name WeChatPlatformBackend

const PlatformAsyncResultScript := preload("res://platform/AsyncResult.gd")
const VariantTruthScript := preload("res://scripts/core/VariantTruth.gd")
const SAVE_PREFIX := "user://"
const SIDEBAR_SCENES := {
	1154: true,
	1155: true
}

var _bridge = null
var _lifecycle_connected := false
var _active_callbacks: Array = []
var _loaded_subpackages: Dictionary = {}
var _share_payload: Dictionary = {}
var _did_log_input_scaling := false

func initialize() -> void:
	_bridge = _get_bridge()
	if _bridge == null:
		_refresh_default_save_warning()
		return
	_connect_lifecycle()
	_launch_context = _build_launch_context(_get_launch_options(), true)
	_share_payload = _default_share_payload()
	_configure_share_payload(_share_payload)
	_refresh_ui_insets()
	_save_warning_message = "WeChat mini-game saves persist in wx.env.USER_DATA_PATH."

func load_save(path: String) -> Dictionary:
	var bridge = _get_bridge()
	if bridge == null:
		return super.load_save(path)
	var result := _parse_json_dict(bridge.readUserFileJson(_to_user_relative_path(path)))
	if not VariantTruthScript.as_bool(result.get("ok", false)):
		_save_warning_message = String(result.get("error", "wechat_save_read_failed"))
		return {}
	if not VariantTruthScript.as_bool(result.get("exists", false)):
		_save_warning_message = ""
		return {}
	var parsed: Variant = JSON.parse_string(String(result.get("data", "")))
	if typeof(parsed) != TYPE_DICTIONARY:
		_save_warning_message = "WeChat save data is corrupted or unreadable."
		return {}
	_save_warning_message = ""
	return (parsed as Dictionary).duplicate(true)

func save_save(path: String, blob: Dictionary) -> bool:
	var bridge = _get_bridge()
	if bridge == null:
		return super.save_save(path, blob)
	var result := _parse_json_dict(bridge.writeUserFileJson(_to_user_relative_path(path), JSON.stringify(blob)))
	if not VariantTruthScript.as_bool(result.get("ok", false)):
		_save_warning_message = String(result.get("error", "wechat_save_write_failed"))
		return false
	_save_warning_message = ""
	return true

func show_rewarded_ad(placement: String) -> Dictionary:
	var ad_unit_id := _get_rewarded_ad_unit_id(placement)
	if ad_unit_id.is_empty():
		return {
			"ok": false,
			"completed": false,
			"error": "missing_rewarded_ad_unit_id",
			"placement": placement
		}
	return await _call_async_bridge("showRewardedAdJson", [ad_unit_id, placement], {
		"ok": false,
		"completed": false,
		"error": "rewarded_ad_unavailable",
		"placement": placement
	})

func track_event(name: String, params: Dictionary = {}) -> void:
	var bridge = _get_bridge()
	if bridge == null:
		return
	bridge.trackEventJson(JSON.stringify({
		"name": name,
		"params": params.duplicate(true)
	}))

func share(payload: Dictionary) -> bool:
	var next_payload := _default_share_payload()
	for key in _share_payload.keys():
		next_payload[key] = _share_payload[key]
	for key in payload.keys():
		next_payload[key] = payload[key]
	_share_payload = next_payload
	return _configure_share_payload(_share_payload)

func vibrate_short() -> void:
	var bridge = _get_bridge()
	if bridge != null:
		bridge.vibrateShort()

func get_platform_name() -> String:
	return "wechat_minigame"

func get_ui_insets() -> Dictionary:
	_refresh_ui_insets()
	return _ui_insets.duplicate(true)

func normalize_input_position(position: Vector2, viewport_size: Vector2) -> Vector2:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return position
	var normalized := position
	if OS.is_debug_build() and not _did_log_input_scaling:
		_did_log_input_scaling = true
		print("[godot-wx] input scale raw=", position, " viewport=", viewport_size, " ref=", _input_reference_size, " normalized=", normalized)
	return normalized

func login() -> Dictionary:
	return await _call_async_bridge("login", [], {
		"ok": false,
		"error": "login_unavailable"
	})

func load_subpackage(name: String) -> Dictionary:
	if _loaded_subpackages.get(name, false):
		return {
			"ok": true,
			"name": name,
			"loaded": true,
			"error": ""
		}
	var result: Dictionary = await _call_async_bridge("loadSubpackageJson", [name], {
		"ok": false,
		"name": name,
		"loaded": false,
		"error": "load_subpackage_unavailable"
	})
	if VariantTruthScript.as_bool(result.get("ok", false)):
		_loaded_subpackages[name] = true
	return result

func run_platform_api_probe(options: Dictionary = {}) -> Dictionary:
	var results: Dictionary = {}
	if _probe_requested(options, "launch_context"):
		results["launch_context"] = _probe_ok(get_launch_context())
	if _probe_requested(options, "ui_insets"):
		results["ui_insets"] = _probe_ok(get_ui_insets())
	if _probe_requested(options, "storage"):
		results["storage"] = _probe_storage(options)
	if _probe_requested(options, "share"):
		var share_payload := {
			"query": _probe_option_string(options, "share_query", "platform_api_probe=1"),
			"path": _probe_option_string(options, "share_path", "")
		}
		var share_ok := share(share_payload)
		results["share"] = _probe_ok({
			"configured": share_ok,
			"payload": _share_payload.duplicate(true)
		}) if share_ok else _probe_fail("share_configure_failed")
	if _probe_requested(options, "vibrate"):
		vibrate_short()
		results["vibrate"] = _probe_ok()
	if _probe_requested(options, "login"):
		var login_result: Dictionary = await login()
		results["login"] = _probe_ok(_probe_detail(login_result.get("data", {}))) if VariantTruthScript.as_bool(login_result.get("ok", false)) else _probe_fail(String(login_result.get("error", "login_failed")), login_result)
	if _probe_requested(options, "load_subpackage"):
		var subpackage_name := _probe_option_string(options, "subpackage_name", "")
		if subpackage_name.is_empty():
			results["load_subpackage"] = _probe_skip("subpackage_name_missing")
		else:
			var subpackage_result: Dictionary = await load_subpackage(subpackage_name)
			results["load_subpackage"] = _probe_ok(subpackage_result) if VariantTruthScript.as_bool(subpackage_result.get("ok", false)) else _probe_fail(String(subpackage_result.get("error", "load_subpackage_failed")), subpackage_result)
	if _probe_requested(options, "rewarded_ad"):
		var rewarded_placement := _probe_option_string(options, "rewarded_placement", "revive")
		if not _probe_option_bool(options, "allow_ui", false):
			results["rewarded_ad"] = _probe_skip("ui_not_allowed", {
				"placement": rewarded_placement
			})
		elif _get_rewarded_ad_unit_id(rewarded_placement).is_empty():
			results["rewarded_ad"] = _probe_skip("rewarded_ad_unit_id_missing", {
				"placement": rewarded_placement
			})
		else:
			var rewarded_result: Dictionary = await show_rewarded_ad(rewarded_placement)
			results["rewarded_ad"] = _probe_ok(rewarded_result) if VariantTruthScript.as_bool(rewarded_result.get("ok", false)) else _probe_fail(String(rewarded_result.get("error", "rewarded_ad_failed")), rewarded_result)

	var runtime_report: Dictionary = await _call_runtime_probe(_build_runtime_probe_plan(options), {
		"ok": false,
		"error": "runtime_probe_unavailable"
	})
	if typeof(runtime_report.get("results", {})) == TYPE_DICTIONARY:
		_append_probe_results(results, "runtime_", runtime_report.get("results", {}))
	else:
		results["runtime_probe"] = _probe_fail(String(runtime_report.get("error", "runtime_probe_unavailable")), runtime_report)
	return _finalize_platform_api_probe(results, {
		"platform": get_platform_name(),
		"bridge": "godotWx"
	})

func _connect_lifecycle() -> void:
	if _lifecycle_connected:
		return
	var bridge = _get_bridge()
	if bridge == null:
		return
	var on_show_callback = JavaScriptBridge.create_callback(_handle_bridge_show)
	_active_callbacks.append(on_show_callback)
	bridge.onShow(on_show_callback)
	var on_hide_callback = JavaScriptBridge.create_callback(_handle_bridge_hide)
	_active_callbacks.append(on_hide_callback)
	bridge.onHide(on_hide_callback)
	_lifecycle_connected = true

func _handle_bridge_show(args: Array) -> void:
	_launch_context = _build_launch_context(_parse_callback_dict(args), false)
	_refresh_ui_insets()
	emit_signal("app_show", get_launch_context())

func _handle_bridge_hide(_args: Array) -> void:
	emit_signal("app_hide")

func _build_launch_context(source: Dictionary, is_cold_start: bool) -> Dictionary:
	var scene_id := int(source.get("scene", 0))
	var query: Dictionary = {}
	if typeof(source.get("query", {})) == TYPE_DICTIONARY:
		query = (source.get("query", {}) as Dictionary).duplicate(true)
	var referrer_info: Dictionary = {}
	if typeof(source.get("referrerInfo", {})) == TYPE_DICTIONARY:
		var raw_referrer := source.get("referrerInfo", {}) as Dictionary
		referrer_info = raw_referrer.duplicate(true)
	var scene := str(scene_id)
	var scene_tail := scene
	return {
		"scene": scene,
		"scene_id": scene_id,
		"scene_tail": scene_tail,
		"sub_scene": String(query.get("sub_scene", "")),
		"query": query,
		"referer_info": referrer_info,
		"share_ticket": String(source.get("shareTicket", "")),
		"show_from": null,
		"launch_from": "",
		"location": "",
		"is_sidebar_entry": SIDEBAR_SCENES.has(scene_id),
		"is_cold_start": is_cold_start,
		"platform": get_platform_name()
	}

func _refresh_ui_insets() -> void:
	if not is_inside_tree():
		return
	var bridge = _get_bridge()
	if bridge == null:
		return
	var system_info := _parse_json_dict(bridge.getSystemInfoJson())
	var safe_area: Dictionary = {}
	if typeof(system_info.get("safeArea", {})) == TYPE_DICTIONARY:
		safe_area = (system_info.get("safeArea", {}) as Dictionary).duplicate(true)
	var menu_rect := _parse_json_dict(bridge.getMenuButtonRectJson())
	var viewport_size := get_viewport().get_visible_rect().size
	var reference_width := maxf(1.0, float(system_info.get("windowWidth", system_info.get("screenWidth", 0.0))))
	var reference_height := maxf(1.0, float(system_info.get("windowHeight", system_info.get("screenHeight", 0.0))))
	_input_reference_size = Vector2(reference_width, reference_height)
	if safe_area.is_empty():
		_ui_insets = DEFAULT_INSETS.duplicate(true)
		return
	var screen_width := maxf(1.0, _input_reference_size.x)
	var screen_height := maxf(1.0, _input_reference_size.y)
	var scale_x := viewport_size.x / screen_width
	var scale_y := viewport_size.y / screen_height
	var safe_right := float(safe_area.get("right", screen_width))
	var safe_bottom := float(safe_area.get("bottom", screen_height))
	var menu_left := float(menu_rect.get("left", safe_right))
	var menu_bottom := float(menu_rect.get("bottom", float(safe_area.get("top", 0.0))))
	var right_safe := maxf(screen_width - safe_right, screen_width - menu_left)
	var top_safe := maxf(float(safe_area.get("top", 0.0)), menu_bottom)
	_ui_insets = {
		"left": float(safe_area.get("left", 0.0)) * scale_x,
		"top": top_safe * scale_y,
		"right": right_safe * scale_x,
		"bottom": (screen_height - safe_bottom) * scale_y
	}

func _get_bridge():
	if OS.get_name() != "Web":
		return null
	if _bridge == null:
		_bridge = JavaScriptBridge.get_interface("godotWx")
	return _bridge

func _has_bridge_interface() -> bool:
	return true

func _get_launch_options() -> Dictionary:
	var bridge = _get_bridge()
	if bridge == null:
		return {}
	return _parse_json_dict(bridge.getLaunchOptionsJson())

func _get_runtime_probe_bridge():
	if OS.get_name() != "Web":
		return null
	return JavaScriptBridge.get_interface("godotMinigameProbe")

func _call_async_bridge(method_name: String, args: Array, fallback: Dictionary) -> Dictionary:
	var bridge = _get_bridge()
	if bridge == null:
		return fallback.duplicate(true)
	var waiter = PlatformAsyncResultScript.new()
	var callback_holder: Dictionary = {}
	var callback = JavaScriptBridge.create_callback(func(callback_args: Array) -> void:
		_release_callback(callback_holder.get("value"))
		waiter.finish(_parse_callback_dict(callback_args, fallback))
	)
	callback_holder["value"] = callback
	_active_callbacks.append(callback)
	if not _invoke_async_bridge(bridge, method_name, args, callback):
		_release_callback(callback)
		return fallback.duplicate(true)
	var result: Dictionary = await waiter.resolved
	return result

func _call_runtime_probe(plan: Dictionary, fallback: Dictionary) -> Dictionary:
	var bridge = _get_runtime_probe_bridge()
	if bridge == null:
		return fallback.duplicate(true)
	var waiter = PlatformAsyncResultScript.new()
	var callback_holder: Dictionary = {}
	var callback = JavaScriptBridge.create_callback(func(callback_args: Array) -> void:
		_release_callback(callback_holder.get("value"))
		waiter.finish(_parse_callback_dict(callback_args, fallback))
	)
	callback_holder["value"] = callback
	_active_callbacks.append(callback)
	bridge.runProbeJson(JSON.stringify(plan), callback)
	return await waiter.resolved

func _release_callback(callback) -> void:
	_active_callbacks.erase(callback)

func _parse_callback_dict(args: Array, fallback: Dictionary = {}) -> Dictionary:
	if args.is_empty():
		return fallback.duplicate(true)
	return _variant_to_dictionary(args[0], fallback)

func _parse_json_dict(raw: Variant, fallback: Dictionary = {}) -> Dictionary:
	return _variant_to_dictionary(raw, fallback)

func _variant_to_dictionary(raw: Variant, fallback: Dictionary = {}) -> Dictionary:
	if typeof(raw) == TYPE_DICTIONARY:
		return (raw as Dictionary).duplicate(true)
	if raw == null:
		return fallback.duplicate(true)
	var parsed: Variant = JSON.parse_string(String(raw))
	if typeof(parsed) == TYPE_DICTIONARY:
		return (parsed as Dictionary).duplicate(true)
	return fallback.duplicate(true)

func _to_user_relative_path(path: String) -> String:
	var relative := path
	if relative.begins_with(SAVE_PREFIX):
		relative = relative.substr(SAVE_PREFIX.length())
	return relative.lstrip("/")

func _default_share_payload() -> Dictionary:
	var title: String = "Godot Mini-game"
	if ProjectSettings.has_setting("wechat/share_title"):
		title = String(ProjectSettings.get_setting("wechat/share_title"))
	var image_url: String = ""
	if ProjectSettings.has_setting("wechat/share_image_url"):
		image_url = String(ProjectSettings.get_setting("wechat/share_image_url"))
	return {
		"title": String(title),
		"imageUrl": String(image_url),
		"query": "",
		"path": ""
	}

func _configure_share_payload(payload: Dictionary) -> bool:
	var bridge = _get_bridge()
	if bridge == null:
		return false
	return VariantTruthScript.as_bool(bridge.configureSharePayloadJson(JSON.stringify(payload)))

func _get_rewarded_ad_unit_id(placement: String) -> String:
	if placement == "revive" and ProjectSettings.has_setting("wechat/rewarded_revive_ad_unit_id"):
		return String(ProjectSettings.get_setting("wechat/rewarded_revive_ad_unit_id"))
	return ""

func _probe_storage(options: Dictionary) -> Dictionary:
	var temp_path := _probe_option_string(options, "temp_path", "user://platform_api_probe.json")
	var payload := {
		"platform": get_platform_name(),
		"timestamp_unix": Time.get_unix_time_from_system()
	}
	if not save_save(temp_path, payload):
		return _probe_fail("storage_write_failed", {
			"path": temp_path,
			"warning": get_save_warning_message()
		})
	var loaded := load_save(temp_path)
	if loaded.is_empty():
		return _probe_fail("storage_read_failed", {
			"path": temp_path,
			"warning": get_save_warning_message()
		})
	return _probe_ok({
		"path": temp_path,
		"loaded_keys": loaded.keys()
	})

func _build_runtime_probe_plan(options: Dictionary) -> Dictionary:
	var plan := {
		"timeout_ms": _probe_option_int(options, "timeout_ms", 1500),
		"request_url": _probe_option_string(options, "request_url", ""),
		"socket_url": _probe_option_string(options, "socket_url", ""),
		"allow_ui": _probe_option_bool(options, "allow_ui", false)
	}
	if options.has("calls"):
		plan["calls"] = options.get("calls", [])
	return plan

func _invoke_async_bridge(bridge, method_name: String, args: Array, callback) -> bool:
	match method_name:
		"login":
			bridge.login(callback)
			return true
		"loadSubpackageJson":
			var subpackage_name := String(args[0]) if args.size() > 0 else ""
			bridge.loadSubpackageJson(subpackage_name, callback)
			return true
		"showRewardedAdJson":
			var ad_unit_id := String(args[0]) if args.size() > 0 else ""
			var placement := String(args[1]) if args.size() > 1 else ""
			bridge.showRewardedAdJson(ad_unit_id, placement, callback)
			return true
		_:
			return false
