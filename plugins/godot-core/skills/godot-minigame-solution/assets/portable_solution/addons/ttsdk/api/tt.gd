extends TTSDK
class_name TT
signal on_feed_status_change(params: OnFeedStatusChangeArg)

signal on_hide()

signal on_share_app_message(args_0: OnShareAppMessageArg)

signal on_show(game_show_params: OnShowArg)

func add_shortcut() -> TTAsyncAddShortcut:
	var task = TTAsyncAddShortcut.new(self)
	await task.invoke()
	return task

func authorize(...args: Array[Variant]) -> TTAsyncAuthorize:
	var task = TTAsyncAuthorize.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func authorize_async() -> TTAsyncAuthorize:
	return TTAsyncAuthorize.new(self)

func create_banner_ad(param: Dictionary) -> BannerAd:
	var args = TTUtils.godot2js_args([param])
	var jso = TTUtils.invoke_js_argv(_get_javascript_object(), 'createBannerAd', args)
	var node = BannerAd.new(jso)
	add_child(node)
	return node

func check_feed_subscribe_status(...args: Array[Variant]) -> TTAsyncCheckFeedSubscribeStatus:
	var task = TTAsyncCheckFeedSubscribeStatus.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func check_feed_subscribe_status_async() -> TTAsyncCheckFeedSubscribeStatus:
	return TTAsyncCheckFeedSubscribeStatus.new(self)

func check_scene(...args: Array[Variant]) -> TTAsyncCheckScene:
	var task = TTAsyncCheckScene.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func check_scene_async() -> TTAsyncCheckScene:
	return TTAsyncCheckScene.new(self)

func check_session() -> TTAsyncCheckSession:
	var task = TTAsyncCheckSession.new(self)
	await task.invoke()
	return task

func check_shortcut() -> TTAsyncCheckShortcut:
	var task = TTAsyncCheckShortcut.new(self)
	await task.invoke()
	return task

func exit_mini_program(...args: Array[Variant]) -> TTAsyncExitMiniProgram:
	var task = TTAsyncExitMiniProgram.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func exit_mini_program_async() -> TTAsyncExitMiniProgram:
	return TTAsyncExitMiniProgram.new(self)

func get_env_info_sync() -> EnvInfo:
	return EnvInfo.new(TTUtils.invoke_js(_get_javascript_object(), 'getEnvInfoSync'))

func get_launch_options_sync() -> GetLaunchOptionsSyncResult:
	return GetLaunchOptionsSyncResult.new(TTUtils.invoke_js(_get_javascript_object(), 'getLaunchOptionsSync'))

func get_setting() -> TTAsyncGetSetting:
	var task = TTAsyncGetSetting.new(self)
	await task.invoke()
	return task

func get_system_info() -> TTAsyncGetSystemInfo:
	var task = TTAsyncGetSystemInfo.new(self)
	await task.invoke()
	return task

func get_system_info_sync() -> SystemInfo:
	return SystemInfo.new(TTUtils.invoke_js(_get_javascript_object(), 'getSystemInfoSync'))

func create_grid_game_panel(params: Dictionary) -> GridGamePanel:
	var args = TTUtils.godot2js_args([params])
	var jso = TTUtils.invoke_js_argv(_get_javascript_object(), 'createGridGamePanel', args)
	var node = GridGamePanel.new(jso)
	add_child(node)
	return node

func hide_share_menu() -> TTAsyncHideShareMenu:
	var task = TTAsyncHideShareMenu.new(self)
	await task.invoke()
	return task

func create_interstitial_ad(params: Dictionary) -> InterstitialAd:
	var args = TTUtils.godot2js_args([params])
	var jso = TTUtils.invoke_js_argv(_get_javascript_object(), 'createInterstitialAd', args)
	var node = InterstitialAd.new(jso)
	add_child(node)
	return node

func load_subpackage(...args: Array[Variant]) -> TTAsyncLoadSubpackage:
	var task = TTAsyncLoadSubpackage.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func load_subpackage_async() -> TTAsyncLoadSubpackage:
	return TTAsyncLoadSubpackage.new(self)

func login(...args: Array[Variant]) -> TTAsyncLogin:
	var task = TTAsyncLogin.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func login_async() -> TTAsyncLogin:
	return TTAsyncLogin.new(self)

func navigate_to_scene(...args: Array[Variant]) -> TTAsyncNavigateToScene:
	var task = TTAsyncNavigateToScene.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func navigate_to_scene_async() -> TTAsyncNavigateToScene:
	return TTAsyncNavigateToScene.new(self)

func navigate_to_video_view(...args: Array[Variant]) -> TTAsyncNavigateToVideoView:
	var task = TTAsyncNavigateToVideoView.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func navigate_to_video_view_async() -> TTAsyncNavigateToVideoView:
	return TTAsyncNavigateToVideoView.new(self)

func open_setting() -> TTAsyncOpenSetting:
	var task = TTAsyncOpenSetting.new(self)
	await task.invoke()
	return task

func report_analytics(event: String, data: Dictionary) -> void:
	var args = TTUtils.godot2js_args([event, data])
	TTUtils.invoke_js_argv(_get_javascript_object(), 'reportAnalytics', args)

func report_scene(...args: Array[Variant]) -> TTAsyncReportScene:
	var task = TTAsyncReportScene.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func report_scene_async() -> TTAsyncReportScene:
	return TTAsyncReportScene.new(self)

func request_feed_subscribe(...args: Array[Variant]) -> TTAsyncRequestFeedSubscribe:
	var task = TTAsyncRequestFeedSubscribe.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func request_feed_subscribe_async() -> TTAsyncRequestFeedSubscribe:
	return TTAsyncRequestFeedSubscribe.new(self)

func request_subscribe_message(...args: Array[Variant]) -> TTAsyncRequestSubscribeMessage:
	var task = TTAsyncRequestSubscribeMessage.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func request_subscribe_message_async() -> TTAsyncRequestSubscribeMessage:
	return TTAsyncRequestSubscribeMessage.new(self)

func restart_mini_program_sync() -> void:
	TTUtils.invoke_js(_get_javascript_object(), 'restartMiniProgramSync')

func create_rewarded_video_ad(params: Dictionary) -> RewardedVideoAd:
	var args = TTUtils.godot2js_args([params])
	var jso = TTUtils.invoke_js_argv(_get_javascript_object(), 'createRewardedVideoAd', args)
	var node = RewardedVideoAd.new(jso)
	add_child(node)
	return node

func share_app_message(...args: Array[Variant]) -> TTAsyncShareAppMessage:
	var task = TTAsyncShareAppMessage.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func share_app_message_async() -> TTAsyncShareAppMessage:
	return TTAsyncShareAppMessage.new(self)

func share_message_to_friend(...args: Array[Variant]) -> TTAsyncShareMessageToFriend:
	var task = TTAsyncShareMessageToFriend.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func share_message_to_friend_async() -> TTAsyncShareMessageToFriend:
	return TTAsyncShareMessageToFriend.new(self)

func show_douyin_open_auth(...args: Array[Variant]) -> TTAsyncShowDouyinOpenAuth:
	var task = TTAsyncShowDouyinOpenAuth.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func show_douyin_open_auth_async() -> TTAsyncShowDouyinOpenAuth:
	return TTAsyncShowDouyinOpenAuth.new(self)

func show_share_menu() -> TTAsyncShowShareMenu:
	var task = TTAsyncShowShareMenu.new(self)
	await task.invoke()
	return task

func get_clipboard_data() -> TTAsyncGetClipboardData:
	var task = TTAsyncGetClipboardData.new(self)
	await task.invoke()
	return task

func set_clipboard_data(...args: Array[Variant]) -> TTAsyncSetClipboardData:
	var task = TTAsyncSetClipboardData.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func set_clipboard_data_async() -> TTAsyncSetClipboardData:
	return TTAsyncSetClipboardData.new(self)

func get_menu_button_layout() -> MenuButtonLayout:
	return MenuButtonLayout.new(TTUtils.invoke_js(_get_javascript_object(), 'getMenuButtonLayout'))

func hide_loading() -> TTAsyncHideLoading:
	var task = TTAsyncHideLoading.new(self)
	await task.invoke()
	return task

func show_loading(...args: Array[Variant]) -> TTAsyncShowLoading:
	var task = TTAsyncShowLoading.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func show_loading_async() -> TTAsyncShowLoading:
	return TTAsyncShowLoading.new(self)

func get_user_info(...args: Array[Variant]) -> TTAsyncGetUserInfo:
	var task = TTAsyncGetUserInfo.new(self)
	task._args_assign(args)
	await task.invoke()
	return task

func get_user_info_async() -> TTAsyncGetUserInfo:
	return TTAsyncGetUserInfo.new(self)

class GetLaunchOptionsSyncResult extends TTObject:
	var scene: String:
		get:
			return _get_by_key_with_default('scene', '')
	
	var query: Dictionary:
		get:
			var jso = _get_by_key('query')
			if jso != null:
				query = TTUtils.dictionary_from_js(jso)
			return query
	
	var extra: Dictionary:
		get:
			var jso = _get_by_key('extra')
			if jso != null:
				extra = TTUtils.dictionary_from_js(jso)
			return extra
	
	func _to_string() -> String:
		return 'GetLaunchOptionsSyncResult{ ' \
		  + 'scene=' + str(scene) + ', ' \
		  + 'query=' + str(query) + ', ' \
		  + 'extra=' + str(extra) + ', ' \
		+ '}'
	
class OnFeedStatusChangeArg extends TTObject:
	var type: String:
		get:
			return _get_by_key_with_default('type', '')
	
	func _to_string() -> String:
		return 'OnFeedStatusChangeArg{ ' \
		  + 'type=' + str(type) + ', ' \
		+ '}'
	
class OnShareAppMessageArg extends TTObject:
	var channel: String:
		get:
			return _get_by_key_with_default('channel', '')
	
	func _to_string() -> String:
		return 'OnShareAppMessageArg{ ' \
		  + 'channel=' + str(channel) + ', ' \
		+ '}'
	
class OnShowArg extends TTObject:
	var query: Dictionary:
		get:
			var jso = _get_by_key('query')
			if jso != null:
				query = TTUtils.dictionary_from_js(jso)
			return query
	
	var scene: String:
		get:
			return _get_by_key_with_default('scene', '')
	
	var sub_scene: String:
		get:
			return _get_by_key_with_default('subScene', '')
	
	var share_ticket: String:
		get:
			return _get_by_key_with_default('shareTicket', '')
	
	var referer_info: RefererInfo:
		get:
			if referer_info == null:
				var jso = _get_by_key('refererInfo')
				if jso != null:
					referer_info = RefererInfo.new(jso)
			return referer_info
	
	var show_from: Variant:
		get:
			return _get_by_key_with_default('showFrom', null)
	
	var launch_from: String:
		get:
			return _get_by_key_with_default('launch_from', '')
	
	var location: String:
		get:
			return _get_by_key_with_default('location', '')
	
	class RefererInfo extends TTObject:
		var app_id: String:
			get:
				return _get_by_key_with_default('appId', '')
		
		var extra_data: Dictionary:
			get:
				var jso = _get_by_key('extraData')
				if jso != null:
					extra_data = TTUtils.dictionary_from_js(jso)
				return extra_data
		
		func _to_string() -> String:
			return 'RefererInfo{ ' \
			  + 'app_id=' + str(app_id) + ', ' \
			  + 'extra_data=' + str(extra_data) + ', ' \
			+ '}'
		
	func _to_string() -> String:
		return 'OnShowArg{ ' \
		  + 'query=' + str(query) + ', ' \
		  + 'scene=' + str(scene) + ', ' \
		  + 'sub_scene=' + str(sub_scene) + ', ' \
		  + 'share_ticket=' + str(share_ticket) + ', ' \
		  + 'referer_info=' + str(referer_info) + ', ' \
		  + 'show_from=' + str(show_from) + ', ' \
		  + 'launch_from=' + str(launch_from) + ', ' \
		  + 'location=' + str(location) + ', ' \
		+ '}'
	
class EnvInfo extends TTObject:
	var microapp: Microapp:
		get:
			if microapp == null:
				var jso = _get_by_key('microapp')
				if jso != null:
					microapp = Microapp.new(jso)
			return microapp
	
	var plugin: Dictionary:
		get:
			var jso = _get_by_key('plugin')
			if jso != null:
				plugin = TTUtils.dictionary_from_js(jso)
			return plugin
	
	var common: Common:
		get:
			if common == null:
				var jso = _get_by_key('common')
				if jso != null:
					common = Common.new(jso)
			return common
	
	class Microapp extends TTObject:
		var mp_version: String:
			get:
				return _get_by_key_with_default('mpVersion', '')
		
		var env_type: String:
			get:
				return _get_by_key_with_default('envType', '')
		
		var app_id: String:
			get:
				return _get_by_key_with_default('appId', '')
		
		func _to_string() -> String:
			return 'Microapp{ ' \
			  + 'mp_version=' + str(mp_version) + ', ' \
			  + 'env_type=' + str(env_type) + ', ' \
			  + 'app_id=' + str(app_id) + ', ' \
			+ '}'
		
	class Common extends TTObject:
		var user_data_path: String:
			get:
				return _get_by_key_with_default('USER_DATA_PATH', '')
		
		func _to_string() -> String:
			return 'Common{ ' \
			  + 'user_data_path=' + str(user_data_path) + ', ' \
			+ '}'
		
	func _to_string() -> String:
		return 'EnvInfo{ ' \
		  + 'microapp=' + str(microapp) + ', ' \
		  + 'plugin=' + str(plugin) + ', ' \
		  + 'common=' + str(common) + ', ' \
		+ '}'
	
class SystemInfo extends TTObject:
	var system: String:
		get:
			return _get_by_key_with_default('system', '')
	
	var platform: String:
		get:
			return _get_by_key_with_default('platform', '')
	
	var brand: String:
		get:
			return _get_by_key_with_default('brand', '')
	
	var model: String:
		get:
			return _get_by_key_with_default('model', '')
	
	var version: String:
		get:
			return _get_by_key_with_default('version', '')
	
	var app_name: String:
		get:
			return _get_by_key_with_default('appName', '')
	
	var native_sdk_version: String:
		get:
			return _get_by_key_with_default('nativeSDKVersion', '')
	
	var sdk_version: String:
		get:
			return _get_by_key_with_default('SDKVersion', '')
	
	var sdk_update_version: String:
		get:
			return _get_by_key_with_default('SDKUpdateVersion', '')
	
	var screen_width: Variant:
		get:
			return _get_by_key_with_default('screenWidth', null)
	
	var screen_height: Variant:
		get:
			return _get_by_key_with_default('screenHeight', null)
	
	var window_width: Variant:
		get:
			return _get_by_key_with_default('windowWidth', null)
	
	var window_height: Variant:
		get:
			return _get_by_key_with_default('windowHeight', null)
	
	var status_bar_height: Variant:
		get:
			return _get_by_key_with_default('statusBarHeight', null)
	
	var safe_area: SafeArea:
		get:
			if safe_area == null:
				var jso = _get_by_key('safeArea')
				if jso != null:
					safe_area = SafeArea.new(jso)
			return safe_area
	
	var pixel_ratio: Variant:
		get:
			return _get_by_key_with_default('pixelRatio', null)
	
	var font_size_setting: Variant:
		get:
			return _get_by_key_with_default('fontSizeSetting', null)
	
	var battery: Variant:
		get:
			return _get_by_key_with_default('battery', null)
	
	var wifi_signal: Variant:
		get:
			return _get_by_key_with_default('wifiSignal', null)
	
	var language: String:
		get:
			return _get_by_key_with_default('language', '')
	
	var device_score: DeviceScore:
		get:
			if device_score == null:
				var jso = _get_by_key('deviceScore')
				if jso != null:
					device_score = DeviceScore.new(jso)
			return device_score
	
	var screen_ratio: Variant:
		get:
			return _get_by_key_with_default('screenRatio', null)
	
	var device_orientation: String:
		get:
			return _get_by_key_with_default('deviceOrientation', '')
	
	class SafeArea extends TTObject:
		var left: Variant:
			get:
				return _get_by_key_with_default('left', null)
		
		var right: Variant:
			get:
				return _get_by_key_with_default('right', null)
		
		var top: Variant:
			get:
				return _get_by_key_with_default('top', null)
		
		var bottom: Variant:
			get:
				return _get_by_key_with_default('bottom', null)
		
		var width: Variant:
			get:
				return _get_by_key_with_default('width', null)
		
		var height: Variant:
			get:
				return _get_by_key_with_default('height', null)
		
		func _to_string() -> String:
			return 'SafeArea{ ' \
			  + 'left=' + str(left) + ', ' \
			  + 'right=' + str(right) + ', ' \
			  + 'top=' + str(top) + ', ' \
			  + 'bottom=' + str(bottom) + ', ' \
			  + 'width=' + str(width) + ', ' \
			  + 'height=' + str(height) + ', ' \
			+ '}'
		
	class DeviceScore extends TTObject:
		var cpu: Variant:
			get:
				return _get_by_key_with_default('cpu', null)
		
		var gpu: Variant:
			get:
				return _get_by_key_with_default('gpu', null)
		
		var memory: Variant:
			get:
				return _get_by_key_with_default('memory', null)
		
		var overall: Variant:
			get:
				return _get_by_key_with_default('overall', null)
		
		func _to_string() -> String:
			return 'DeviceScore{ ' \
			  + 'cpu=' + str(cpu) + ', ' \
			  + 'gpu=' + str(gpu) + ', ' \
			  + 'memory=' + str(memory) + ', ' \
			  + 'overall=' + str(overall) + ', ' \
			+ '}'
		
	func _to_string() -> String:
		return 'SystemInfo{ ' \
		  + 'system=' + str(system) + ', ' \
		  + 'platform=' + str(platform) + ', ' \
		  + 'brand=' + str(brand) + ', ' \
		  + 'model=' + str(model) + ', ' \
		  + 'version=' + str(version) + ', ' \
		  + 'app_name=' + str(app_name) + ', ' \
		  + 'native_sdk_version=' + str(native_sdk_version) + ', ' \
		  + 'sdk_version=' + str(sdk_version) + ', ' \
		  + 'sdk_update_version=' + str(sdk_update_version) + ', ' \
		  + 'screen_width=' + str(screen_width) + ', ' \
		  + 'screen_height=' + str(screen_height) + ', ' \
		  + 'window_width=' + str(window_width) + ', ' \
		  + 'window_height=' + str(window_height) + ', ' \
		  + 'status_bar_height=' + str(status_bar_height) + ', ' \
		  + 'safe_area=' + str(safe_area) + ', ' \
		  + 'pixel_ratio=' + str(pixel_ratio) + ', ' \
		  + 'font_size_setting=' + str(font_size_setting) + ', ' \
		  + 'battery=' + str(battery) + ', ' \
		  + 'wifi_signal=' + str(wifi_signal) + ', ' \
		  + 'language=' + str(language) + ', ' \
		  + 'device_score=' + str(device_score) + ', ' \
		  + 'screen_ratio=' + str(screen_ratio) + ', ' \
		  + 'device_orientation=' + str(device_orientation) + ', ' \
		+ '}'
	
class MenuButtonLayout extends TTObject:
	var width: Variant:
		get:
			return _get_by_key_with_default('width', null)
	
	var height: Variant:
		get:
			return _get_by_key_with_default('height', null)
	
	var top: Variant:
		get:
			return _get_by_key_with_default('top', null)
	
	var bottom: Variant:
		get:
			return _get_by_key_with_default('bottom', null)
	
	var right: Variant:
		get:
			return _get_by_key_with_default('right', null)
	
	var left: Variant:
		get:
			return _get_by_key_with_default('left', null)
	
	func _to_string() -> String:
		return 'MenuButtonLayout{ ' \
		  + 'width=' + str(width) + ', ' \
		  + 'height=' + str(height) + ', ' \
		  + 'top=' + str(top) + ', ' \
		  + 'bottom=' + str(bottom) + ', ' \
		  + 'right=' + str(right) + ', ' \
		  + 'left=' + str(left) + ', ' \
		+ '}'
	
func _enter_tree() -> void:
	_register_event('onFeedStatusChange', 'offFeedStatusChange', 'on_feed_status_change', 1, [1,OnFeedStatusChangeArg])
	_register_event('onHide', 'offHide', 'on_hide', 0, [])
	_register_event('onShareAppMessage', 'offShareAppMessage', 'on_share_app_message', 1, [1,OnShareAppMessageArg])
	_register_event('onShow', 'offShow', 'on_show', 1, [1,OnShowArg])
