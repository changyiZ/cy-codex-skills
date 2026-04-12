@abstract
extends RefCounted
class_name TTObject
var _javaScriptObject: JavaScriptObject;


func _init(object: JavaScriptObject):
	_javaScriptObject = object

func _get_javascript_object() ->JavaScriptObject:
	return _javaScriptObject

func _get_by_key(key: String) -> Variant:
	return _javaScriptObject[key]

func _get_by_key_with_default(key: String, default: Variant) -> Variant:
	var ret = _javaScriptObject[key]
	if ret != null:
		return ret
	return default
