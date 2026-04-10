extends EditorExportPlatformExtension

const ExportConfigScript = preload("res://addons/ttsdk.editor/export_config.gd")
const ExportFilesScript = preload("res://addons/ttsdk.editor/export_files.gd")
const ExportHelperScript = preload("res://addons/ttsdk.editor/export_helper.gd")
const ExportReportScript = preload("res://addons/ttsdk.editor/export_report.gd")
const ExportSettingsScript = preload("res://addons/ttsdk.editor/export_settings.gd")

const OPTIONS_APP_ID := "douyin/app_id"
const OPTIONS_CANVAS_RESIZE_POLICY := "douyin/canvas_resize_policy"
const OPTIONS_DEVICE_ORIENTATION := "douyin/device_device_orientation"
const OPTIONS_SUBPACKAGE_ON := "douyin/subpackage_on"
const OPTIONS_CUSTOM_GAME_JS := "douyin/custom_game_js"
const OPTIONS_DEVELOPER_TOOL := "douyin/douyin_developer_tool"
const OPTIONS_EXTENSIONS_SUPPORT := "douyin/extensions_support"

const OPTIONS_DEBUG_REMOTE_DEBUGGER_ON := "douyin_debug/remote_debugger_on"
const OPTIONS_DEBUG_REMOTE_DEBUGGER_URL := "douyin_debug/remote_debugger_url"
const OPTIONS_DEBUG_SETTINGS_DEBUG_ID := "douyin_debug/settings_debug_id"

const OPTIONS_OPTIMIZE_BROTLI_ON := "douyin_optimize/brotli_on"
const OPTIONS_OPTIMIZE_BROTLI_POLICY := "douyin_optimize/brotli_policy"

const OPTIONS_CUSTOM_TEMPLATE_DEBUG := "douyin_custom_template/debug"
const OPTIONS_CUSTOM_TEMPLATE_RELEASE := "douyin_custom_template/release"

const OPTIONS_EXPRIMENTAL_AUDIO_CONTEXT := "douyin_exeprimental/audio_context"
const HELIUM_MIN_CHROME_VERSION := 93


func _get_name() -> String:
	return "tt-minigame"

func _get_logo() -> Texture2D:
	return load("res://addons/ttsdk.editor/platform-logo.png")

func _get_binary_extensions(preset: EditorExportPreset) -> PackedStringArray:
	return PackedStringArray(["config.json"])

func _has_valid_export_configuration(preset: EditorExportPreset, debug: bool) -> bool:
	if (!preset.get_or_env(OPTIONS_APP_ID, "")):
		set_config_error("app_id is missing.")
		return false;
	return true

func _has_valid_project_configuration(preset: EditorExportPreset) -> bool:
	if !ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc"):
		return false
	return true


func _get_export_option_visibility(preset: EditorExportPreset, option: String) -> bool:
	var advance_options_enabled = preset.are_advanced_options_enabled()
	var advance_options := [
		OPTIONS_CUSTOM_TEMPLATE_DEBUG, 
		OPTIONS_CUSTOM_TEMPLATE_RELEASE, 
		OPTIONS_DEBUG_SETTINGS_DEBUG_ID
	]
	if advance_options.has(option):
		return advance_options_enabled
	var unavailable := [OPTIONS_DEVELOPER_TOOL, OPTIONS_EXTENSIONS_SUPPORT]
	if unavailable.has(option):
		return false
	return true
	
func _get_platform_features() -> PackedStringArray:
	return PackedStringArray(["web", "Web", "tt"])
	
func _get_preset_features(preset: EditorExportPreset) -> PackedStringArray:
	var features = ["astc", "etc2", "nothreads", "wasm32"]
	if preset.get_or_env(OPTIONS_EXTENSIONS_SUPPORT, ""):
		features.push_back("web_extensions")
	else:
		features.push_back("web_noextensions")
	return PackedStringArray(features)
	
func _get_debug_protocol() -> String:
	return "ws://"
	
func _get_export_options() -> Array[Dictionary]:
	return [
		_make_export_option(OPTIONS_APP_ID, Variant.Type.TYPE_STRING, ""),
		_make_export_option(OPTIONS_CANVAS_RESIZE_POLICY, Variant.Type.TYPE_INT, 0, PropertyHint.PROPERTY_HINT_ENUM, "None,Project,Adaptive"),
		_make_export_option(OPTIONS_DEVICE_ORIENTATION, Variant.Type.TYPE_INT, 0, PropertyHint.PROPERTY_HINT_ENUM, "Portrait,Landscape"),
		_make_export_option(OPTIONS_SUBPACKAGE_ON, Variant.Type.TYPE_BOOL, false),
		_make_export_option(OPTIONS_CUSTOM_GAME_JS, Variant.Type.TYPE_BOOL, false),
		_make_export_option(OPTIONS_DEVELOPER_TOOL, Variant.Type.TYPE_STRING, "", PropertyHint.PROPERTY_HINT_GLOBAL_FILE, "*.exe"),
		_make_export_option(OPTIONS_EXTENSIONS_SUPPORT, Variant.Type.TYPE_BOOL, false),
		# --- debug ---
		_make_export_option(OPTIONS_DEBUG_REMOTE_DEBUGGER_ON, Variant.Type.TYPE_BOOL, false),
		_make_export_option(OPTIONS_DEBUG_REMOTE_DEBUGGER_URL, Variant.Type.TYPE_STRING, _get_debugger_url()),
		_make_export_option(OPTIONS_DEBUG_SETTINGS_DEBUG_ID, Variant.Type.TYPE_STRING, ""),
		# --- optimize ---
		_make_export_option(OPTIONS_OPTIMIZE_BROTLI_ON, Variant.Type.TYPE_BOOL, false),
		_make_export_option(OPTIONS_OPTIMIZE_BROTLI_POLICY, Variant.Type.TYPE_INT, 0, PropertyHint.PROPERTY_HINT_ENUM, ExportHelperScript.BROTLI_POLICY_HIT_STRING),
		# --- custom template ---
		_make_export_option(OPTIONS_CUSTOM_TEMPLATE_DEBUG, Variant.Type.TYPE_STRING, "", PropertyHint.PROPERTY_HINT_GLOBAL_FILE, "*.zip"),
		_make_export_option(OPTIONS_CUSTOM_TEMPLATE_RELEASE, Variant.Type.TYPE_STRING, "", PropertyHint.PROPERTY_HINT_GLOBAL_FILE, "*.zip"),
		
		# --- experimental ---
		_make_export_option(OPTIONS_EXPRIMENTAL_AUDIO_CONTEXT, Variant.Type.TYPE_BOOL, true),

	]

func _make_export_option(name: String, type: Variant.Type, default_value: Variant, hint: PropertyHint = PropertyHint.PROPERTY_HINT_NONE, hint_string: String = "") -> Dictionary:
	var dict = {
		"name": name,
		"type": type,
		"default_value": default_value
	}
	if hint:
		dict["hint"] = hint
	if hint_string:
		dict["hint_string"] = hint_string
	return dict

func _get_debugger_url() -> String:
	var editor_settings = EditorInterface.get_editor_settings()
	var host = editor_settings.get_setting("network/debug/remote_host")
	var port = editor_settings.get_setting("network/debug/remote_port")
	return _get_debug_protocol() + host + ":" + str(port)
	
func _extract_config_from_preset(preset: EditorExportPreset, debug: bool):
	var config = ExportConfigScript.new()
	config.app_id = preset.get_or_env(OPTIONS_APP_ID, "")
	config.debug_on = debug
	config.canvas_resize_policy = preset.get_or_env(OPTIONS_CANVAS_RESIZE_POLICY, "")
	config.device_orientation = preset.get_or_env(OPTIONS_DEVICE_ORIENTATION, "") as int
	config.subpackage_on = preset.get_or_env(OPTIONS_SUBPACKAGE_ON, "")
	config.custom_game_js = preset.get_or_env(OPTIONS_CUSTOM_GAME_JS, "")
	if debug:
		config.remote_debugger_on = preset.get_or_env(OPTIONS_DEBUG_REMOTE_DEBUGGER_ON, "") as bool
		if config.remote_debugger_on:
			config.remote_debugger_url = preset.get_or_env(OPTIONS_DEBUG_REMOTE_DEBUGGER_URL, "")
			if !config.remote_debugger_url:
				config.remote_debugger_url = _get_debugger_url()
	config.brotli_on = preset.get_or_env(OPTIONS_OPTIMIZE_BROTLI_ON, "") as bool
	config.brotli_policy = preset.get_or_env(OPTIONS_OPTIMIZE_BROTLI_POLICY, "") as int
	config.force_tt_audio_context = preset.get_or_env(OPTIONS_EXPRIMENTAL_AUDIO_CONTEXT, "") as bool
	if preset.are_advanced_options_enabled():
		var settings_debug_id = preset.get_or_env(OPTIONS_DEBUG_SETTINGS_DEBUG_ID, "")
		if settings_debug_id:
			config.settings_debug_id = settings_debug_id
	#config.ide_exe = preset.get_or_env("douyin/douyin_developer_tool", "")
	return config;
func _export_pack_patch(preset: EditorExportPreset, debug: bool, path: String, patches: PackedStringArray, flags: int) -> Error:
	return Error.ERR_UNAVAILABLE
func _export_zip_patch(preset: EditorExportPreset, debug: bool, path: String, patches: PackedStringArray, flags: int) -> Error:
	return Error.ERR_UNAVAILABLE
func _export_zip(preset: EditorExportPreset, debug: bool, path: String, flags: int) -> Error:
	return Error.ERR_UNAVAILABLE
func _export_pack(preset: EditorExportPreset, debug: bool, path: String, flags: int) -> Error:
	print("export pack: " + path)
	if !path.ends_with(".pck"):
		return Error.ERR_FILE_BAD_PATH
	
	var base_dir = path.get_base_dir()
	var base_dir_access = DirAccess.open(base_dir)
	
	var res = save_pack(preset, debug, path);
	for so in res.so_files:
		print("so_files: " + so.path + " [" + str(so.tags) + "] " + so.target_folder)
	if res.result != Error.OK:
		return res.result
	
	base_dir_access.rename(path, path.substr(0, path.length() - 4) + ".bin"); # TT IDE 不支持 .pck 文件 	

	return Error.OK


func _get_export_dir_safe(path: String) -> String:
	var export_dir = ProjectSettings.globalize_path(path).get_base_dir().simplify_path()
	if export_dir == "." || export_dir == ProjectSettings.globalize_path("res://"):
		export_dir = "tt-minigame"
	if !DirAccess.dir_exists_absolute(export_dir):
		DirAccess.make_dir_recursive_absolute(export_dir)
	return export_dir
	

func _export_project(preset: EditorExportPreset, debug: bool, path: String, flags: int) -> Error:
	var base_dir = _get_export_dir_safe(path)
	print("export project to: " + base_dir)
	
	var base_dir_access = DirAccess.open(base_dir)
	if !base_dir_access.dir_exists("godot"):
		base_dir_access.make_dir("godot")
	
	var config = _extract_config_from_preset(preset, debug)
	var report = ExportReportScript.new()
	report.project_dir = base_dir
	
	var err = ExportSettingsScript.fetch_remote_config(config.settings_debug_id)
	if err != OK:
		printerr("check network and try again.")
		return err
	var remote_config = ExportSettingsScript.get_remote_config()
	if remote_config.plugin_download_enabled:
		err = ExportSettingsScript.download_file(remote_config.plugin_download_url, base_dir.path_join("godot.launcher.js"))
		if err != OK:
			printerr("failed to download godot launcher, url = " + str(remote_config.plugin_download_url))
			return err
		config.embed_godot_plugin = true
	else:
		config.embed_godot_plugin = false
		if base_dir_access.file_exists("godot.launcher.js"):
			base_dir_access.remove("godot.launcher.js")
	if !remote_config.plugin_version.is_empty():
		config.godot_plugin_info.version = remote_config.plugin_version
	if FileAccess.file_exists(base_dir.path_join("godot.launcher.js")):
		_patch_launcher_compat(base_dir.path_join("godot.launcher.js"))
	
	err = ExportHelperScript.export_pack(self, preset, debug, base_dir.path_join("godot/main.pck"), config.brotli_on, config.brotli_policy, report)
	if err != Error.OK:
		printerr('failed to export pack.')
		return err
		
	var template_file_path = _get_template_file_path(preset, debug)
	if !template_file_path || !FileAccess.file_exists(template_file_path):
		printerr('template file not found')
		return Error.ERR_FILE_NOT_FOUND
	print('using template: ' + template_file_path)
	var zip_reader = ZIPReader.new()
	zip_reader.open(template_file_path)
	var wasm_file_name := ""
	if zip_reader.file_exists("godot.wasm.br"):
		wasm_file_name = "godot.wasm.br"
	elif zip_reader.file_exists("godot.wasm"):
		wasm_file_name = "godot.wasm"
	else:
		printerr("file not found in template: godot.wasm(.br)")
		return Error.ERR_DOES_NOT_EXIST
	for file_name in ["godot.js", wasm_file_name]:
		if !zip_reader.file_exists(file_name):
			printerr("file not found in template: " + file_name)
			return Error.ERR_DOES_NOT_EXIST
		var fa = FileAccess.open(base_dir.path_join("godot").path_join(file_name), FileAccess.WRITE)
		fa.store_buffer(zip_reader.read_file(file_name))
		fa.close()
		if file_name == "godot.js":
			_patch_runtime_compat(base_dir.path_join("godot").path_join(file_name))
	var stale_wasm_name := "godot.wasm" if wasm_file_name == "godot.wasm.br" else "godot.wasm.br"
	var stale_wasm_path := base_dir.path_join("godot").path_join(stale_wasm_name)
	if FileAccess.file_exists(stale_wasm_path):
		DirAccess.remove_absolute(stale_wasm_path)

	zip_reader.close();
	report.wasm_file = base_dir.path_join("godot").path_join(wasm_file_name)
	_maybe_compress_wasm(config, report)
	
	if config.subpackage_on:
		if !base_dir_access.file_exists("godot/game.js"):
			FileAccess.open(base_dir.path_join("godot/game.js"), FileAccess.WRITE).close()
	else:
		if base_dir_access.file_exists("godot/game.js"):
			base_dir_access.remove("godot/game.js")
			
	var files: Array = [
		ExportFilesScript.TTGameJsFile.new(),
		ExportFilesScript.TTGameJsonFile.new(),
		ExportFilesScript.TTProjectConfigFile.new(),
		ExportFilesScript.GameConfigFile.new()
	]
	for file in files:
		var file_path = base_dir.path_join(file.get_file_name());
		if FileAccess.file_exists(file_path) && !file.is_ignore_exist():
			var file_access_read = FileAccess.open(file_path, FileAccess.READ)
			file.read_exist(file_access_read)
			file_access_read.close()
		if file.get_file_name() == "game.js":
			if FileAccess.file_exists(file_path) && config.custom_game_js:
				continue
		var file_access_write = FileAccess.open(file_path, FileAccess.WRITE)
		file.write(file_access_write, config, report)
		file_access_write.close()

	var entry_game_js_path := base_dir.path_join("game.js")
	if FileAccess.file_exists(entry_game_js_path):
		_patch_entry_canvas_metrics(entry_game_js_path)
		
	FileAccess.open(base_dir.path_join('.gdignore'), FileAccess.WRITE).close();
	
	return Error.OK

func _get_template_file_path(preset: EditorExportPreset, debug: bool) -> String:
	var file_path := ProjectSettings.globalize_path("./addons/ttsdk.editor/templates").path_join("web_debug.zip" if debug else "web_release.zip")
	if preset.are_advanced_options_enabled():
		var custom_file_path = preset.get_or_env(OPTIONS_CUSTOM_TEMPLATE_DEBUG, "") if debug else preset.get_or_env(OPTIONS_CUSTOM_TEMPLATE_RELEASE, "")
		if custom_file_path:
			file_path = custom_file_path
	file_path = _resolve_nothreads_template_variant(file_path, debug)
	return file_path


func _resolve_nothreads_template_variant(file_path: String, debug: bool) -> String:
	var file_name := file_path.get_file()
	if file_name.begins_with("web_nothreads_"):
		return file_path
	var expected_name := "web_nothreads_debug.zip" if debug else "web_nothreads_release.zip"
	if file_name == ("web_debug.zip" if debug else "web_release.zip"):
		var candidate := file_path.get_base_dir().path_join(expected_name)
		if FileAccess.file_exists(candidate):
			return candidate
	return file_path


func _maybe_compress_wasm(config, report) -> void:
	if !config.brotli_on:
		return
	if report.wasm_file.is_empty() or !report.wasm_file.ends_with(".wasm"):
		return
	if !FileAccess.file_exists(report.wasm_file):
		return
	var wasm_br_path = report.wasm_file + ".br"
	if FileAccess.file_exists(wasm_br_path):
		DirAccess.remove_absolute(wasm_br_path)
	var brotli_policy = config.brotli_policy
	if brotli_policy == ExportHelperScript.BROTLI_POLICY.AUTO:
		brotli_policy = ExportHelperScript.BROTLI_POLICY.FAST if config.debug_on else ExportHelperScript.BROTLI_POLICY.SIZE
	Brotli.compress_file(report.wasm_file, wasm_br_path, 5 if brotli_policy == ExportHelperScript.BROTLI_POLICY.FAST else 9)
	DirAccess.remove_absolute(report.wasm_file)
	report.wasm_file = wasm_br_path


func _patch_runtime_compat(godot_js_path: String) -> void:
	var source := FileAccess.get_file_as_string(godot_js_path)
	if source.is_empty():
		return
	var old_preloader_const := "const preloader = new Preloader();"
	var new_preloader_mutable := "let preloader = new Preloader();"
	if source.contains(old_preloader_const):
		source = source.replace(old_preloader_const, new_preloader_mutable)
	var old_guard := "if(currentChromeVersion<95){throw new Error(`This emscripten-generated code requires Chrome v95 (detected v${currentChromeVersion})`)}"
	var new_guard := "if(currentChromeVersion<%d){throw new Error(`This emscripten-generated code requires Chrome v%d (detected v${currentChromeVersion})`)}" % [HELIUM_MIN_CHROME_VERSION, HELIUM_MIN_CHROME_VERSION]
	if source.contains(old_guard):
		source = source.replace(old_guard, new_guard)
	var old_engine_ctor := "function Engine(initConfig) { // eslint-disable-line no-shadow\n\t\tthis.config = new InternalConfig(initConfig);\n\t\tthis.rtenv = null;\n\t}"
	var new_engine_ctor := "function Engine(initConfig) { // eslint-disable-line no-shadow\n\t\tthis.config = new InternalConfig(initConfig);\n\t\tthis.rtenv = null;\n\t\tif (initConfig.preloaderOverride) {\n\t\t\tpreloader = initConfig.preloaderOverride;\n\t\t}\n\t}"
	if source.contains(old_engine_ctor) and !source.contains("if (initConfig.preloaderOverride)"):
		source = source.replace(old_engine_ctor, new_engine_ctor)
	var old_engine_load := "Engine.load = function (basePath, size) {\n\t\tif (loadPromise == null) {\n\t\t\tloadPath = basePath;\n\t\t\tloadPromise = preloader.loadPromise(`${loadPath}.wasm`, size, true);\n\t\t\trequestAnimationFrame(preloader.animateProgress);\n\t\t}\n\t\treturn loadPromise;\n\t};"
	var new_engine_load := "Engine.load = function (basePath, size, mainWasm) {\n\t\tif (loadPromise == null) {\n\t\t\tloadPath = basePath;\n\t\t\tloadPromise = preloader.loadPromise(mainWasm ?? `${loadPath}.wasm`, size, true);\n\t\t\trequestAnimationFrame(preloader.animateProgress);\n\t\t}\n\t\treturn loadPromise;\n\t};"
	if source.contains(old_engine_load):
		source = source.replace(old_engine_load, new_engine_load)
	var old_init_call := "Engine.load(basePath, this.config.fileSizes[`${basePath}.wasm`]);"
	var new_init_call := "Engine.load(basePath, this.config.fileSizes[this.config.mainWasm ?? `${basePath}.wasm`] ?? this.config.fileSizes[`${basePath}.wasm`], this.config.mainWasm);"
	if source.contains(old_init_call):
		source = source.replace(old_init_call, new_init_call)
	var current_init_call := "Engine.load(basePath, this.config.fileSizes[`${basePath}.wasm`], this.config.mainWasm);"
	if source.contains(current_init_call):
		source = source.replace(current_init_call, new_init_call)
	var module_config_anchor := "this.onProgress = parse('onProgress', this.onProgress);\n\n\t\t// Godot config"
	var module_config_patch := "this.onProgress = parse('onProgress', this.onProgress);\n\t\tthis.instantiateWasm = parse('instantiateWasm', this.instantiateWasm);\n\n\t\t// Godot config"
	if source.contains(module_config_anchor) and !source.contains("this.instantiateWasm = parse('instantiateWasm', this.instantiateWasm);"):
		source = source.replace(module_config_anchor, module_config_patch)
	var tt_config_anchor := "this.onExit = parse('onExit', this.onExit);\n\t};"
	var tt_config_patch := "this.onExit = parse('onExit', this.onExit);\n\t\tthis.mainWasm = parse('mainWasm', this.mainWasm);\n\t};"
	if source.contains(tt_config_anchor) and !source.contains("this.mainWasm = parse('mainWasm', this.mainWasm);"):
		source = source.replace(tt_config_anchor, tt_config_patch)
	var old_module_instantiate := "'instantiateWasm': function (imports, onSuccess) {"
	var new_module_instantiate := "'instantiateWasm': this.instantiateWasm ?? function (imports, onSuccess) {"
	if source.contains(old_module_instantiate) and !source.contains("'instantiateWasm': this.instantiateWasm ?? function (imports, onSuccess) {"):
		source = source.replace(old_module_instantiate, new_module_instantiate)
	var old_pthread_pool_default := "var pthreadPoolSize=Module[\"emscriptenPoolSize\"]||8;"
	var new_pthread_pool_default := "var pthreadPoolSize=Module[\"emscriptenPoolSize\"] ?? 8;"
	if source.contains(old_pthread_pool_default):
		source = source.replace(old_pthread_pool_default, new_pthread_pool_default)
	var old_ttfs_mount := "GodotFS._mount_points.forEach(function(path){createRecursive(path);FS.mount(IDBFS,{},path)});"
	var new_ttfs_mount := "var TTFS;if(typeof __tt_emscripten_js_libs!=\"undefined\"){TTFS=__tt_emscripten_js_libs.getTTFS({FS})}GodotFS._mount_points.forEach(function(path){createRecursive(path);if(TTFS){FS.mount(TTFS,{ttPath:\"ttfile://user\"+path},path)}else{FS.mount(IDBFS,{},path)}});"
	if source.contains(old_ttfs_mount) and !source.contains("__tt_emscripten_js_libs.getTTFS({FS})"):
		source = source.replace(old_ttfs_mount, new_ttfs_mount)
	var old_get_now := "var _emscripten_get_now=()=>performance.timeOrigin+performance.now();"
	var new_get_now := "var _emscripten_get_now=()=>performance.now();"
	if source.contains(old_get_now):
		source = source.replace(old_get_now, new_get_now)
	var old_webgl_feature_check := "isWebGLAvailable: function (majorVersion = 1) {\n\t\ttry {\n\t\t\treturn !!document.createElement('canvas').getContext(['webgl', 'webgl2'][majorVersion - 1]);\n\t\t} catch (e) { /* Not available */ }\n\t\treturn false;\n\t},"
	var new_webgl_feature_check := "isWebGLAvailable: function (majorVersion = 1) {\n\t\tconst contextName = ['webgl', 'webgl2'][majorVersion - 1];\n\t\ttry {\n\t\t\tif (typeof GodotConfig !== 'undefined' && GodotConfig.canvas && typeof GodotConfig.canvas.getContext === 'function') {\n\t\t\t\tconst mainCanvasContext = GodotConfig.canvas.getContext(contextName);\n\t\t\t\tif (mainCanvasContext) {\n\t\t\t\t\treturn true;\n\t\t\t\t}\n\t\t\t}\n\t\t\tconst testCanvas = document.createElement('canvas');\n\t\t\treturn !!(testCanvas && typeof testCanvas.getContext === 'function' && testCanvas.getContext(contextName));\n\t\t} catch (e) { /* Not available */ }\n\t\treturn false;\n\t},"
	if source.contains(old_webgl_feature_check):
		source = source.replace(old_webgl_feature_check, new_webgl_feature_check)
	var old_canvas_detection := "if (!(this.canvas instanceof HTMLCanvasElement)) {\n\t\t\tconst nodes = document.getElementsByTagName('canvas');\n\t\t\tif (nodes.length && nodes[0] instanceof HTMLCanvasElement) {\n\t\t\t\tconst first = nodes[0];\n\t\t\t\tthis.canvas = /** @type {!HTMLCanvasElement} */ (first);\n\t\t\t}\n\t\t\tif (!this.canvas) {\n\t\t\t\tthrow new Error('No canvas found in page');\n\t\t\t}\n\t\t}"
	var new_canvas_detection := "const CanvasCtor = typeof HTMLCanvasElement !== 'undefined' ? HTMLCanvasElement : null;\n\t\tconst isCanvasElement = function (node) {\n\t\t\treturn !!node && ((CanvasCtor && node instanceof CanvasCtor) || (typeof node.getContext === 'function' && typeof node.width !== 'undefined' && typeof node.height !== 'undefined'));\n\t\t};\n\t\tif (!isCanvasElement(this.canvas)) {\n\t\t\tconst nodes = document.getElementsByTagName('canvas');\n\t\t\tif (nodes.length && isCanvasElement(nodes[0])) {\n\t\t\t\tconst first = nodes[0];\n\t\t\t\tthis.canvas = /** @type {!HTMLCanvasElement} */ (first);\n\t\t\t}\n\t\t\tif (!this.canvas) {\n\t\t\t\tthrow new Error('No canvas found in page');\n\t\t\t}\n\t\t}"
	if source.contains(old_canvas_detection):
		source = source.replace(old_canvas_detection, new_canvas_detection)
	var old_window_icon_set := "function _godot_js_display_window_icon_set(p_ptr,p_len){let link=document.getElementById(\"-gd-engine-icon\");const old_icon=GodotDisplay.window_icon;if(p_ptr){if(link===null){link=document.createElement(\"link\");link.rel=\"icon\";link.id=\"-gd-engine-icon\";document.head.appendChild(link)}const png=new Blob([GodotRuntime.heapSlice(HEAPU8,p_ptr,p_len)],{type:\"image/png\"});GodotDisplay.window_icon=URL.createObjectURL(png);link.href=GodotDisplay.window_icon}else{if(link){link.remove()}GodotDisplay.window_icon=null}if(old_icon){URL.revokeObjectURL(old_icon)}}"
	var new_window_icon_set := "function _godot_js_display_window_icon_set(p_ptr,p_len){let link=document.getElementById(\"-gd-engine-icon\");const old_icon=GodotDisplay.window_icon;if(p_ptr){if(link===null){link=document.createElement(\"link\");if(!link){return}link.rel=\"icon\";link.id=\"-gd-engine-icon\";if(document.head&&typeof document.head.appendChild===\"function\"){document.head.appendChild(link)}}let object_url=null;try{if(typeof URL!==\"undefined\"&&typeof URL.createObjectURL===\"function\"&&typeof Blob!==\"undefined\"){const png=new Blob([GodotRuntime.heapSlice(HEAPU8,p_ptr,p_len)],{type:\"image/png\"});object_url=URL.createObjectURL(png)}}catch(e){object_url=null}GodotDisplay.window_icon=object_url;if(link&&object_url){link.href=object_url}}else{if(link&&typeof link.remove===\"function\"){link.remove()}GodotDisplay.window_icon=null}if(old_icon&&typeof URL!==\"undefined\"&&typeof URL.revokeObjectURL===\"function\"){try{URL.revokeObjectURL(old_icon)}catch(e){}}}"
	if source.contains(old_window_icon_set):
		source = source.replace(old_window_icon_set, new_window_icon_set)
	var old_js_eval := "_godot_js_eval(p_js,p_use_global_ctx,p_union_ptr,p_byte_arr,p_byte_arr_write,p_callback){const js_code=GodotRuntime.parseString(p_js);let eval_ret=null;try{if(p_use_global_ctx){const global_eval=eval;eval_ret=global_eval(js_code)}else{eval_ret=eval(js_code)}}catch(e){GodotRuntime.error(e)}"
	var new_js_eval := "_godot_js_eval(p_js,p_use_global_ctx,p_union_ptr,p_byte_arr,p_byte_arr_write,p_callback){const js_code=GodotRuntime.parseString(p_js);let eval_ret=null;try{const local_eval=typeof eval===\"function\"?eval:null;const global_eval=typeof globalThis!==\"undefined\"&&typeof globalThis.eval===\"function\"?globalThis.eval:local_eval;const fallback_eval=typeof Function===\"function\"?function(code){return Function(code)()}:null;if(p_use_global_ctx){if(global_eval){eval_ret=global_eval(js_code)}else if(fallback_eval){eval_ret=fallback_eval(js_code)}else{throw new TypeError(\"global eval unavailable\")}}else if(local_eval){eval_ret=local_eval(js_code)}else if(global_eval){eval_ret=global_eval(js_code)}else if(fallback_eval){eval_ret=fallback_eval(js_code)}else{throw new TypeError(\"eval unavailable\")}}catch(e){GodotRuntime.error(e)}"
	if source.contains(old_js_eval):
		source = source.replace(old_js_eval, new_js_eval)
	var old_ime_attach := "GodotConfig.canvas.parentElement.appendChild(ime);GodotIME.ime=ime"
	var new_ime_attach := "var ime_parent=GodotConfig.canvas&&GodotConfig.canvas.parentElement;if(!ime_parent||typeof ime_parent.appendChild!==\"function\"){return}if(typeof Node!=\"undefined\"&&!(ime instanceof Node)){return}try{ime_parent.appendChild(ime)}catch(e){return}GodotIME.ime=ime"
	if source.contains(old_ime_attach):
		source = source.replace(old_ime_attach, new_ime_attach)
	var old_vk_insert := "GodotConfig.canvas.insertAdjacentElement(\"beforebegin\",elem);return elem"
	var new_vk_insert := "var vk_canvas=GodotConfig.canvas;if(!vk_canvas||typeof vk_canvas.insertAdjacentElement!==\"function\"){return elem}if(typeof Element!=\"undefined\"&&!(elem instanceof Element)){return elem}try{vk_canvas.insertAdjacentElement(\"beforebegin\",elem)}catch(e){return elem}return elem"
	if source.contains(old_vk_insert):
		source = source.replace(old_vk_insert, new_vk_insert)
	var engine_export_shim := "if (typeof module != 'undefined') {\n\tmodule.exports = Engine\n\tmodule.exports.default = Engine\n}\n"
	var export_anchor := "if (typeof window !== 'undefined') {\n\twindow['Engine'] = Engine;\n}\n"
	if source.contains(export_anchor) and !source.contains("module.exports = Engine"):
		source = source.replace(export_anchor, export_anchor + engine_export_shim)
	var file_access := FileAccess.open(godot_js_path, FileAccess.WRITE)
	file_access.store_string(source)
	file_access.close()


func _patch_launcher_compat(launcher_js_path: String) -> void:
	var source := FileAccess.get_file_as_string(launcher_js_path)
	if source.is_empty():
		return
	var old_experimental_vk := "experimentalVK:!0"
	var new_experimental_vk := "experimentalVK:!1"
	if source.contains(old_experimental_vk):
		source = source.replace(old_experimental_vk, new_experimental_vk)
	var old_webgl_contexts := "WebGLRenderingContext:{},"
	var new_webgl_contexts := "WebGLRenderingContext:{},WebGL2RenderingContext:{},"
	if source.contains(old_webgl_contexts) and !source.contains("WebGL2RenderingContext:{}"):
		source = source.replace(old_webgl_contexts, new_webgl_contexts)
	var old_screen_size := "screenWidth:e.screenHeight,screenHeight:e.screenHeight"
	var new_screen_size := "screenWidth:e.screenWidth,screenHeight:e.screenHeight"
	if source.contains(old_screen_size):
		source = source.replace(old_screen_size, new_screen_size)
	var old_canvas_client_size := "clientWidth:e.width/window.devicePixelRatio,clientHeight:e.height/window.devicePixelRatio"
	var new_canvas_client_size := "clientWidth:window.innerWidth||e.width,clientHeight:window.innerHeight||e.height"
	if source.contains(old_canvas_client_size):
		source = source.replace(old_canvas_client_size, new_canvas_client_size)
	var old_canvas_rect := "getBoundingClientRect=function(){return{x:0,y:0,left:0,top:0,bottom:e.clientHeight,right:e.clientWidth,width:e.clientWidth,height:e.clientHeight}}"
	var new_canvas_rect := "getBoundingClientRect=function(){const width=window.innerWidth||e.clientWidth||e.width;const height=window.innerHeight||e.clientHeight||e.height;return{x:0,y:0,left:0,top:0,bottom:height,right:width,width:width,height:height}}"
	if source.contains(old_canvas_rect):
		source = source.replace(old_canvas_rect, new_canvas_rect)
	var file_access := FileAccess.open(launcher_js_path, FileAccess.WRITE)
	file_access.store_string(source)
	file_access.close()


func _patch_entry_canvas_metrics(game_js_path: String) -> void:
	var source := FileAccess.get_file_as_string(game_js_path)
	if source.is_empty():
		return
	var old_create_canvas := "function createCanvas() {\n\tconst systemInfo = tt.getSystemInfoSync();\n\tconst canvas = tt.createCanvas();\n    canvas.width = systemInfo.screenWidth * systemInfo.pixelRatio;\n    canvas.height = systemInfo.screenHeight * systemInfo.pixelRatio;\n\treturn canvas;\n}\n"
	var new_create_canvas := "function createCanvas() {\n\tconst systemInfo = tt.getSystemInfoSync();\n\tconst canvas = tt.createCanvas();\n\tconst logicalWidth = systemInfo.windowWidth || systemInfo.screenWidth;\n\tconst logicalHeight = systemInfo.windowHeight || systemInfo.screenHeight;\n    canvas.width = logicalWidth * systemInfo.pixelRatio;\n    canvas.height = logicalHeight * systemInfo.pixelRatio;\n\ttry {\n\t\tconsole.log('[godot-tt] canvas metrics ' + JSON.stringify({\n\t\t\twindowWidth: systemInfo.windowWidth,\n\t\t\twindowHeight: systemInfo.windowHeight,\n\t\t\tscreenWidth: systemInfo.screenWidth,\n\t\t\tscreenHeight: systemInfo.screenHeight,\n\t\t\tpixelRatio: systemInfo.pixelRatio,\n\t\t\tcanvasWidth: canvas.width,\n\t\t\tcanvasHeight: canvas.height\n\t\t}));\n\t} catch (_error) {}\n\treturn canvas;\n}\n"
	if source.contains(old_create_canvas):
		source = source.replace(old_create_canvas, new_create_canvas)
	var old_main := "function main() {\n\tconst launcher = loadLauncher();\n\n\tlauncher.start({\n\t\tcanvas: createCanvas(),\n\t\tconfig: require('./godot.config.js')\n\t});\n}\n"
	var new_main := "function isIgnorableAbortError(error) {\n\tif (!error) {\n\t\treturn false;\n\t}\n\tconst name = String(error.name || '');\n\tconst message = String(error.message || error.errMsg || error.reason || error);\n\treturn name === 'AbortError' || message.indexOf('The user aborted a request.') !== -1;\n}\n\nfunction installUnhandledRejectionFilter() {\n\tif (typeof globalThis === 'undefined' || globalThis.__godotDouyinAbortFilterInstalled) {\n\t\treturn;\n\t}\n\tglobalThis.__godotDouyinAbortFilterInstalled = true;\n\tconst handler = function (event) {\n\t\tconst reason = event && Object.prototype.hasOwnProperty.call(event, 'reason') ? event.reason : event;\n\t\tif (!isIgnorableAbortError(reason)) {\n\t\t\treturn false;\n\t\t}\n\t\ttry {\n\t\t\tconsole.info('[godot-tt] ignored benign abort error from launcher telemetry');\n\t\t} catch (_error) {}\n\t\tif (event && typeof event.preventDefault === 'function') {\n\t\t\tevent.preventDefault();\n\t\t}\n\t\treturn true;\n\t};\n\ttry {\n\t\tif (typeof globalThis.addEventListener === 'function') {\n\t\t\tglobalThis.addEventListener('unhandledrejection', handler);\n\t\t\treturn;\n\t\t}\n\t} catch (_error) {}\n\ttry {\n\t\tglobalThis.onunhandledrejection = handler;\n\t} catch (_error) {}\n}\n\nfunction main() {\n\tinstallUnhandledRejectionFilter();\n\tconst launcher = loadLauncher();\n\tconst startResult = launcher.start({\n\t\tcanvas: createCanvas(),\n\t\tconfig: require('./godot.config.js')\n\t});\n\tif (startResult && typeof startResult.catch === 'function') {\n\t\tstartResult.catch((error) => {\n\t\t\tif (isIgnorableAbortError(error)) {\n\t\t\t\ttry {\n\t\t\t\t\tconsole.info('[godot-tt] ignored benign abort error from launcher start');\n\t\t\t\t} catch (_error) {}\n\t\t\t\treturn;\n\t\t\t}\n\t\t\tconsole.error('[godot-tt] launcher start failed', error);\n\t\t});\n\t}\n}\n"
	if source.contains(old_main):
		source = source.replace(old_main, new_main)
	var file_access := FileAccess.open(game_js_path, FileAccess.WRITE)
	file_access.store_string(source)
	file_access.close()
