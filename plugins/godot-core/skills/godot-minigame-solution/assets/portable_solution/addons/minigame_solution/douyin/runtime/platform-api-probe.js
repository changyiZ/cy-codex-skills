'use strict'

function ttProbeToJson(value) {
  try {
    return JSON.stringify(value == null ? {} : value)
  } catch (_error) {
    return '{}'
  }
}

function ttProbeFromJson(text, fallback) {
  if (!text) {
    return fallback
  }
  try {
    return Object.assign({}, fallback, JSON.parse(text))
  } catch (_error) {
    return fallback
  }
}

function ttProbeOk(detail) {
  return {
    ok: true,
    skipped: false,
    error: '',
    detail: detail || {},
  }
}

function ttProbeFail(error, detail) {
  return {
    ok: false,
    skipped: false,
    error: String(error || 'probe_failed'),
    detail: detail || {},
  }
}

function ttProbeSkip(reason, detail) {
  return {
    ok: false,
    skipped: true,
    error: String(reason || 'probe_skipped'),
    detail: detail || {},
  }
}

function ttProbeSummary(results) {
  const summary = {
    passed: 0,
    failed: 0,
    skipped: 0,
  }
  Object.keys(results || {}).forEach((key) => {
    const entry = results[key] || {}
    if (entry.ok) {
      summary.passed += 1
    } else if (entry.skipped) {
      summary.skipped += 1
    } else {
      summary.failed += 1
    }
  })
  return summary
}

function ttNormalizeCalls(plan, defaults) {
  if (!Array.isArray(plan.calls) || plan.calls.length === 0) {
    return defaults.slice()
  }
  return plan.calls
    .map((entry) => String(entry || '').trim().toLowerCase())
    .filter(Boolean)
}

function ttWantsCall(calls, name) {
  return calls.indexOf(String(name || '').toLowerCase()) !== -1
}

function ttSafeCall(fn, fallback) {
  try {
    const value = fn()
    return value === undefined ? fallback : value
  } catch (_error) {
    return fallback
  }
}

function ttRequestAsync(ttApi, url, timeoutMs) {
  return new Promise((resolve) => {
    if (!url) {
      resolve(ttProbeSkip('request_url_missing'))
      return
    }
    if (!ttApi || typeof ttApi.request !== 'function') {
      resolve(ttProbeSkip('request_unavailable'))
      return
    }
    ttApi.request({
      url,
      method: 'GET',
      timeout: timeoutMs,
      success(result) {
        resolve(ttProbeOk({
          status_code: Number(result && result.statusCode) || 0,
          header_keys: Object.keys((result && result.header) || {}),
        }))
      },
      fail(error) {
        resolve(ttProbeFail(error && (error.errMsg || error.message || error)))
      },
    })
  })
}

function ttSocketAsync(ttApi, url, timeoutMs) {
  return new Promise((resolve) => {
    if (!url) {
      resolve(ttProbeSkip('socket_url_missing'))
      return
    }
    if (!ttApi || typeof ttApi.connectSocket !== 'function') {
      resolve(ttProbeSkip('socket_unavailable'))
      return
    }
    let settled = false
    let timer = null
    function finish(payload) {
      if (settled) {
        return
      }
      settled = true
      if (timer) {
        clearTimeout(timer)
      }
      resolve(payload)
    }
    try {
      const task = ttApi.connectSocket({ url })
      if (!task) {
        finish(ttProbeFail('connect_socket_returned_null'))
        return
      }
      timer = setTimeout(() => {
        ttSafeCall(() => task.close && task.close({ code: 1000, reason: 'probe-timeout' }))
        finish(ttProbeFail('socket_timeout'))
      }, Math.max(250, timeoutMs))
      ttSafeCall(() => task.onOpen && task.onOpen(() => {
        ttSafeCall(() => task.close && task.close({ code: 1000, reason: 'probe-complete' }))
        finish(ttProbeOk({ opened: true }))
      }))
      ttSafeCall(() => task.onError && task.onError((error) => {
        finish(ttProbeFail(error && (error.errMsg || error.message || error)))
      }))
    } catch (error) {
      finish(ttProbeFail(error && (error.errMsg || error.message || error)))
    }
  })
}

function ttKeyboardAsync(ttApi) {
  return new Promise((resolve) => {
    if (!ttApi || typeof ttApi.showKeyboard !== 'function') {
      resolve(ttProbeSkip('show_keyboard_unavailable'))
      return
    }
    const onInput = function () {}
    const onConfirm = function () {}
    const onComplete = function () {}
    ttSafeCall(() => ttApi.onKeyboardInput && ttApi.onKeyboardInput(onInput))
    ttSafeCall(() => ttApi.onKeyboardConfirm && ttApi.onKeyboardConfirm(onConfirm))
    ttSafeCall(() => ttApi.onKeyboardComplete && ttApi.onKeyboardComplete(onComplete))
    ttApi.showKeyboard({
      defaultValue: 'probe',
      maxLength: 16,
      multiple: false,
      confirmHold: false,
      confirmType: 'done',
      success() {
        if (typeof ttApi.hideKeyboard === 'function') {
          ttApi.hideKeyboard({
            success() {
              ttSafeCall(() => ttApi.offKeyboardInput && ttApi.offKeyboardInput(onInput))
              ttSafeCall(() => ttApi.offKeyboardConfirm && ttApi.offKeyboardConfirm(onConfirm))
              ttSafeCall(() => ttApi.offKeyboardComplete && ttApi.offKeyboardComplete(onComplete))
              resolve(ttProbeOk({ shown: true, hidden: true }))
            },
            fail(error) {
              resolve(ttProbeFail(error && (error.errMsg || error.message || error)))
            },
          })
          return
        }
        resolve(ttProbeOk({ shown: true, hidden: false }))
      },
      fail(error) {
        resolve(ttProbeFail(error && (error.errMsg || error.message || error)))
      },
    })
  })
}

;(function installDouyinPlatformProbe(globalObject) {
  const ttApi = globalObject.tt

  async function runProbe(planJson, callback) {
    const defaults = [
      'env_info',
      'canvas',
      'file_system',
      'storage',
      'audio',
      'buffer',
      'stark_api',
      'request',
      'socket',
    ]
    const plan = ttProbeFromJson(planJson, {})
    const calls = ttNormalizeCalls(plan, defaults)
    const allowUI = !!plan.allow_ui
    const timeoutMs = Number(plan.timeout_ms) > 0 ? Number(plan.timeout_ms) : 1500
    const requestUrl = String(plan.request_url || '')
    const socketUrl = String(plan.socket_url || '')
    const storageKey = String(plan.storage_key || '__godot_platform_api_probe')
    const results = {}

    if (ttWantsCall(calls, 'env_info')) {
      if (!ttApi || typeof ttApi.getEnvInfoSync !== 'function' || typeof ttApi.getSystemInfoSync !== 'function') {
        results.env_info = ttProbeSkip('env_info_unavailable')
      } else {
        try {
          const envInfo = ttApi.getEnvInfoSync()
          const systemInfo = ttApi.getSystemInfoSync()
          results.env_info = ttProbeOk({
            host_version: String((envInfo && envInfo.version) || ''),
            sdk_version: String((systemInfo && systemInfo.SDKVersion) || ''),
          })
        } catch (error) {
          results.env_info = ttProbeFail(error && (error.errMsg || error.message || error))
        }
      }
    }

    if (ttWantsCall(calls, 'canvas')) {
      if (!ttApi || typeof ttApi.createCanvas !== 'function' || typeof ttApi.getSystemInfoSync !== 'function') {
        results.canvas = ttProbeSkip('create_canvas_unavailable')
      } else {
        try {
          const systemInfo = ttApi.getSystemInfoSync()
          const canvas = ttApi.createCanvas()
          results.canvas = ttProbeOk({
            width: Number(canvas && canvas.width) || 0,
            height: Number(canvas && canvas.height) || 0,
            window_width: Number(systemInfo && (systemInfo.windowWidth || systemInfo.screenWidth)) || 0,
            window_height: Number(systemInfo && (systemInfo.windowHeight || systemInfo.screenHeight)) || 0,
          })
        } catch (error) {
          results.canvas = ttProbeFail(error && (error.errMsg || error.message || error))
        }
      }
    }

    if (ttWantsCall(calls, 'file_system')) {
      if (!ttApi || typeof ttApi.getFileSystemManager !== 'function') {
        results.file_system = ttProbeSkip('file_system_unavailable')
      } else {
        try {
          const fs = ttApi.getFileSystemManager()
          results.file_system = ttProbeOk({
            has_read_file: !!(fs && typeof fs.readFile === 'function'),
            has_write_file: !!(fs && typeof fs.writeFile === 'function'),
          })
        } catch (error) {
          results.file_system = ttProbeFail(error && (error.errMsg || error.message || error))
        }
      }
    }

    if (ttWantsCall(calls, 'storage')) {
      if (!ttApi || typeof ttApi.setStorageSync !== 'function' || typeof ttApi.getStorageSync !== 'function') {
        results.storage = ttProbeSkip('storage_unavailable')
      } else {
        try {
          const payload = JSON.stringify({ timestamp: Date.now() })
          ttApi.setStorageSync(storageKey, payload)
          const value = ttApi.getStorageSync(storageKey)
          ttSafeCall(() => ttApi.removeStorageSync && ttApi.removeStorageSync(storageKey))
          results.storage = ttProbeOk({
            key: storageKey,
            roundtrip: String(value || '') === payload,
          })
        } catch (error) {
          results.storage = ttProbeFail(error && (error.errMsg || error.message || error))
        }
      }
    }

    if (ttWantsCall(calls, 'audio')) {
      if (!ttApi || typeof ttApi.getAudioContext !== 'function') {
        results.audio = ttProbeSkip('audio_context_unavailable')
      } else {
        try {
          const context = ttApi.getAudioContext()
          results.audio = ttProbeOk({
            has_state: !!(context && Object.prototype.hasOwnProperty.call(context, 'state')),
          })
        } catch (error) {
          results.audio = ttProbeFail(error && (error.errMsg || error.message || error))
        }
      }
    }

    if (ttWantsCall(calls, 'buffer')) {
      if (!ttApi || typeof ttApi.createBuffer !== 'function') {
        results.buffer = ttProbeSkip('create_buffer_unavailable')
      } else {
        try {
          const buffer = ttApi.createBuffer()
          results.buffer = ttProbeOk({
            has_to_string: !!(buffer && typeof buffer.toString === 'function'),
          })
        } catch (error) {
          results.buffer = ttProbeFail(error && (error.errMsg || error.message || error))
        }
      }
    }

    if (ttWantsCall(calls, 'stark_api')) {
      if (!ttApi || typeof ttApi.getStarkInnerAPI !== 'function') {
        results.stark_api = ttProbeSkip('stark_inner_api_unavailable')
      } else {
        try {
          const starkApi = ttApi.getStarkInnerAPI()
          results.stark_api = ttProbeOk({
            available: !!starkApi,
          })
        } catch (error) {
          results.stark_api = ttProbeFail(error && (error.errMsg || error.message || error))
        }
      }
    }

    if (ttWantsCall(calls, 'request')) {
      results.request = await ttRequestAsync(ttApi, requestUrl, timeoutMs)
    }

    if (ttWantsCall(calls, 'socket')) {
      results.socket = await ttSocketAsync(ttApi, socketUrl, timeoutMs)
    }

    if (ttWantsCall(calls, 'keyboard')) {
      if (!allowUI) {
        results.keyboard = ttProbeSkip('ui_not_allowed')
      } else {
        results.keyboard = await ttKeyboardAsync(ttApi)
      }
    }

    const summary = ttProbeSummary(results)
    callback(ttProbeToJson({
      ok: summary.failed === 0,
      platform: 'douyin_minigame',
      results,
      summary,
    }))
  }

  globalObject.godotMinigameProbe = {
    runProbeJson(planJson, callback) {
      runProbe(planJson, callback).catch((error) => {
        callback(ttProbeToJson({
          ok: false,
          platform: 'douyin_minigame',
          error: String(error && (error.errMsg || error.message || error)),
          results: {},
          summary: {
            passed: 0,
            failed: 1,
            skipped: 0,
          },
        }))
      })
    },
  }
})(typeof globalThis !== 'undefined' ? globalThis : this)
