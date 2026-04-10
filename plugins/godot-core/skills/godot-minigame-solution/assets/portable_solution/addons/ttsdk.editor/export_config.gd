extends RefCounted

const GODOT_PLUGIN_ID = "tte22494997d29862c12"
const GODOT_PLUGIN_VERSION = "1.0.0"

var app_id: String = ""

var brotli_on: bool = false
var brotli_policy: int = 0 # 0: Auto, 1: Fast, 2: Size
var canvas_resize_policy: int = 0
var subpackage_on: bool = false
var subpackage_info := {
	"name": "godot",
	"root": "godot"
}
var ide_exe: String = ""
var custom_game_js: bool = false
var embed_godot_plugin: bool = false

var settings_debug_id = "0"
var device_orientation = 0 # 0: portrait, 1: landscape
var debug_on: bool = true
var remote_debugger_on: bool = false
var remote_debugger_url: String = ""

var force_tt_audio_context: bool = true

var godot_plugin_info: GodotPluginInfo = GodotPluginInfo.new(GODOT_PLUGIN_ID, GODOT_PLUGIN_VERSION)

class GodotPluginInfo:
	var provider_id: String
	var version: String
	func _init(id: String, ver: String) -> void:
		provider_id = id;
		version = ver
