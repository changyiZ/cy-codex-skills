extends RefCounted

class ExportFile extends RefCounted:
	func is_ignore_exist() -> bool:
		return false

	func get_file_name() -> String:
		return ""

	func get_exist_file_error() -> String:
		return ""

	func read_exist(fa: FileAccess) -> Error:
		return Error.OK

	func write(fa: FileAccess, config, report) -> void:
		pass

class TTProjectConfigFile extends ExportFile:
	var data := {}
	func is_ignore_exist()->bool:
		return false;
	func read_exist(fa: FileAccess) -> Error:
		var text := fa.get_as_text()
		var json := JSON.new()
		var err := json.parse(text)
		if err != Error.OK:
			printerr(json.get_error_message())
			return err
		if typeof(json.data) != TYPE_DICTIONARY:
			return Error.ERR_INVALID_DATA
		var dict : Dictionary = json.data
		for key in dict.keys():
			data.set(key, dict.get(key))
		return Error.OK
		
	func write(fa: FileAccess, config, report) -> void:
		data.set("appid", config.app_id)
		if !data.has("projectname"):
			data.set("projectname", ProjectSettings.get_setting("application/config/name"))
		var pack_options = data.get_or_add("packOptions", {})
		var pack_options_include = pack_options.get_or_add("include", [])
		var pack_options_ignore = pack_options.get_or_add("ignore", [])
		
		var add_pack_option_if_missing = func(arr: Array, type: String, value: String):
			for x in arr:
				if x.get("type") == type && x.get("value") == value:
					return
			arr.push_back({"type": type, "value": value})
		add_pack_option_if_missing.call(pack_options_ignore, "folder", "__MACOSX")
		add_pack_option_if_missing.call(pack_options_ignore, "file", ".gdignore")
		
		var setting = data.get_or_add("setting", {})
		setting.set("urlCheck", false if config.debug_on else true)
		
		var engine_info = data.get_or_add("engineInfos", [])
		var add_engine_info_if_missing = func(arr: Array, name: String, version: String):
			for x in arr:
				if x.get("name") == name:
					x.set("version", version)
					return
			arr.push_back({"name": name, "version": version})
		var vi = Engine.get_version_info()
		add_engine_info_if_missing.call(engine_info, "godot", "%d.%d.%d" % [vi.major, vi.minor, vi.patch])
		fa.store_string(JSON.stringify(data, "  "))
		
	func get_file_name() -> String:
		return "project.config.json"

class TTGameJsonFile extends ExportFile:
	var subpackages: Array
	func is_ignore_exist() -> bool:
		return false
		
	func read_exist(fa: FileAccess) -> Error:
		var text := fa.get_as_text()
		var json := JSON.new()
		var err := json.parse(text)
		if err != Error.OK:
			printerr(json.get_error_message())
			return err
		if typeof(json.data) != TYPE_DICTIONARY:
			return Error.ERR_INVALID_DATA
		if typeof(json.data.get("subpackages")) == TYPE_ARRAY:
			if subpackages == null:
				subpackages = json.data["subpackages"].duplicate()
			else:
				for x in json.data["subpackages"]:
					if x.has('name') && x.has('root'):
						add_subpackage_if_missing(x['name'], x['root'])
		return Error.OK
	func add_subpackage_if_missing(name: String, root: String) -> void:
		if subpackages == null:
			subpackages = [{"name": name, "root": root}]
		else:
			for x in subpackages:
				if x.get("name") == name && x.get("root") == root:
					return
			subpackages.push_back({"name": name, "root": root})
	func remove_subpackage_if_exists(name: String, root: String) -> void:
		if subpackages == null:
			return
		for i in subpackages.size():
			if subpackages[i].get("name") == name && subpackages[i].get("root") == root:
				subpackages.remove_at(i)
				i = i - 1;
	func write(fa: FileAccess, config, report) -> void:
		if config.subpackage_on:
			add_subpackage_if_missing(config.subpackage_info.name, config.subpackage_info.root)
		else:
			remove_subpackage_if_exists(config.subpackage_info.name, config.subpackage_info.root)
		var dict = {
			"deviceOrientation": "portrait" if config.device_orientation == 0 else "landscape",
			"menuButtonStyle": "dark",
			"enableWebGL2": true,
			"enableIOSHighPerformanceMode" : true,
			"enableIOSHighPerformanceModePlus" : false,
			"subpackages": subpackages if subpackages != null else [],
			"plugins": { 
				"GodotPlugin" : { 
					"version": config.godot_plugin_info.version, 
					"provider": config.godot_plugin_info.provider_id
				}
			}
		}
		fa.store_string(JSON.stringify(dict, "  "))
		
	func get_file_name() -> String:
		return "game.json"


class TTGameJsFile extends ExportFile:
	func is_ignore_exist() -> bool:
		return true
	func write(fa: FileAccess, config, report) -> void:
		fa.store_string("""
function createCanvas() {
	const systemInfo = tt.getSystemInfoSync();
	const canvas = tt.createCanvas();
    canvas.width = systemInfo.screenWidth * systemInfo.pixelRatio;
    canvas.height = systemInfo.screenHeight * systemInfo.pixelRatio;
	return canvas;
}

function loadLauncher() {
	const systemInfo = tt.getSystemInfoSync();
	console.log("systemInfo.SDKVersion", systemInfo.SDKVersion)
	if (systemInfo.SDKVersion < "3.95.0") {
		console.warn("using embed godot launcher.")
		return require("./godot.launcher.js")
	} else {
		return requirePlugin("GodotPlugin/index.js");
	}
}

function main() {
	const launcher = loadLauncher();

	launcher.start({
		canvas: createCanvas(),
		config: require('./godot.config.js')
	});
}

main();

/* keep this lines
tt.navigateToScene
*/

""")

	func get_file_name() -> String:
		return "game.js"

class GameConfigFile extends ExportFile:
	func is_ignore_exist() -> bool:
		return true
	func write(fa: FileAccess, config, report) -> void:
		fa.store_string("""
module.exports = {
	mainPack: {mainPack},
    executable: 'godot/godot',
	canvasResizePolicy: {canvasResizePolicy},
	args: [{args}],
	experimentalVK: false,
	emscriptenPoolSize: 0,
	godotPoolSize: 0,
	
	mainWasm: {mainWasm},
	godotModule: 'godot/godot.js',
	godotVersion: {godotVersion},
	subpackages: [{subpackages}],
	forceTTAudioContext: {forceTTAudioContext}
}		
""".format({
	"mainPack": "'" + report.pack_file_relative + "'",
	"mainWasm": "'" + report.wasm_file_relative + "'",
	"canvasResizePolicy": str(config.canvas_resize_policy),
	"args": _get_args_str(config),
	"godotVersion": _get_engine_version_str(),
	"subpackages": _get_subpackages_str(config),
	"forceTTAudioContext": "true" if config.force_tt_audio_context else "false"
}) );
	
	func get_file_name() -> String:
		return "godot.config.js"
	func _get_subpackages_str(config) -> String:
		return "'%s'" % config.subpackage_info.name if config.subpackage_on else ""
	func _get_engine_version_str() -> String:
		var version_info = Engine.get_version_info()
		return "'%d.%d.%d'" % [version_info.major, version_info.minor, version_info.patch]
	func _get_args_str(config) -> String:
		var ret = ""
		if config.debug_on && config.remote_debugger_on:
			ret = ret + "'--remote-debug'"
			ret = ret + ", " + "'" + config.remote_debugger_url + "'"
		return ret
