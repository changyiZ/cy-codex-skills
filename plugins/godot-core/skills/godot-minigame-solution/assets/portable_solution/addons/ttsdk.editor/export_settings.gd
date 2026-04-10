extends Object
class RemoteConfig extends RefCounted:
	var plugin_download_enabled := false
	var plugin_download_url := ""
	var plugin_version := ""

static var _remote_config: RemoteConfig

static func get_remote_config() -> RemoteConfig:
	return _remote_config

static func try_get_config_from_environment() -> RemoteConfig:
	var version = OS.get_environment("BUILD_SETTINGS_PLUGIN_VERSION");
	var download_url = OS.get_environment("BUILD_SETTINGS_PLUGIN_DOWNLOAD_URL");
	if version.is_empty() && download_url.is_empty():
		return null
	var config = RemoteConfig.new()
	if !version.is_empty():
		config.plugin_version = version
	if !download_url.is_empty():
		config.plugin_download_url = download_url
		config.plugin_download_enabled = true
	return config

static func fetch_remote_config(debug_id: String) -> Error:
	var config_from_env = try_get_config_from_environment()
	if config_from_env != null:
		_remote_config = config_from_env;
		return Error.OK
	var recv = PackedByteArray()
	var err = _tls_get_sync("is.snssdk.com", "/service/settings/v3/", {
		"aid": "247",
		"caller_name": "gameplus_uge",
		"device_id": debug_id
	}, recv)
	if err != OK:
		printerr(_get_http_error())
		return err
	
	var text = recv.get_string_from_utf8()
	var json = JSON.new()
	if json.parse(text) != OK || typeof(json.data) != TYPE_DICTIONARY:
		printerr('body failed to parse')
		return Error.FAILED
	#config.plugin_download_enabled = true
	#config.plugin_download_url = "https://lf3-static.bytednsdoc.com/obj/eden-cn/ubqupevhn/index.js"
	var dict = json.data as Dictionary
	if !dict.has("data") || !dict["data"].has("settings") || !dict["data"]["settings"].has("godot_sdk_config"):
		printerr('body error')
		return Error.FAILED
	var godot_sdk_config = dict["data"]["settings"]["godot_sdk_config"] as Dictionary
	_remote_config = RemoteConfig.new()
	_remote_config.plugin_download_enabled = godot_sdk_config.get("plugin_download_enabled", false)
	_remote_config.plugin_download_url = godot_sdk_config.get("plugin_download_url", "")
	_remote_config.plugin_version = godot_sdk_config.get("plugin_version", "")
	return OK
	

static func download_file(url: String, save_file_path: String) -> Error:
	var parsed = _parse_url(url)
	var recv = PackedByteArray()
	var err = _tls_get_sync(parsed.host, parsed.path, {}, recv)
	if err != OK:
		printerr(_get_http_error())
		return err
	var text = recv.get_string_from_utf8()
	if text.length() == 0:
		return Error.FAILED
	var fa = FileAccess.open(save_file_path, FileAccess.WRITE)
	fa.store_string(text)
	fa.close()
	return Error.OK

static var _http_error: String;

static func _get_http_error()-> String:
	return _http_error;

static func _tls_get_sync(host: String, path: String, query: Dictionary, recv: PackedByteArray) -> Error:
	_http_error = ""
	var http = HTTPClient.new()
	var err = http.connect_to_host(host, 443, TLSOptions.client())
	if err != OK:
		_http_error = "connect_to_host failed"
		return err
	
	var start = Time.get_ticks_msec()
	# Wait until resolved and connected.
	while Time.get_ticks_msec() - start < 3000 && http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		OS.delay_msec(10)
	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		_http_error = "http status error: " + str(http.get_status())
		return Error.FAILED
	
	if query.size() > 0:
		path = "%s?%s" % [path, http.query_string_from_dict(query)]
	err = http.request(HTTPClient.METHOD_GET, path, []) # Request a page from the site (this one was chunked..)
	if err != OK:
		_http_error = "http request failed"
		return err;

	while Time.get_ticks_msec() - start < 3000 && http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		http.poll()
		OS.delay_msec(10)
	if http.get_status() == HTTPClient.STATUS_REQUESTING:
		_http_error = "http request timeout"
		return Error.ERR_TIMEOUT;
		
	assert(http.has_response())
	
	var rb = PackedByteArray()
	if http.has_response():
		 # Array that will hold the data.
		while Time.get_ticks_msec() - start < 3000 && http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http.poll()
			# Get a chunk.
			var chunk = http.read_response_body_chunk()
			if chunk.size() == 0:
				OS.delay_msec(10)
			else:
				rb = rb + chunk # Append to read buffer.
		if http.get_status() == HTTPClient.STATUS_BODY:
			_http_error = "http response timeout"
			return Error.ERR_TIMEOUT;
	http.close()
	recv.clear()
	recv.append_array(rb)
	return OK
	
static func _parse_url(url: String) -> Dictionary:
	var result := {
		"scheme": "",
		"host": "",
		"port": -1,
		"path": "",
		"query": "",
		"fragment": ""
	}

	var work := url.strip_edges()

	# 1) scheme
	var scheme_split := work.split("://", false, 1)
	if scheme_split.size() == 2:
		result.scheme = scheme_split[0]
		work = scheme_split[1]
	else:
		work = scheme_split[0]  # no scheme

	# 2) fragment (#xxx)
	var frag_idx := work.find("#")
	if frag_idx != -1:
		result.fragment = work.substr(frag_idx + 1)
		work = work.substr(0, frag_idx)

	# 3) query (?xxx)
	var query_idx := work.find("?")
	if query_idx != -1:
		result.query = work.substr(query_idx + 1)
		work = work.substr(0, query_idx)

	# 4) host + optional port + path
	# find first slash (path start)
	var slash_idx := work.find("/")
	var host_port := ""
	if slash_idx != -1:
		host_port = work.substr(0, slash_idx)
		result.path = work.substr(slash_idx)  # keep leading "/"
	else:
		host_port = work
		result.path = "/"

	# 5) host:port
	var colon_idx := host_port.find(":")
	if colon_idx != -1:
		result.host = host_port.substr(0, colon_idx)
		var port_str := host_port.substr(colon_idx + 1)
		result.port = int(port_str)
	else:
		result.host = host_port
		result.port = -1  # unspecified

	return result
