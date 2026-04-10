extends EditorExportPlatformExtension

const ExportHelperScript = preload("res://addons/ttsdk.editor/export_helper.gd")


func _get_name() -> String:
	return "tt-minigame-subpackage"
	
func _get_logo() -> Texture2D:
	return load("res://addons/ttsdk.editor/platform-logo.png")
func _get_platform_features() -> PackedStringArray:
	return PackedStringArray(["web", "Web", "tt"])
func _get_preset_features(preset: EditorExportPreset) -> PackedStringArray:
	var features = ["astc", "etc2", "nothreads", "wasm32"]
	return PackedStringArray(features)
func _get_binary_extensions(preset: EditorExportPreset) -> PackedStringArray:
	return PackedStringArray([])
func _is_executable(path: String) -> bool:
	return false
func _get_export_options() -> Array[Dictionary]:
	return [
		{ "name": "douyin/project_config_file", "type": Variant.Type.TYPE_STRING, "default_value": "", "hint": PropertyHint.PROPERTY_HINT_GLOBAL_FILE, "hint_string": "*.config.json"},
		{ "name": "douyin/subpackage_name", "type": Variant.Type.TYPE_STRING, "default_value": ""},
		{ "name": "douyin_optimize/brotli_on", "type":Variant.Type.TYPE_BOOL, "default_value": false },
		{ "name": "douyin_optimize/brotli_policy", "type": Variant.Type.TYPE_INT, "default_value": 0, "hint": PropertyHint.PROPERTY_HINT_ENUM, "hint_string": "Auto,Fast,Size"},
	]
func _has_valid_export_configuration(preset: EditorExportPreset, debug: bool) -> bool:
	var project_config_file = preset.get_or_env("douyin/project_config_file", "")
	if !FileAccess.file_exists(project_config_file):
		set_config_error("project_config_file not exist: " + project_config_file)
		return false
	if !preset.get_or_env("douyin/subpackage_name", ""):
		set_config_error("subpackage_name is empty")
		return false
	return true

func _has_valid_project_configuration(preset: EditorExportPreset) -> bool:
	if !ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc"):
		return false
	return true
func _export_pack_patch(preset: EditorExportPreset, debug: bool, path: String, patches: PackedStringArray, flags: int) -> Error:
	printerr("export pack patch not available.")
	return Error.ERR_UNAVAILABLE
func _export_zip_patch(preset: EditorExportPreset, debug: bool, path: String, patches: PackedStringArray, flags: int) -> Error:
	printerr("export zip patch not available.")
	return Error.ERR_UNAVAILABLE
func _export_zip(preset: EditorExportPreset, debug: bool, path: String, flags: int) -> Error:
	printerr("export zip not available.")
	return Error.ERR_UNAVAILABLE
func _export_project(preset: EditorExportPreset, debug: bool, path: String, flags: int) -> Error:
	printerr("export project not available.")
	return Error.ERR_UNAVAILABLE
	
func _export_pack(preset: EditorExportPreset, debug: bool, export_pck_path: String, flags: int) -> Error:
	if !export_pck_path.ends_with(".pck"):
		printerr("please use .pck as file extension.")
		return Error.ERR_FILE_BAD_PATH
	
	var project_config_file :String= preset.get_or_env("douyin/project_config_file", "")
	if !FileAccess.file_exists(project_config_file):
		printerr("project.config.json file not exists at: " + project_config_file)
		return Error.ERR_FILE_NOT_FOUND
	var game_json_file :String= project_config_file.get_base_dir().path_join("game.json")
	if !FileAccess.file_exists(game_json_file):
		printerr("game.json file not exists at: " + game_json_file)
		return Error.ERR_FILE_NOT_FOUND
	
	var project_dir = ProjectSettings.globalize_path(project_config_file.get_base_dir()).simplify_path()
	var export_dir = ProjectSettings.globalize_path(export_pck_path.get_base_dir()).simplify_path()
	if !export_dir.begins_with(project_dir) || project_dir == export_dir:
		printerr("export path should be inside a sub directory of " + project_dir + ", current is " + export_dir)
		return Error.ERR_FILE_BAD_PATH
	if !DirAccess.dir_exists_absolute(export_dir):
		DirAccess.make_dir_recursive_absolute(export_dir)
	
	var export_dir_access = DirAccess.open(export_dir)
	
	var res = save_pack(preset, debug, export_pck_path);
	for so in res.so_files:
		print("so_files: " + so.path + " [" + str(so.tags) + "] " + so.target_folder)
	if res.result != Error.OK:
		return res.result
	
	var file_name = export_pck_path.get_file()
	
	var brotli_on = preset.get_or_env("douyin_optimize/brotli_on", "")
	var brotli_policy = preset.get_or_env("douyin_optimize/brotli_policy", "")
	ExportHelperScript.export_pack(self, preset, debug, export_pck_path, brotli_on, brotli_policy)
	
	var subpackage_root = _resolve_subpackage_root(project_config_file, export_pck_path)
	var err = _write_game_json(game_json_file, preset.get_or_env("douyin/subpackage_name", ""), subpackage_root)

	if !FileAccess.file_exists(export_dir.path_join("game.js")):
		var fa = FileAccess.open(export_dir.path_join("game.js"), FileAccess.WRITE)
		fa.close() # empty file

	return Error.OK
	
func _resolve_subpackage_root(project_config_file: String, export_pack_path: String)-> String:
	var project_dir = ProjectSettings.globalize_path(project_config_file.get_base_dir()).simplify_path()
	var package_dir = ProjectSettings.globalize_path(export_pack_path.get_base_dir()).simplify_path()
	return package_dir.replace(project_dir + "/", "")

func _write_game_json(file_path: String, name: String, root: String) -> Error:
	var json = JSON.new()
	var err = json.parse(FileAccess.get_file_as_string(file_path))
	if err != Error.OK:
		return err
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		printerr("invalid game json file, please re-export project. " + file_path)
		return Error.ERR_INVALID_DATA
	var subpackages = data.get_or_add("subpackages", [])
	for x in subpackages:
		if x.get("name") == name && x.get("root") == root:
			return Error.OK
	subpackages.push_back({ "name": name, "root": root })
	var fa = FileAccess.open(file_path, FileAccess.WRITE)
	if fa == null:
		return FileAccess.get_open_error()
	fa.store_string(JSON.stringify(data, "    "))
	fa.close()
	return Error.OK
	
