@abstract
extends RefCounted
class_name TTAsyncTask
var _args = {}

var _done = false;
var _owner : TTNode;
var _result: Array[Variant];
var _success: bool;

var is_done: bool:
	get:
		return _done
var is_success: bool:
	get:
		return _success

func _init(owner: TTNode) -> void:
	_owner = owner
	
func _set_success(...res: Array) -> void:
	_result = res
	_done = true
	_success = true
	
	
func _set_fail(...res: Array) -> void:
	_result = res
	_done = true
	_success = false
	
func _get_result(i: int = 0) -> Variant:
	return _result[i] if _result.size() > i else null
	
func _get_javascript_object() -> JavaScriptObject:
	return _owner._get_javascript_object()

func _register_to_owner() -> void:
	_owner._register_async_task(self)

func _args_object_set(i: int, key: String, val: Variant) -> void:
	if !_args.has(i):
		_args.set(i, {})
	var o = _args.get(i)
	o.set(key, val)
	
func _args_set(i: int, val: Variant) -> void:
	_args.set(i, val)
	
func _args_get(i: int) -> Variant:
	return _args.get(i)
	
func _args_assign(args: Array[Variant]) -> void:
	for i in args.size():
		var val = args[i]
		if typeof(val) == TYPE_DICTIONARY:
			for key in val.keys():
				_args_object_set(i, key, val.get(key))
		else:
			_args_set(i, args[i])

func _create_signal_callback(signalName: String, args_size: int, args_unpacks: Array) -> JavaScriptObject:
	var wrapped = func(args):
		TTUtils.emit_signal_from_js_callback(self, signalName, args, args_size, args_unpacks)
	return JavaScriptBridge.create_callback(wrapped)

func _reset():
	_done = false;
	_success = false;
	_result = [];
	
