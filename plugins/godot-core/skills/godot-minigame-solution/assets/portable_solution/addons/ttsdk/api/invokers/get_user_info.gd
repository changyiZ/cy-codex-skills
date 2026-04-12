extends TTAsyncTask
class_name TTAsyncGetUserInfo
signal success(res: SuccessRes0)

signal fail(res: FailRes0)

signal complete(res: CompleteRes0)

var with_credentials: bool:
	set(value):
		_args_object_set(0, 'withCredentials', value)

var with_real_name_authentication_info: bool:
	set(value):
		_args_object_set(0, 'withRealNameAuthenticationInfo', value)

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
	TTUtils.invoke_js_argv(_get_javascript_object(), 'getUserInfo', args)
	if !is_done: await complete

class SuccessRes0 extends TTObject:
	var user_info: UserInfo:
		get:
			if user_info == null:
				var jso = _get_by_key('userInfo')
				if jso != null:
					user_info = UserInfo.new(jso)
			return user_info
	
	var raw_data: String:
		get:
			return _get_by_key_with_default('rawData', '')
	
	var signature: String:
		get:
			return _get_by_key_with_default('signature', '')
	
	var encrypted_data: String:
		get:
			return _get_by_key_with_default('encryptedData', '')
	
	var iv: String:
		get:
			return _get_by_key_with_default('iv', '')
	
	var real_name_authentication_status: Variant:
		get:
			return _get_by_key_with_default('realNameAuthenticationStatus', null)
	
	var err_msg: String:
		get:
			return _get_by_key_with_default('errMsg', '')
	
	class UserInfo extends TTObject:
		var avatar_url: String:
			get:
				return _get_by_key_with_default('avatarUrl', '')
		
		var nick_name: String:
			get:
				return _get_by_key_with_default('nickName', '')
		
		var gender: Variant:
			get:
				return _get_by_key_with_default('gender', null)
		
		var city: String:
			get:
				return _get_by_key_with_default('city', '')
		
		var province: String:
			get:
				return _get_by_key_with_default('province', '')
		
		var country: String:
			get:
				return _get_by_key_with_default('country', '')
		
		var language: String:
			get:
				return _get_by_key_with_default('language', '')
		
		func _to_string() -> String:
			return 'UserInfo{ ' \
			  + 'avatar_url=' + str(avatar_url) + ', ' \
			  + 'nick_name=' + str(nick_name) + ', ' \
			  + 'gender=' + str(gender) + ', ' \
			  + 'city=' + str(city) + ', ' \
			  + 'province=' + str(province) + ', ' \
			  + 'country=' + str(country) + ', ' \
			  + 'language=' + str(language) + ', ' \
			+ '}'
		
	func _to_string() -> String:
		return 'SuccessRes0{ ' \
		  + 'user_info=' + str(user_info) + ', ' \
		  + 'raw_data=' + str(raw_data) + ', ' \
		  + 'signature=' + str(signature) + ', ' \
		  + 'encrypted_data=' + str(encrypted_data) + ', ' \
		  + 'iv=' + str(iv) + ', ' \
		  + 'real_name_authentication_status=' + str(real_name_authentication_status) + ', ' \
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
	

