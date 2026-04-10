@abstract
extends Node
class_name TTNode

var _javascript_object: JavaScriptObject

var _asyncTasks : Array[TTAsyncTask] = [] # keep reference
var _events : Array[TTEvent] = []

func _init(jso: JavaScriptObject) -> void:
	_javascript_object = jso;

func _enter_tree() -> void:
	pass
	
func _exit_tree() -> void:
	for evt in _events:
		evt.clear();
		evt.free();
	_events.clear();
	_asyncTasks.clear();
	
func _process(delta: float) -> void:
	for i in range(_asyncTasks.size()-1, 0, -1):
		if _asyncTasks[i].is_done:
			_asyncTasks.remove_at(i)

func _get_javascript_object() -> JavaScriptObject:
	return _javascript_object

func _register_async_task(task: TTAsyncTask) -> void:
	_asyncTasks.push_back(task)

func _register_event(js_on_method: String, js_off_method: String, to_signal_name: String, signal_args_size: int, signal_args_unpacks: Array) -> void:
	var event = TTEvent.new(_get_javascript_object(), js_on_method, js_off_method)
	_events.push_back(event)
	var handler = func (args):
		TTUtils.emit_signal_from_js_callback(self, to_signal_name, args, signal_args_size, signal_args_unpacks)
	event.on(handler)
