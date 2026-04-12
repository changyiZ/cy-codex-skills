'use strict'

var pakoInflate = require('./vendor/pako_inflate.min')

;(function installGodotWeChatRuntime(globalObject) {
  var root = globalObject
  var gameGlobal = root.GameGlobal || (root.GameGlobal = {})
  var wxApi = root.wx
  var bootStart = Date.now()

  function nowPolyfill() {
    return Date.now() - bootStart
  }

  function toArrayBuffer(data) {
    if (data instanceof ArrayBuffer) {
      return data
    }
    if (ArrayBuffer.isView(data)) {
      return data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength)
    }
    if (typeof data === 'string') {
      var encoded
      if (typeof TextEncoder === 'function') {
        encoded = new TextEncoder().encode(data)
      } else {
        var utf8 = unescape(encodeURIComponent(data))
        encoded = new Uint8Array(utf8.length)
        for (var i = 0; i < utf8.length; i += 1) {
          encoded[i] = utf8.charCodeAt(i)
        }
      }
      return encoded.buffer.slice(encoded.byteOffset, encoded.byteOffset + encoded.byteLength)
    }
    throw new Error('Unsupported localFetch payload')
  }

  function normalizePackagePath(filePath) {
    var normalized = String(filePath || '')
      .replace(/^https?:\/\/[^/]+/i, '')
      .replace(/[?#].*$/, '')
      .replace(/^\.?\//, '')
      .replace(/^\/+/, '')
    return normalized
  }

  function getPlatform() {
    try {
      if (!wxApi || typeof wxApi.getSystemInfoSync !== 'function') {
        return ''
      }
      return String(wxApi.getSystemInfoSync().platform || '')
    } catch (_error) {
      return ''
    }
  }

  function shouldBypassWasmRead(filePath) {
    var normalized = normalizePackagePath(filePath)
    return (
      /\.(wasm|wasm\.br)$/i.test(normalized) &&
      typeof root.WebAssembly === 'undefined' &&
      typeof root.WXWebAssembly !== 'undefined'
    )
  }

  function runSequential(tasks) {
    return new Promise(function (resolve, reject) {
      var index = 0
      var lastError = null

      function next() {
        if (index >= tasks.length) {
          reject(lastError || new Error('localFetch failed'))
          return
        }
        var task = tasks[index]
        index += 1
        task().then(resolve).catch(function (error) {
          lastError = error
          next()
        })
      }

      next()
    })
  }

  function makeReadCandidates(filePath) {
    var raw = String(filePath || '')
    if (/^wxfile:\/\//i.test(raw)) {
      return [raw]
    }

    var normalized = normalizePackagePath(raw)
    var candidates = []

    function pushCandidate(path) {
      if (!path) {
        return
      }
      if (candidates.indexOf(path) === -1) {
        candidates.push(path)
      }
    }

    pushCandidate('/' + normalized)
    pushCandidate(normalized)
    return candidates
  }

  function ensureUserDataDir(dirPath) {
    return new Promise(function (resolve, reject) {
      if (!wxApi || typeof wxApi.getFileSystemManager !== 'function') {
        reject(new Error('wx.getFileSystemManager is not available'))
        return
      }
      var fs = wxApi.getFileSystemManager()
      if (!fs) {
        reject(new Error('FileSystemManager is not available'))
        return
      }
      if (typeof fs.mkdir === 'function') {
        fs.mkdir({
          dirPath: dirPath,
          recursive: true,
          success: function success() {
            resolve()
          },
          fail: function fail(error) {
            var message = error && error.errMsg ? error.errMsg : ''
            if (/file already exists/i.test(message)) {
              resolve()
              return
            }
            reject(new Error(message || 'mkdir failed'))
          },
        })
        return
      }
      if (typeof fs.mkdirSync === 'function') {
        try {
          fs.mkdirSync(dirPath, true)
          resolve()
        } catch (error) {
          var text = error && error.message ? error.message : String(error || '')
          if (/file already exists/i.test(text)) {
            resolve()
            return
          }
          reject(error)
        }
        return
      }
      reject(new Error('mkdir is not available'))
    })
  }

  function stagePackagedFileToUserData(filePath) {
    return new Promise(function (resolve, reject) {
      if (!wxApi || typeof wxApi.getFileSystemManager !== 'function') {
        reject(new Error('wx.getFileSystemManager is not available'))
        return
      }
      if (!wxApi.env || !wxApi.env.USER_DATA_PATH) {
        reject(new Error('wx.env.USER_DATA_PATH is not available'))
        return
      }
      var normalized = normalizePackagePath(filePath)
      var buildStamp = String(root.__godotWxBuildStamp || 'unknown').replace(/[^0-9A-Za-z_-]/g, '_')
      var baseDir = wxApi.env.USER_DATA_PATH + '/godot-staged/' + buildStamp
      var stagedPath = baseDir + '/' + normalized.replace(/^\/+/, '')
      var stagedDir = stagedPath.slice(0, stagedPath.lastIndexOf('/'))
      var fs = wxApi.getFileSystemManager()
      if (!fs || typeof fs.copyFile !== 'function') {
        reject(new Error('copyFile is not available'))
        return
      }

      ensureUserDataDir(stagedDir).then(function () {
        fs.copyFile({
          srcPath: makeReadCandidates(filePath)[0],
          destPath: stagedPath,
          success: function success() {
            console.log('[godot-wx] staged code package file', normalized, stagedPath)
            resolve(stagedPath)
          },
          fail: function fail(error) {
            reject(new Error(error && error.errMsg ? error.errMsg : 'copyFile failed'))
          },
        })
      }).catch(reject)
    })
  }

  function readCompressedPackagedFile(filePath) {
    return new Promise(function (resolve, reject) {
      if (!wxApi || typeof wxApi.getFileSystemManager !== 'function') {
        reject(new Error('wx.getFileSystemManager is not available'))
        return
      }
      var fs = wxApi.getFileSystemManager()
      if (!fs || typeof fs.readCompressedFile !== 'function') {
        reject(new Error('readCompressedFile is not available'))
        return
      }

      var candidates = makeReadCandidates(filePath)
      var lastError = null

      function tryRead(index) {
        if (index >= candidates.length) {
          reject(lastError || new Error('readCompressedFile failed'))
          return
        }
        fs.readCompressedFile({
          filePath: candidates[index],
          compressionAlgorithm: 'br',
          success: function success(result) {
            try {
              resolve(toArrayBuffer(result.data))
            } catch (error) {
              reject(error)
            }
          },
          fail: function fail(error) {
            lastError = new Error(error && error.errMsg ? error.errMsg : 'readCompressedFile failed')
            tryRead(index + 1)
          },
        })
      }

      tryRead(0)
    })
  }

  function readPackagedFile(filePath) {
    return new Promise(function (resolve, reject) {
      if (!wxApi || typeof wxApi.getFileSystemManager !== 'function') {
        reject(new Error('wx.getFileSystemManager is not available'))
        return
      }
      var fs = wxApi.getFileSystemManager()
      var candidates = makeReadCandidates(filePath)
      var lastError = null

      function tryRead(index) {
        if (index >= candidates.length) {
          reject(lastError || new Error('readFile failed'))
          return
        }
        fs.readFile({
          filePath: candidates[index],
          success: function success(result) {
            try {
              resolve(toArrayBuffer(result.data))
            } catch (error) {
              reject(error)
            }
          },
          fail: function fail(error) {
            lastError = new Error(error && error.errMsg ? error.errMsg : 'readFile failed')
            tryRead(index + 1)
          },
        })
      }

      tryRead(0)
    })
  }

  function loadPackagedFile(filePath) {
    var normalized = normalizePackagePath(filePath)
    var platform = getPlatform()
    var tasks = []

    function pushTask(task) {
      tasks.push(task)
    }

    function pushCompressedTask() {
      if (/\.br$/i.test(normalized)) {
        pushTask(function () {
          return readCompressedPackagedFile(filePath)
        })
      }
    }

    if (shouldBypassWasmRead(filePath)) {
      console.log('[godot-wx] bypass wasm preload', normalized)
      return Promise.resolve(new ArrayBuffer(0))
    }

    pushCompressedTask()
    pushTask(function () {
      return readPackagedFile(filePath)
    })
    if (platform !== 'devtools' && !/\.br$/i.test(normalized)) {
      pushTask(function () {
        return stagePackagedFileToUserData(filePath).then(function (stagedPath) {
          return readPackagedFile(stagedPath)
        })
      })
    }

    return runSequential(tasks)
  }

  function requestArrayBuffer(url) {
    return new Promise(function (resolve, reject) {
      if (!wxApi || typeof wxApi.request !== 'function') {
        reject(new Error('wx.request is not available'))
        return
      }
      wxApi.request({
        url: url,
        responseType: 'arraybuffer',
        success: function success(result) {
          if (typeof result.statusCode === 'number' && result.statusCode >= 400) {
            reject(new Error('wx.request failed with status ' + result.statusCode + ' for ' + url))
            return
          }
          try {
            resolve(toArrayBuffer(result.data))
          } catch (error) {
            reject(error)
          }
        },
        fail: function fail(error) {
          reject(new Error(error && error.errMsg ? error.errMsg : 'wx.request failed'))
        },
      })
    })
  }

  function isGzipBuffer(buffer) {
    if (!(buffer instanceof ArrayBuffer) || buffer.byteLength < 2) {
      return false
    }
    var view = new Uint8Array(buffer, 0, 2)
    return view[0] === 0x1f && view[1] === 0x8b
  }

  function decodeLocalBuffer(filePath, buffer) {
    if (!isGzipBuffer(buffer)) {
      return buffer
    }
    if (!pakoInflate || typeof pakoInflate.inflate !== 'function') {
      throw new Error('pako.inflate is not available for gzip decode')
    }
    var inflated = pakoInflate.inflate(new Uint8Array(buffer))
    var output = inflated.buffer.slice(
      inflated.byteOffset,
      inflated.byteOffset + inflated.byteLength
    )
    console.log('[godot-wx] decoded gzip asset', normalizePackagePath(filePath), inflated.byteLength)
    return output
  }

  function bindKeyboardMethod(name) {
    if (!root.__globalAdapter) {
      root.__globalAdapter = {}
    }
    if (wxApi && typeof wxApi[name] === 'function') {
      root.__globalAdapter[name] = wxApi[name].bind(wxApi)
      return
    }
    if (typeof root.__globalAdapter[name] !== 'function') {
      root.__globalAdapter[name] = function noop() {}
    }
  }

  var fsUtils = root.fsUtils || {}
  fsUtils.localFetch = function localFetch(filePath) {
    var target = String(filePath || '')
    if (/^https?:\/\/usr\//i.test(target)) {
      return loadPackagedFile(target)
    }
    if (/^[a-zA-Z][a-zA-Z\\d+.-]*:/.test(target)) {
      return requestArrayBuffer(target)
    }
    return loadPackagedFile(target)
  }
  fsUtils.decodeLocalBuffer = function decodeLocalBufferBridge(filePath, buffer) {
    return decodeLocalBuffer(filePath, buffer)
  }

  root.fsUtils = fsUtils
  gameGlobal.fsUtils = fsUtils

  ;[
    'showKeyboard',
    'hideKeyboard',
    'updateKeyboard',
    'onKeyboardInput',
    'onKeyboardConfirm',
    'onKeyboardComplete',
    'offKeyboardInput',
    'offKeyboardConfirm',
    'offKeyboardComplete',
  ].forEach(bindKeyboardMethod)

  root.nowPolyfill = nowPolyfill
  gameGlobal.nowPolyfill = nowPolyfill
  gameGlobal.GODOTSDK = gameGlobal.GODOTSDK || {
    audio: {
      WEBAudio: {
        audioContext: wxApi && typeof wxApi.createWebAudioContext === 'function'
          ? wxApi.createWebAudioContext()
          : null,
      },
    },
  }
})(typeof globalThis !== 'undefined' ? globalThis : this)
