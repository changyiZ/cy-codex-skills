extends TTNode
class_name RewardedVideoAd
signal on_close(input: OnCloseArg)

signal on_error(input: OnErrorArg)

signal on_load()

func load() -> void:
	TTUtils.invoke_js(_get_javascript_object(), 'load')

func show() -> void:
	TTUtils.invoke_js(_get_javascript_object(), 'show')

func destroy() -> void:
	TTUtils.invoke_js(_get_javascript_object(), 'destroy')

class OnCloseArg extends TTObject:
	var is_ended: bool:
		get:
			return _get_by_key_with_default('isEnded', false)
	
	var count: Variant:
		get:
			return _get_by_key_with_default('count', null)
	
	func _to_string() -> String:
		return 'OnCloseArg{ ' \
		  + 'is_ended=' + str(is_ended) + ', ' \
		  + 'count=' + str(count) + ', ' \
		+ '}'
	
class OnErrorArg extends TTObject:
	var is_ended: bool:
		get:
			return _get_by_key_with_default('isEnded', false)
	
	var count: Variant:
		get:
			return _get_by_key_with_default('count', null)
	
	func _to_string() -> String:
		return 'OnErrorArg{ ' \
		  + 'is_ended=' + str(is_ended) + ', ' \
		  + 'count=' + str(count) + ', ' \
		+ '}'
	
func _enter_tree() -> void:
	_register_event('onClose', 'offClose', 'on_close', 1, [1,OnCloseArg])
	_register_event('onError', 'offError', 'on_error', 1, [1,OnErrorArg])
	_register_event('onLoad', 'offLoad', 'on_load', 0, [])


