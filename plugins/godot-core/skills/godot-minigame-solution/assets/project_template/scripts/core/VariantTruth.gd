extends RefCounted
class_name VariantTruth

static func as_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			var text := String(value).strip_edges().to_lower()
			if text.is_empty():
				return false
			if text in ["false", "0", "no", "off", "null", "nil"]:
				return false
			if text in ["true", "1", "yes", "on"]:
				return true
			return true
		TYPE_ARRAY:
			return not (value as Array).is_empty()
		TYPE_DICTIONARY:
			return not (value as Dictionary).is_empty()
		TYPE_NIL:
			return false
		_:
			return value != null
