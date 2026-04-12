extends RefCounted
class_name MinigameSubpackageManifest

const DEFAULT_MANIFEST_PATH := "res://data/minigame_subpackages.json"

static func load_manifest(path: String = DEFAULT_MANIFEST_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return (parsed as Dictionary).duplicate(true)

static func get_platform_subpackages(platform_name: String, path: String = DEFAULT_MANIFEST_PATH) -> Array[Dictionary]:
	var manifest := load_manifest(path)
	if typeof(manifest.get("platforms", {})) != TYPE_DICTIONARY:
		return []
	var platforms := manifest.get("platforms", {}) as Dictionary
	if typeof(platforms.get(platform_name, {})) != TYPE_DICTIONARY:
		return []
	var platform_config := platforms.get(platform_name, {}) as Dictionary
	if typeof(platform_config.get("subpackages", [])) != TYPE_ARRAY:
		return []
	var result: Array[Dictionary] = []
	for entry in platform_config.get("subpackages", []):
		if typeof(entry) == TYPE_DICTIONARY:
			result.append((entry as Dictionary).duplicate(true))
	return result

static func find_subpackage(platform_name: String, subpackage_name: String, path: String = DEFAULT_MANIFEST_PATH) -> Dictionary:
	for entry in get_platform_subpackages(platform_name, path):
		if String(entry.get("name", "")) == subpackage_name:
			return entry
	return {}
