@tool
extends EditorPlugin
var exportPlatform: EditorExportPlatform
var subpackageExportPlatform: EditorExportPlatform

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	exportPlatform = preload("res://addons/ttsdk.editor/export_platform.gd").new()
	add_export_platform(exportPlatform)
	subpackageExportPlatform = preload("res://addons/ttsdk.editor/export_platform_subpackage.gd").new()
	add_export_platform(subpackageExportPlatform)

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	if exportPlatform:
		remove_export_platform(exportPlatform)
		exportPlatform = null
	if subpackageExportPlatform:
		remove_export_platform(subpackageExportPlatform)
		subpackageExportPlatform = null
