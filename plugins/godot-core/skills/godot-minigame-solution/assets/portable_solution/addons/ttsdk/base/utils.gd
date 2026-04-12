@abstract
extends Object
class_name TTUtils

static var helper: JavaScriptObject:
	get:
		if helper == null:
			helper = JavaScriptBridge.get_interface('__godot_js_helper')
		return helper

static func is_run_in_tt() -> bool:
	var tt_interface := JavaScriptBridge.get_interface("tt")
	if tt_interface == null:
		return false
	if OS.has_feature("tt"):
		return true
	for method_name in ["getSystemInfoSync", "getLaunchOptionsSync", "loadSubpackage", "createRewardedVideoAd"]:
		if tt_interface.get(method_name) != null:
			return true
	return false

class FakeJavaScriptObject extends RefCounted:
	func set(...args):
		pass
	func get(...args):
		return null;
	func call(...args):
		return null
	
static func create_fake_javascript_object() -> Variant:
	return JavaScriptBridge.create_object("Object")

static func invoke_js_argv(jso: JavaScriptObject, method: String, args: Array) -> Variant:
	if jso == null:
		return null;
	var fn = jso.get(method)
	if fn == null:
		return;
	var arg_size = args.size();
	if arg_size == 1:
		return fn.call(jso, args[0])
	elif arg_size == 2:
		return fn.call(jso, args[0], args[1])
	elif arg_size == 3:
		return fn.call(jso, args[0], args[1], args[2])
	elif arg_size == 4:
		return fn.call(jso, args[0], args[1], args[2], args[3])
	printerr("arg size out of range")
	return null

static func invoke_js(jso: JavaScriptObject, method: String) -> Variant:
	if jso == null:
		return null
	var fn = jso.get(method)
	if fn == null:
		return;
	return fn.call(jso)

static func godot2js_args(args: Array)-> Array:
	for i in args.size():
		var val = args[i]
		if val == null:
			continue;
		val = godot2js_val(args[i])
		if val == null:
			printerr("invalid arg type: " + str(typeof(args[i])))
			printerr(args[i])
		args[i] = val
	return args

static func godot2js_val(val: Variant) -> Variant:
	if val is JavaScriptObject:
		return val
	var t = typeof(val)
	if t == TYPE_BOOL || t == TYPE_STRING || t == TYPE_INT || t == TYPE_FLOAT:
		return val
	elif t == TYPE_ARRAY:
		return array_to_js(val)
	elif t == TYPE_DICTIONARY:
		return dictionary_to_js(val)
	else:
		return null

static func array_to_js(arr: Array) -> JavaScriptObject:
	var obj := JavaScriptBridge.create_object("Array");
	for i in arr.size():
		obj.push(godot2js_val(arr[i]))
	return obj
	
static func dictionary_to_js(dict: Dictionary) -> JavaScriptObject:
	var obj := JavaScriptBridge.create_object("Object");
	for key in dict.keys():
		obj[key] = godot2js_val(dict[key])
	return obj

static func array_from_js(jso: JavaScriptObject) -> Array:
	var arr := []
	for i in jso.length:
		arr.push_back(jso[i])
	return arr

static func dictionary_from_js(jso: JavaScriptObject) -> Dictionary:
	var str : String = helper.getKeysOfObject(jso)
	var keys : = str.split(",", false)
	var dict = {}
	for key in keys:
		dict[key] = jso[key]
	return dict;


enum JS_TO_GODOT_ARG_UNPACK_TYPE {
	DIRECT = 0,
	OBJECT = 1,
	ARRAY = 2,
	DICTIONARY = 3,
}

static func js2godot_args_unpack(args: Array, args_unpacks: Array) -> Array:
	var argI = 0
	for i in args_unpacks.size():
		if i >= args.size():
			break
		var arg = args[argI]
		var m = args_unpacks[i]
		if m == JS_TO_GODOT_ARG_UNPACK_TYPE.OBJECT:
			arg = args_unpacks[i+1].new(arg)
			i += 1
		elif m == JS_TO_GODOT_ARG_UNPACK_TYPE.DICTIONARY:
			arg = dictionary_from_js(arg)
		elif m == JS_TO_GODOT_ARG_UNPACK_TYPE.ARRAY:
			arg = array_from_js(arg)
		args[argI] = arg
		argI += 1
	return args


static func emit_signal_from_js_callback(owner: Object, signalName: String, args: Array, args_size: int, args_unpacks: Array) -> void:
	args_size = min(args_size, args.size()) 
	if args_size > 0:
		args = js2godot_args_unpack(args, args_unpacks);
		if args_size == 0:
			owner.emit_signal(signalName)
		elif args_size == 1:
			owner.emit_signal(signalName, args[0])
		elif args_size == 2:
			owner.emit_signal(signalName, args[0], args[1])
		elif args_size == 3:
			owner.emit_signal(signalName, args[0], args[1], args[2])
		elif args_size == 4:
			owner.emit_signal(signalName, args[0], args[1], args[2], args[3])
		elif args_size == 5:
			owner.emit_signal(signalName, args[0], args[1], args[2], args[3], args[4])
