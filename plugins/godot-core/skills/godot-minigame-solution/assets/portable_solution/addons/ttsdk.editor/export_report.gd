extends RefCounted

var wasm_file: String
var pack_file: String
var project_dir: String

var pack_file_relative: String:
	get:
		if pack_file.begins_with(project_dir + "/"):
			return pack_file.substr(project_dir.length() + 1)
		return pack_file
var wasm_file_relative: String:
	get:
		if wasm_file.begins_with(project_dir + "/"):
			return wasm_file.substr(project_dir.length() + 1)
		return wasm_file
