extends TTAsyncTask
class_name TTAsyncReportScene
signal success(res: SuccessRes0)

signal fail(res: FailRes0)

signal complete(res: CompleteRes0)

var cost_time: Variant:
	set(value):
		_args_object_set(0, 'costTime', value)

var scene_id: Variant:
	set(value):
		_args_object_set(0, 'sceneId', value)

var dimension: Dictionary:
	get:
		if dimension == null:
			dimension = {}
			_args_object_set(0, 'dimension', dimension)
		return dimension
	set(value):
		dimension = value
		_args_object_set(0, 'dimension', dimension)

var metric: Dictionary:
	get:
		if metric == null:
			metric = {}
			_args_object_set(0, 'metric', metric)
		return metric
	set(value):
		metric = value
		_args_object_set(0, 'metric', metric)

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
	TTUtils.invoke_js_argv(_get_javascript_object(), 'reportScene', args)
	if !is_done: await complete

class SuccessRes0 extends TTObject:
	var err_msg: String:
		get:
			return _get_by_key_with_default('errMsg', '')
	
	var data: Data:
		get:
			if data == null:
				var jso = _get_by_key('data')
				if jso != null:
					data = Data.new(jso)
			return data
	
	class Data extends TTObject:
		var cost_time: Variant:
			get:
				return _get_by_key_with_default('costTime', null)
		
		var scene_id: Variant:
			get:
				return _get_by_key_with_default('sceneId', null)
		
		var dimension: Dictionary:
			get:
				var jso = _get_by_key('dimension')
				if jso != null:
					dimension = TTUtils.dictionary_from_js(jso)
				return dimension
		
		var metric: Dictionary:
			get:
				var jso = _get_by_key('metric')
				if jso != null:
					metric = TTUtils.dictionary_from_js(jso)
				return metric
		
		func _to_string() -> String:
			return 'Data{ ' \
			  + 'cost_time=' + str(cost_time) + ', ' \
			  + 'scene_id=' + str(scene_id) + ', ' \
			  + 'dimension=' + str(dimension) + ', ' \
			  + 'metric=' + str(metric) + ', ' \
			+ '}'
		
	func _to_string() -> String:
		return 'SuccessRes0{ ' \
		  + 'err_msg=' + str(err_msg) + ', ' \
		  + 'data=' + str(data) + ', ' \
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
	
