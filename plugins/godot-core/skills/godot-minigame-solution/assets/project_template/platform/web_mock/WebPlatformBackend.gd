extends "res://platform/PlatformBackend.gd"
class_name WebPlatformBackend

const VariantTruthScript := preload("res://scripts/core/VariantTruth.gd")

func initialize() -> void:
	_refresh_default_save_warning()
	_launch_context = _build_web_launch_context()
	_ui_insets = DEFAULT_INSETS.duplicate(true)

func _build_web_launch_context() -> Dictionary:
	var query: Dictionary = {}
	var scene := ""
	var scene_id := 0
	var scene_tail := ""
	var sub_scene := ""
	var launch_from := ""
	var location := ""
	var share_ticket := ""
	var is_sidebar_entry := false
	var referer_info: Dictionary = {}
	var runtime_json := _read_runtime_json()
	if not runtime_json.is_empty():
		var parsed: Variant = JSON.parse_string(runtime_json)
		if typeof(parsed) == TYPE_DICTIONARY:
			var runtime: Dictionary = parsed
			if typeof(runtime.get("query", {})) == TYPE_DICTIONARY:
				query = (runtime.get("query", {}) as Dictionary).duplicate(true)
			scene = String(query.get("scene", runtime.get("scene", "")))
			sub_scene = String(query.get("sub_scene", runtime.get("sub_scene", "")))
			launch_from = String(query.get("launch_from", runtime.get("launch_from", "")))
			location = String(query.get("location", runtime.get("location", "")))
			share_ticket = String(query.get("share_ticket", runtime.get("share_ticket", "")))
			if typeof(runtime.get("referer_info", {})) == TYPE_DICTIONARY:
				referer_info = (runtime.get("referer_info", {}) as Dictionary).duplicate(true)
			if typeof(runtime.get("is_sidebar_entry", false)) == TYPE_BOOL:
				is_sidebar_entry = VariantTruthScript.as_bool(runtime.get("is_sidebar_entry", false))

	if scene.is_empty():
		scene = String(query.get("scene", ""))
	scene_tail = scene.substr(maxi(0, scene.length() - 4), min(4, scene.length()))
	if scene_tail.is_valid_int():
		scene_id = int(scene_tail)

	return {
		"scene": scene,
		"scene_id": scene_id,
		"scene_tail": scene_tail,
		"sub_scene": sub_scene,
		"query": query,
		"referer_info": referer_info,
		"share_ticket": share_ticket,
		"show_from": query.get("show_from", null),
		"launch_from": launch_from,
		"location": location,
		"is_sidebar_entry": is_sidebar_entry,
		"is_cold_start": true,
		"platform": get_platform_name()
	}

func _read_runtime_json() -> String:
	if OS.get_name() != "Web":
		return ""
	var runtime_marker = JavaScriptBridge.get_interface("godotMinigameRuntime")
	if runtime_marker == null:
		return ""
	var raw: Variant = runtime_marker.getRuntimeJson()
	return "" if raw == null else String(raw)

func show_rewarded_ad(placement: String) -> Dictionary:
	return {
		"ok": true,
		"completed": true,
		"error": "",
		"mock": true,
		"placement": placement
	}

func show_interstitial(placement: String) -> Dictionary:
	return {
		"ok": true,
		"completed": true,
		"error": "",
		"mock": true,
		"placement": placement
	}

func get_platform_name() -> String:
	return "web_mock"
