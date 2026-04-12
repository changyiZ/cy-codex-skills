extends Node

signal on_feed_status_change(params)
signal on_hide()
signal on_share_app_message(args_0)
signal on_show(game_show_params)

const TTScript := preload("res://addons/ttsdk/api/tt.gd")
const VariantTruthScript := preload("res://scripts/core/VariantTruth.gd")

var _impl: TT = null
var _is_tt_runtime := false

func _ready() -> void:
	_ensure_impl()

func is_run_in_tt() -> bool:
	_ensure_impl()
	return _is_tt_runtime

func get_launch_options_sync() -> Variant:
	return _call_impl("get_launch_options_sync")

func get_system_info_sync() -> Variant:
	return _call_impl("get_system_info_sync")

func get_menu_button_layout() -> Variant:
	return _call_impl("get_menu_button_layout")

func create_rewarded_video_ad(params: Dictionary) -> Variant:
	return _call_impl("create_rewarded_video_ad", [params])

func create_interstitial_ad(params: Dictionary) -> Variant:
	return _call_impl("create_interstitial_ad", [params])

func share_app_message_async() -> Variant:
	return _call_impl("share_app_message_async")

func login_async() -> Variant:
	return _call_impl("login_async")

func load_subpackage_async() -> Variant:
	return _call_impl("load_subpackage_async")

func mount_ttpkg_file(path: String) -> void:
	_call_impl("mount_ttpkg_file", [path])

func report_scene_async() -> Variant:
	return _call_impl("report_scene_async")

func report_analytics(event: String, data: Dictionary) -> void:
	_call_impl("report_analytics", [event, data])

func _call_impl(method_name: String, args: Array = []) -> Variant:
	_ensure_impl()
	if _impl == null:
		return null
	return _impl.callv(method_name, args)

func _ensure_impl() -> void:
	if _impl != null:
		return
	_is_tt_runtime = _detect_tt_runtime()
	if not _is_tt_runtime:
		return
	_impl = TTScript.new()
	_impl.name = "TTImpl"
	add_child(_impl)
	_impl.on_feed_status_change.connect(func (params) -> void:
		emit_signal("on_feed_status_change", params)
	)
	_impl.on_hide.connect(func () -> void:
		emit_signal("on_hide")
	)
	_impl.on_share_app_message.connect(func (args_0) -> void:
		emit_signal("on_share_app_message", args_0)
	)
	_impl.on_show.connect(func (game_show_params) -> void:
		emit_signal("on_show", game_show_params)
	)

func _detect_tt_runtime() -> bool:
	return OS.has_feature("douyin_minigame") or OS.has_feature("tt")
