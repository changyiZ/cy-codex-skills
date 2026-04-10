extends TTAsyncTask
class_name TTAsyncShowDouyinOpenAuth
signal success(res: SuccessRes0)

signal fail(res: FailRes0)

signal complete(res: CompleteRes0)

var scopes: Dictionary:
	get:
		if scopes == null:
			scopes = {}
			_args_object_set(0, 'scopes', scopes)
		return scopes
	set(value):
		scopes = value
		_args_object_set(0, 'scopes', scopes)

func get_result_success() -> SuccessRes0:
	return _get_result() if is_success else null

func get_result_fail() -> FailRes0:
	return null if is_success else _get_result()

func invoke() -> void:
	_register_to_owner()
	_args_object_set(0, 'success', _create_signal_callback('success', 1, [1,SuccessRes0]))
	_args_object_set(0, 'fail', _create_signal_callback('fail', 1, [1,FailRes0]))
	_args_object_set(0, 'complete', _create_signal_callback('complete', 1, [1,CompleteRes0]))
	if !success.is_connected(_set_success): success.connect(_set_success, CONNECT_ONE_SHOT)
	if !fail.is_connected(_set_fail): fail.connect(_set_fail, CONNECT_ONE_SHOT)
	var args = TTUtils.godot2js_args([_args_get(0)])
	TTUtils.invoke_js_argv(_get_javascript_object(), 'showDouyinOpenAuth', args)
	if !is_done: await complete

class SuccessRes0 extends TTObject:
	var ticket: String:
		get:
			return _get_by_key_with_default('ticket', '')
	
	var grant_permissions: Array:
		get:
			var jso = _get_by_key('grantPermissions')
			if jso != null:
				grant_permissions = TTUtils.array_from_js(jso)
			return grant_permissions
	
	var err_msg: String:
		get:
			return _get_by_key_with_default('errMsg', '')
	
	func _to_string() -> String:
		return 'SuccessRes0{ ' \
		  + 'ticket=' + str(ticket) + ', ' \
		  + 'grant_permissions=' + str(grant_permissions) + ', ' \
		  + 'err_msg=' + str(err_msg) + ', ' \
		+ '}'
	
class FailRes0 extends TTObject:
	var err_msg: String:
		get:
			return _get_by_key_with_default('errMsg', '')
	
	func _to_string() -> String:
		return 'FailRes0{ ' \
		  + 'err_msg=' + str(err_msg) + ', ' \
		+ '}'
	
class CompleteRes0 extends TTObject:
	var err_msg: String:
		get:
			return _get_by_key_with_default('errMsg', '')
	
	func _to_string() -> String:
		return 'CompleteRes0{ ' \
		  + 'err_msg=' + str(err_msg) + ', ' \
		+ '}'
	

