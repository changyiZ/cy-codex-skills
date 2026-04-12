@tool
extends EditorPlugin

const TTSDK_AUTOLOAD_NAME = "tt"

func _enable_plugin() -> void:
	# Add autoloads here.
	add_autoload_singleton(TTSDK_AUTOLOAD_NAME, "res://addons/ttsdk/api/tt.gd")


func _disable_plugin() -> void:
	# Remove autoloads here.
	remove_autoload_singleton(TTSDK_AUTOLOAD_NAME)

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
