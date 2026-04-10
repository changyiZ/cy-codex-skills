@tool
extends EditorPlugin

const PLUGIN_NOTICE := "Repo-managed WeChat export baseline. Use make export-wechat for the current non-interactive export flow."

func _enter_tree() -> void:
	print("[godot-minigame] %s" % PLUGIN_NOTICE)

func _exit_tree() -> void:
	pass
