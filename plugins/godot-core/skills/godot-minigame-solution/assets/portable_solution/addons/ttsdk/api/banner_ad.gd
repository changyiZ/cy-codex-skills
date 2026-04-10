extends TTNode
class_name BannerAd
signal on_error(data: OnErrorArg)

signal on_resize(data: OnResizeArg)

signal on_load()

func destroy() -> void:
	TTUtils.invoke_js(_get_javascript_object(), 'destroy')

func show() -> void:
	TTUtils.invoke_js(_get_javascript_object(), 'show')

func hide() -> void:
	TTUtils.invoke_js(_get_javascript_object(), 'hide')

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
	
class OnResizeArg extends TTObject:
	var width: Variant:
		get:
			return _get_by_key_with_default('width', null)
	
	var height: Variant:
		get:
			return _get_by_key_with_default('height', null)
	
	func _to_string() -> String:
		return 'OnResizeArg{ ' \
		  + 'width=' + str(width) + ', ' \
		  + 'height=' + str(height) + ', ' \
		+ '}'
	
func _enter_tree() -> void:
	_register_event('onError', 'offError', 'on_error', 1, [1,OnErrorArg])
	_register_event('onResize', 'offResize', 'on_resize', 1, [1,OnResizeArg])
	_register_event('onLoad', 'offLoad', 'on_load', 0, [])
