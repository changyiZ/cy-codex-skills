@abstract
extends TTNode
class_name TTSDK

var _is_run_in_tt: bool = false

func _init() -> void:
	_is_run_in_tt = TTUtils.is_run_in_tt()
	if _is_run_in_tt:
		super._init(JavaScriptBridge.get_interface("tt"))
	else:
		super._init(TTUtils.create_fake_javascript_object())

func is_run_in_tt() -> bool:
	return _is_run_in_tt
# can_i_use ...

func mount_ttpkg_file(path: String) -> void:
	TTUtils.helper.mountFile(path)
