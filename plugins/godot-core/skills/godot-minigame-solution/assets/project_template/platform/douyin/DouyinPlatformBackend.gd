extends "res://platform/PlatformBackend.gd"
class_name DouyinPlatformBackend

const PlatformAsyncResultScript := preload("res://platform/AsyncResult.gd")
const SubpackageManifestScript := preload("res://addons/minigame_solution/godot_contract/SubpackageManifest.gd")
const VariantTruthScript := preload("res://scripts/core/VariantTruth.gd")
const SIDEBAR_SCENES := {
	"1001": true,
	"1036": true,
	"1042": true
}
var _lifecycle_connected := false
var _loaded_subpackages: Dictionary = {}
var _rewarded_ads: Dictionary = {}
var _active_callbacks: Array = []

func initialize() -> void:
	if not _is_tt_runtime():
		_refresh_default_save_warning()
		return

	var tt_node = _get_tt_node()
	_connect_lifecycle()
	_launch_context = _build_launch_context(tt_node.get_launch_options_sync(), true)
	_refresh_ui_insets()
	_refresh_default_save_warning()

func show_rewarded_ad(placement: String) -> Dictionary:
	var ad_unit_id := _get_rewarded_ad_unit_id(placement)
	if ad_unit_id.is_empty():
		return {
			"ok": false,
			"completed": false,
			"error": "missing_rewarded_ad_unit_id",
			"placement": placement
		}

	var ad: RewardedVideoAd = _get_rewarded_ad(ad_unit_id)
	var result_waiter = PlatformAsyncResultScript.new()

	ad.on_close.connect(func (payload: RewardedVideoAd.OnCloseArg) -> void:
		result_waiter.finish({
			"ok": VariantTruthScript.as_bool(payload.is_ended),
			"completed": VariantTruthScript.as_bool(payload.is_ended),
			"error": "" if VariantTruthScript.as_bool(payload.is_ended) else "closed_early",
			"placement": placement
		})
	, CONNECT_ONE_SHOT)

	ad.on_error.connect(func (_payload: RewardedVideoAd.OnErrorArg) -> void:
		result_waiter.finish({
			"ok": false,
			"completed": false,
			"error": "rewarded_ad_error",
			"placement": placement
		})
	, CONNECT_ONE_SHOT)

	ad.load()
	ad.show()
	var result: Dictionary = await result_waiter.resolved
	return result

func show_interstitial(placement: String) -> Dictionary:
	var ad_unit_id := _get_interstitial_ad_unit_id()
	if ad_unit_id.is_empty():
		return {
			"ok": false,
			"completed": false,
			"error": "missing_interstitial_ad_unit_id",
			"placement": placement
		}

	var tt_node = _get_tt_node()
	var ad: InterstitialAd = tt_node.create_interstitial_ad({
		"adUnitId": ad_unit_id
	})
	var result_waiter = PlatformAsyncResultScript.new()
	ad.on_close.connect(func () -> void:
		result_waiter.finish({
			"ok": true,
			"completed": true,
			"error": "",
			"placement": placement
		})
	, CONNECT_ONE_SHOT)
	ad.on_error.connect(func (payload: InterstitialAd.OnErrorArg) -> void:
		result_waiter.finish({
			"ok": false,
			"completed": false,
			"error": String(payload.err_msg),
			"placement": placement
		})
	, CONNECT_ONE_SHOT)
	ad.load()
	ad.show()
	var result: Dictionary = await result_waiter.resolved
	ad.destroy()
	return result

func track_event(name: String, params: Dictionary = {}) -> void:
	var tt_node = _get_tt_node()
	if tt_node != null and _is_tt_runtime():
		tt_node.report_analytics(name, params)

func share(payload: Dictionary) -> bool:
	if not _is_tt_runtime():
		return false
	var tt_node = _get_tt_node()
	var task = tt_node.share_app_message_async()
	if payload.has("title"):
		task.title = String(payload.get("title", ""))
	if payload.has("desc"):
		task.desc = String(payload.get("desc", ""))
	if payload.has("channel"):
		task.channel = String(payload.get("channel", ""))
	if payload.has("query"):
		task.query = String(payload.get("query", ""))
	if payload.has("template_id"):
		task.template_id = String(payload.get("template_id", ""))
	if payload.has("extra") and typeof(payload.get("extra")) == TYPE_DICTIONARY:
		task.extra = payload.get("extra", {}).duplicate(true)
	await task.invoke()
	return task.is_success

func get_platform_name() -> String:
	return "douyin_minigame"

func get_ui_insets() -> Dictionary:
	_refresh_ui_insets()
	return _ui_insets.duplicate(true)

func normalize_input_position(position: Vector2, viewport_size: Vector2) -> Vector2:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return position
	if position.x >= -1.0 and position.y >= -1.0 and position.x <= viewport_size.x + 1.0 and position.y <= viewport_size.y + 1.0:
		return position
	if _input_reference_size.x <= 0.0 or _input_reference_size.y <= 0.0:
		return position
	return Vector2(
		position.x * viewport_size.x / _input_reference_size.x,
		position.y * viewport_size.y / _input_reference_size.y
	)

func login() -> Dictionary:
	var tt_node = _get_tt_node()
	var task = tt_node.login_async()
	await task.invoke()
	if task.is_success:
		var result = task.get_result_success()
		return {
			"ok": true,
			"data": {
				"code": String(result.code),
				"anonymous_code": String(result.anonymous_code),
				"is_login": VariantTruthScript.as_bool(result.is_login)
			},
			"error": ""
		}
	return {
		"ok": false,
		"error": String(task.get_result_fail().err_msg)
	}

func load_subpackage(name: String) -> Dictionary:
	if _loaded_subpackages.get(name, false):
		return {
			"ok": true,
			"name": name,
			"loaded": true,
			"error": ""
		}

	var subpackage_config := SubpackageManifestScript.find_subpackage("douyin", name)
	if subpackage_config.is_empty():
		return {
			"ok": false,
			"name": name,
			"loaded": false,
			"error": "unknown_subpackage"
		}

	var tt_node = _get_tt_node()
	var task = tt_node.load_subpackage_async()
	task.name = name
	await task.invoke()
	if not task.is_success:
		return {
			"ok": false,
			"name": name,
			"loaded": false,
			"error": String(task.get_result_fail().err_msg)
		}

	var pack_path := String(subpackage_config.get("pack_path", ""))
	if pack_path.is_empty():
		return {
			"ok": false,
			"name": name,
			"loaded": false,
			"error": "missing_pack_path"
		}
	tt_node.mount_ttpkg_file(pack_path)
	if not ProjectSettings.load_resource_pack(pack_path):
		return {
			"ok": false,
			"name": name,
			"loaded": false,
			"error": "resource_pack_load_failed"
		}

	_loaded_subpackages[name] = true
	return {
		"ok": true,
		"name": name,
		"loaded": true,
		"error": ""
	}

func report_scene(scene_id: Variant, dimension: Dictionary = {}, metric: Dictionary = {}, cost_time: Variant = null) -> Dictionary:
	var tt_node = _get_tt_node()
	var task = tt_node.report_scene_async()
	task.scene_id = scene_id
	task.dimension = dimension.duplicate(true)
	task.metric = metric.duplicate(true)
	if cost_time != null:
		task.cost_time = cost_time
	await task.invoke()
	if task.is_success:
		return {
			"ok": true,
			"scene_id": scene_id,
			"dimension": dimension.duplicate(true),
			"metric": metric.duplicate(true),
			"cost_time": cost_time,
			"error": ""
		}
	return {
		"ok": false,
		"scene_id": scene_id,
		"error": String(task.get_result_fail().err_msg)
	}

func run_platform_api_probe(options: Dictionary = {}) -> Dictionary:
	var results: Dictionary = {}
	if _probe_requested(options, "launch_context"):
		results["launch_context"] = _probe_ok(get_launch_context())
	if _probe_requested(options, "ui_insets"):
		results["ui_insets"] = _probe_ok(get_ui_insets())
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
	if _probe_requested(options, "report_scene"):
		var report_scene_raw := _probe_option_string(options, "report_scene_id", "")
		if report_scene_raw.is_empty() or not report_scene_raw.is_valid_int():
			results["report_scene"] = _probe_skip("report_scene_id_missing")
		else:
			var report_scene_result: Dictionary = await report_scene(int(report_scene_raw), {
				"probe": true
			}, {
				"timestamp_unix": Time.get_unix_time_from_system()
			}, 0)
			results["report_scene"] = _probe_ok(report_scene_result) if VariantTruthScript.as_bool(report_scene_result.get("ok", false)) else _probe_fail(String(report_scene_result.get("error", "report_scene_failed")), report_scene_result)
	if _probe_requested(options, "share"):
		if not _probe_option_bool(options, "allow_ui", false):
			results["share"] = _probe_skip("ui_not_allowed")
		else:
			var share_ok: bool = await share({
				"title": "Platform API Probe",
				"query": _probe_option_string(options, "share_query", "platform_api_probe=1")
			})
			results["share"] = _probe_ok({
				"configured": share_ok
			}) if share_ok else _probe_fail("share_failed")
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
	if _probe_requested(options, "interstitial"):
		if not _probe_option_bool(options, "allow_ui", false):
			results["interstitial"] = _probe_skip("ui_not_allowed")
		elif _get_interstitial_ad_unit_id().is_empty():
			results["interstitial"] = _probe_skip("interstitial_ad_unit_id_missing")
		else:
			var interstitial_result: Dictionary = await show_interstitial("platform_api_probe")
			results["interstitial"] = _probe_ok(interstitial_result) if VariantTruthScript.as_bool(interstitial_result.get("ok", false)) else _probe_fail(String(interstitial_result.get("error", "interstitial_failed")), interstitial_result)

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
		"bridge": "tt"
	})

func _connect_lifecycle() -> void:
	if _lifecycle_connected:
		return
	var tt_node = _get_tt_node()
	tt_node.on_show.connect(_handle_app_show)
	tt_node.on_hide.connect(_handle_app_hide)
	_lifecycle_connected = true

func _handle_app_show(params: TT.OnShowArg) -> void:
	_launch_context = _build_launch_context(params, false)
	_refresh_ui_insets()
	emit_signal("app_show", get_launch_context())

func _handle_app_hide() -> void:
	emit_signal("app_hide")

func _build_launch_context(source: Variant, is_cold_start: bool) -> Dictionary:
	var scene := ""
	var query: Dictionary = {}
	var sub_scene := ""
	var share_ticket := ""
	var show_from: Variant = null
	var launch_from := ""
	var location := ""
	var referer_info: Dictionary = {}

	if source is TT.GetLaunchOptionsSyncResult:
		var launch_options: TT.GetLaunchOptionsSyncResult = source
		scene = String(launch_options.scene)
		if launch_options.query != null:
			query = launch_options.query.duplicate(true)
	elif source is TT.OnShowArg:
		var show_params: TT.OnShowArg = source
		scene = String(show_params.scene)
		if show_params.query != null:
			query = show_params.query.duplicate(true)
		sub_scene = String(show_params.sub_scene)
		share_ticket = String(show_params.share_ticket)
		show_from = show_params.show_from
		launch_from = String(show_params.launch_from)
		location = String(show_params.location)
		if show_params.referer_info != null:
			referer_info = {
				"app_id": String(show_params.referer_info.app_id),
				"extra_data": show_params.referer_info.extra_data.duplicate(true) if show_params.referer_info.extra_data != null else {}
			}

	var scene_tail := scene.substr(maxi(0, scene.length() - 4), min(4, scene.length()))

	return {
		"scene": scene,
		"scene_id": int(scene_tail) if scene_tail.is_valid_int() else 0,
		"scene_tail": scene_tail,
		"sub_scene": sub_scene,
		"query": query,
		"referer_info": referer_info,
		"share_ticket": share_ticket,
		"show_from": show_from,
		"launch_from": launch_from,
		"location": location,
		"is_sidebar_entry": SIDEBAR_SCENES.has(scene_tail),
		"is_cold_start": is_cold_start,
		"platform": get_platform_name()
	}

func _refresh_ui_insets() -> void:
	if not is_inside_tree():
		return

	var tt_node = _get_tt_node()
	var system_info: TT.SystemInfo = tt_node.get_system_info_sync()
	var safe_area = system_info.safe_area
	var menu_layout: TT.MenuButtonLayout = tt_node.get_menu_button_layout()
	var viewport_size := get_viewport().get_visible_rect().size
	var reference_width := maxf(1.0, float(system_info.window_width if system_info.window_width != null else system_info.screen_width))
	var reference_height := maxf(1.0, float(system_info.window_height if system_info.window_height != null else system_info.screen_height))
	_input_reference_size = Vector2(
		reference_width,
		reference_height
	)
	if safe_area == null:
		_ui_insets = DEFAULT_INSETS.duplicate(true)
		return
	var screen_width := maxf(1.0, _input_reference_size.x)
	var screen_height := maxf(1.0, _input_reference_size.y)
	var scale_x := viewport_size.x / screen_width
	var scale_y := viewport_size.y / screen_height

	var right_safe := maxf(
		screen_width - float(safe_area.right),
		screen_width - float(menu_layout.left if menu_layout != null and menu_layout.left != null and float(menu_layout.left) >= 0.0 and float(menu_layout.left) <= screen_width else safe_area.right)
	)
	var top_safe := maxf(
		float(safe_area.top),
		float(menu_layout.bottom if menu_layout != null and menu_layout.bottom != null and float(menu_layout.bottom) >= 0.0 and float(menu_layout.bottom) <= screen_height else safe_area.top)
	)

	_ui_insets = {
		"left": float(safe_area.left) * scale_x,
		"top": top_safe * scale_y,
		"right": right_safe * scale_x,
		"bottom": (screen_height - float(safe_area.bottom)) * scale_y
	}

func _get_rewarded_ad(ad_unit_id: String) -> RewardedVideoAd:
	if _rewarded_ads.has(ad_unit_id):
		var existing: RewardedVideoAd = _rewarded_ads[ad_unit_id]
		if is_instance_valid(existing):
			return existing
	var tt_node = _get_tt_node()
	var created: RewardedVideoAd = tt_node.create_rewarded_video_ad({
		"adUnitId": ad_unit_id
	})
	_rewarded_ads[ad_unit_id] = created
	return created

func _get_rewarded_ad_unit_id(placement: String) -> String:
	if placement == "revive" and ProjectSettings.has_setting("douyin/rewarded_revive_ad_unit_id"):
		return String(ProjectSettings.get_setting("douyin/rewarded_revive_ad_unit_id"))
	return ""

func _get_interstitial_ad_unit_id() -> String:
	if ProjectSettings.has_setting("douyin/interstitial_level_end_ad_unit_id"):
		return String(ProjectSettings.get_setting("douyin/interstitial_level_end_ad_unit_id"))
	return ""

func _is_tt_runtime() -> bool:
	var tt_node = _get_tt_node()
	if tt_node != null and tt_node.is_run_in_tt():
		return true
	return OS.has_feature("douyin_minigame") or OS.has_feature("tt")

func _get_tt_node():
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root.get_node_or_null("tt")
	return null

func _get_runtime_probe_bridge():
	if OS.get_name() != "Web":
		return null
	return JavaScriptBridge.get_interface("godotMinigameProbe")

func _call_runtime_probe(plan: Dictionary, fallback: Dictionary) -> Dictionary:
	var bridge = _get_runtime_probe_bridge()
	if bridge == null:
		return fallback.duplicate(true)
	var waiter = PlatformAsyncResultScript.new()
	var callback_holder: Dictionary = {}
	var callback = JavaScriptBridge.create_callback(func(callback_args: Array) -> void:
		_release_probe_callback(callback_holder.get("value"))
		waiter.finish(_parse_probe_callback_dict(callback_args, fallback))
	)
	callback_holder["value"] = callback
	_active_callbacks.append(callback)
	bridge.runProbeJson(JSON.stringify(plan), callback)
	return await waiter.resolved

func _release_probe_callback(callback) -> void:
	_active_callbacks.erase(callback)

func _parse_probe_callback_dict(args: Array, fallback: Dictionary = {}) -> Dictionary:
	if args.is_empty():
		return fallback.duplicate(true)
	var raw: Variant = args[0]
	if typeof(raw) == TYPE_DICTIONARY:
		return (raw as Dictionary).duplicate(true)
	if raw == null:
		return fallback.duplicate(true)
	var parsed: Variant = JSON.parse_string(String(raw))
	if typeof(parsed) == TYPE_DICTIONARY:
		return (parsed as Dictionary).duplicate(true)
	return fallback.duplicate(true)

func _build_runtime_probe_plan(options: Dictionary) -> Dictionary:
	var plan := {
		"timeout_ms": _probe_option_int(options, "timeout_ms", 1500),
		"request_url": _probe_option_string(options, "request_url", ""),
		"socket_url": _probe_option_string(options, "socket_url", ""),
		"allow_ui": _probe_option_bool(options, "allow_ui", false),
		"storage_key": "__godot_platform_api_probe"
	}
	if options.has("calls"):
		plan["calls"] = options.get("calls", [])
	return plan
