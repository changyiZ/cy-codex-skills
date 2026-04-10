extends Object
class_name  TTEvent

var _jso: JavaScriptObject;
var _listen_fn: String;
var _unlisten_fn: String;
var _is_listening: bool = false;

var _callback: JavaScriptObject;

var _callables;

func _init(jso: JavaScriptObject, listen_fn: String, unlisten_fn: String):
	_jso = jso;
	_listen_fn = listen_fn;
	_unlisten_fn = unlisten_fn;


func on(callable: Callable):
	if callable == null:
		return
	if _callables == null:
		_callables = callable
	elif typeof(_callables) == TYPE_ARRAY:
		_callables.push_back(callable)
	else:
		_callables = [callable]
	_check_listen_state();
	
func off(callable: Callable):
	if callable == null || _callables == null:
		return
	if _callables == callable:
		_callables = null
	elif typeof(_callables) == TYPE_ARRAY:
		for i in _callables.size():
			if _callables[i] == callable:
				_callables.remove_at(i);
				break
		if _callables.size() == 0:
			_callables = null
	_check_listen_state();

func clear():
	if _is_listening:
		_call_unlisten()
	_callables = null

func _check_listen_state():
	if _is_listening:
		if _callables == null:
			_call_unlisten()
	else:
		if _callables != null:
			_call_listen()
	

func _call_unlisten():
	if !_is_listening:
		return
	_is_listening = false;
	TTUtils.invoke_js_argv(_jso, _unlisten_fn, [_callback])
	
func _call_listen():
	if _is_listening:
		return
	_is_listening = true;
	if _callback == null:
		_callback = JavaScriptBridge.create_callback(_handle);
	
	TTUtils.invoke_js_argv(_jso, _listen_fn, [_callback])
	
func _handle(args):
	if !_is_listening:
		return
	if _callables != null:
		if typeof(_callables) == TYPE_CALLABLE:
			_callables.call(args)
		else:
			for c in Array(_callables):
				c.call(args)
