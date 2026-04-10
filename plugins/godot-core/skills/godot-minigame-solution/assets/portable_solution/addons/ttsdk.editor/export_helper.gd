extends RefCounted

enum BROTLI_POLICY {
	AUTO=0,
	FAST=1,
	SIZE=2
}
const BROTLI_POLICY_HIT_STRING:  = "Auto,Fast,Size"
static func export_pack(platform: EditorExportPlatform, preset: EditorExportPreset, debug: bool, export_pck_path: String, brotli_on: bool, brotli_policy: BROTLI_POLICY, report = null) -> Error:
	var res = platform.save_pack(preset, debug, export_pck_path);
	if res.result != Error.OK:
		return res.result
	for so in res.so_files:
		print("so_files: " + so.path + " [" + str(so.tags) + "] " + so.target_folder)

	var file_name = export_pck_path.get_file()
	
	var pack_bytes = FileAccess.get_file_as_bytes(export_pck_path)
	var export_bin_path = export_pck_path.substr(0, export_pck_path.length() - 4) + ".bin"
	var file_access_pack_bin = FileAccess.open(export_bin_path, FileAccess.WRITE)
	file_access_pack_bin.store_buffer(pack_bytes)
	file_access_pack_bin.close()
	if report != null:
		report.pack_file = export_bin_path
	
	var export_br_path = export_pck_path.substr(0, export_pck_path.length() - 4) + ".br"
	if brotli_on:
		if brotli_policy == BROTLI_POLICY.AUTO:
			brotli_policy = BROTLI_POLICY.FAST if debug else BROTLI_POLICY.SIZE
		
		Brotli.compress_file(export_bin_path, export_br_path, 5 if brotli_policy == BROTLI_POLICY.FAST else 9)
		DirAccess.remove_absolute(export_bin_path)
		if report != null:
			report.pack_file = export_br_path
	else:
		if FileAccess.file_exists(export_br_path):
			DirAccess.remove_absolute(export_br_path)
	return Error.OK
