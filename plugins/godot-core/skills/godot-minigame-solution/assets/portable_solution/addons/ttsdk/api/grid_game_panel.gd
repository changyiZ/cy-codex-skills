extends TTNode
class_name GridGamePanel
signal on_state_change(grid_game_panel_state_change_response: OnStateChangeArg)

func show() -> void:
	TTUtils.invoke_js(_get_javascript_object(), 'show')

func destroy() -> void:
	TTUtils.invoke_js(_get_javascript_object(), 'destroy')

func hide() -> TTAsyncHide:
	var task = TTAsyncHide.new(self)
	await task.invoke()
	return task

class TTAsyncHide extends TTAsyncTask:
	signal success(res: SuccessRes0)
	
	signal fail(res: FailRes0)
	
	signal complete(res: CompleteRes0)
	
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
		TTUtils.invoke_js_argv(_get_javascript_object(), 'hide', args)
		if !is_done: await complete
	
	class SuccessRes0 extends TTObject:
		var err_msg: String:
			get:
				return _get_by_key_with_default('errMsg', '')
		
		func _to_string() -> String:
			return 'SuccessRes0{ ' \
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
		
class OnStateChangeArg extends TTObject:
	var state: String:
		get:
			return _get_by_key_with_default('state', '')
	
	var operate_id: Variant:
		get:
			return _get_by_key_with_default('operateId', null)
	
	var err_msg: String:
		get:
			return _get_by_key_with_default('errMsg', '')
	
	var app_name: String:
		get:
			return _get_by_key_with_default('appName', '')
	
	func _to_string() -> String:
		return 'OnStateChangeArg{ ' \
		  + 'state=' + str(state) + ', ' \
		  + 'operate_id=' + str(operate_id) + ', ' \
		  + 'err_msg=' + str(err_msg) + ', ' \
		  + 'app_name=' + str(app_name) + ', ' \
		+ '}'
	
func _enter_tree() -> void:
	_register_event('onStateChange', 'offStateChange', 'on_state_change', 1, [1,OnStateChangeArg])
