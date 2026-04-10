extends TTNode
class_name InterstitialAd
signal on_error(data: OnErrorArg)

signal on_load()

signal on_close()

func destroy() -> void:
	TTUtils.invoke_js(_get_javascript_object(), 'destroy')

func show() -> void:
	TTUtils.invoke_js(_get_javascript_object(), 'show')

func load() -> void:
	TTUtils.invoke_js(_get_javascript_object(), 'load')

class OnErrorArg extends TTObject:
	var err_code: Variant:
		get:
			return _get_by_key_with_default('errCode', null)
	
	var err_msg: String:
		get:
			return _get_by_key_with_default('errMsg', '')
	
	func _to_string() -> String:
		return 'OnErrorArg{ ' \
		  + 'err_code=' + str(err_code) + ', ' \
		  + 'err_msg=' + str(err_msg) + ', ' \
		+ '}'
	
func _enter_tree() -> void:
	_register_event('onError', 'offError', 'on_error', 1, [1,OnErrorArg])
	_register_event('onLoad', 'offLoad', 'on_load', 0, [])
	_register_event('onClose', 'offClose', 'on_close', 0, [])
