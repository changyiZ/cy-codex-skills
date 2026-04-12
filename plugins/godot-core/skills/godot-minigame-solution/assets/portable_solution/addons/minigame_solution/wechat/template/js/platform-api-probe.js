'use strict'

function safeProbeCall(fn, fallback) {
  try {
    const value = fn()
    return value === undefined ? fallback : value
  } catch (_error) {
    return fallback
  }
}

function probeToJson(value) {
  try {
    return JSON.stringify(value == null ? {} : value)
  } catch (_error) {
    return '{}'
  }
}

function probeFromJson(text, fallback) {
  if (!text) {
    return fallback
  }
  try {
    return Object.assign({}, fallback, JSON.parse(text))
  } catch (_error) {
    return fallback
  }
}

function probeOk(detail) {
  return {
    ok: true,
    skipped: false,
    error: '',
    detail: detail || {},
  }
}

function probeFail(error, detail) {
  return {
    ok: false,
    skipped: false,
    error: String(error || 'probe_failed'),
    detail: detail || {},
  }
}

function probeSkip(reason, detail) {
  return {
    ok: false,
    skipped: true,
    error: String(reason || 'probe_skipped'),
    detail: detail || {},
  }
}

function summarizeProbeResults(results) {
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

function normalizeProbeCalls(plan, defaults) {
  if (!Array.isArray(plan.calls) || plan.calls.length === 0) {
    return defaults.slice()
  }
  return plan.calls
    .map((entry) => String(entry || '').trim().toLowerCase())
    .filter(Boolean)
}

function wantsProbeCall(calls, name) {
  return calls.indexOf(String(name || '').toLowerCase()) !== -1
}

function requestAsync(wxApi, url, timeoutMs) {
  return new Promise((resolve) => {
    if (!url) {
      resolve(probeSkip('request_url_missing'))
      return
    }
    if (!wxApi || typeof wxApi.request !== 'function') {
      resolve(probeSkip('request_unavailable'))
      return
    }
    wxApi.request({
      url,
      method: 'GET',
      timeout: timeoutMs,
      success(result) {
        resolve(probeOk({
          status_code: Number(result && result.statusCode) || 0,
          header_keys: Object.keys((result && result.header) || {}),
        }))
      },
      fail(error) {
        resolve(probeFail(error && (error.errMsg || error.message || error)))
      },
    })
  })
}

function socketAsync(wxApi, url, timeoutMs) {
  return new Promise((resolve) => {
    if (!url) {
      resolve(probeSkip('socket_url_missing'))
      return
    }
    if (!wxApi || typeof wxApi.connectSocket !== 'function') {
      resolve(probeSkip('socket_unavailable'))
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
      const task = wxApi.connectSocket({ url })
      if (!task) {
        finish(probeFail('connect_socket_returned_null'))
        return
      }
      timer = setTimeout(() => {
        safeProbeCall(() => task.close && task.close({ code: 1000, reason: 'probe-timeout' }))
        finish(probeFail('socket_timeout'))
      }, Math.max(250, timeoutMs))
      safeProbeCall(() => task.onOpen && task.onOpen(() => {
        safeProbeCall(() => task.close && task.close({ code: 1000, reason: 'probe-complete' }))
        finish(probeOk({ opened: true }))
      }))
      safeProbeCall(() => task.onError && task.onError((error) => {
        finish(probeFail(error && (error.errMsg || error.message || error)))
      }))
    } catch (error) {
      finish(probeFail(error && (error.errMsg || error.message || error)))
    }
  })
}

;(function installPlatformApiProbe(globalObject) {
  const root = globalObject
  const wxApi = root.wx

  async function runProbe(planJson, callback) {
    const defaults = [
      'base64',
      'update_manager',
      'canvas',
      'image',
      'audio',
      'request',
      'socket',
    ]
    const plan = probeFromJson(planJson, {})
    const calls = normalizeProbeCalls(plan, defaults)
    const allowUI = !!plan.allow_ui
    const timeoutMs = Number(plan.timeout_ms) > 0 ? Number(plan.timeout_ms) : 1500
    const requestUrl = String(plan.request_url || '')
    const socketUrl = String(plan.socket_url || '')
    const modalTitle = String(plan.modal_title || 'Platform API Probe')
    const modalContent = String(plan.modal_content || 'Confirm modal invocation')
    const results = {}

    if (wantsProbeCall(calls, 'base64')) {
      if (!wxApi || typeof wxApi.base64ToArrayBuffer !== 'function') {
        results.base64 = probeSkip('base64_to_array_buffer_unavailable')
      } else {
        try {
          const buffer = wxApi.base64ToArrayBuffer('QQ==')
          results.base64 = probeOk({ byte_length: buffer ? buffer.byteLength || 0 : 0 })
        } catch (error) {
          results.base64 = probeFail(error && (error.errMsg || error.message || error))
        }
      }
    }

    if (wantsProbeCall(calls, 'update_manager')) {
      if (!wxApi || typeof wxApi.getUpdateManager !== 'function') {
        results.update_manager = probeSkip('update_manager_unavailable')
      } else {
        try {
          const manager = wxApi.getUpdateManager()
          safeProbeCall(() => manager.onCheckForUpdate && manager.onCheckForUpdate(() => {}))
          safeProbeCall(() => manager.onUpdateReady && manager.onUpdateReady(() => {}))
          safeProbeCall(() => manager.onUpdateFailed && manager.onUpdateFailed(() => {}))
          results.update_manager = probeOk({
            has_apply_update: !!(manager && typeof manager.applyUpdate === 'function'),
          })
        } catch (error) {
          results.update_manager = probeFail(error && (error.errMsg || error.message || error))
        }
      }
    }

    if (wantsProbeCall(calls, 'modal')) {
      if (!allowUI) {
        results.modal = probeSkip('ui_not_allowed')
      } else if (!wxApi || typeof wxApi.showModal !== 'function') {
        results.modal = probeSkip('show_modal_unavailable')
      } else {
        results.modal = await new Promise((resolve) => {
          wxApi.showModal({
            title: modalTitle,
            content: modalContent,
            showCancel: true,
            success(result) {
              resolve(probeOk({
                confirm: !!(result && result.confirm),
                cancel: !!(result && result.cancel),
              }))
            },
            fail(error) {
              resolve(probeFail(error && (error.errMsg || error.message || error)))
            },
          })
        })
      }
    }

    if (wantsProbeCall(calls, 'canvas')) {
      if (!wxApi || typeof wxApi.createCanvas !== 'function') {
        results.canvas = probeSkip('create_canvas_unavailable')
      } else {
        try {
          const canvas = wxApi.createCanvas()
          results.canvas = probeOk({
            width: Number(canvas && canvas.width) || 0,
            height: Number(canvas && canvas.height) || 0,
          })
        } catch (error) {
          results.canvas = probeFail(error && (error.errMsg || error.message || error))
        }
      }
    }

    if (wantsProbeCall(calls, 'image')) {
      if (!wxApi || typeof wxApi.createImage !== 'function') {
        results.image = probeSkip('create_image_unavailable')
      } else {
        try {
          const image = wxApi.createImage()
          results.image = probeOk({
            has_src: !!(image && Object.prototype.hasOwnProperty.call(image, 'src')),
          })
        } catch (error) {
          results.image = probeFail(error && (error.errMsg || error.message || error))
        }
      }
    }

    if (wantsProbeCall(calls, 'audio')) {
      if (!wxApi || typeof wxApi.createInnerAudioContext !== 'function') {
        results.audio = probeSkip('create_inner_audio_context_unavailable')
      } else {
        try {
          const audio = wxApi.createInnerAudioContext()
          results.audio = probeOk({
            has_play: !!(audio && typeof audio.play === 'function'),
            has_destroy: !!(audio && typeof audio.destroy === 'function'),
          })
          safeProbeCall(() => audio.destroy && audio.destroy())
        } catch (error) {
          results.audio = probeFail(error && (error.errMsg || error.message || error))
        }
      }
    }

    if (wantsProbeCall(calls, 'request')) {
      results.request = await requestAsync(wxApi, requestUrl, timeoutMs)
    }

    if (wantsProbeCall(calls, 'socket')) {
      results.socket = await socketAsync(wxApi, socketUrl, timeoutMs)
    }

    const summary = summarizeProbeResults(results)
    callback(probeToJson({
      ok: summary.failed === 0,
      platform: 'wechat_minigame',
      results,
      summary,
    }))
  }

  root.godotMinigameProbe = {
    runProbeJson(planJson, callback) {
      runProbe(planJson, callback).catch((error) => {
        callback(probeToJson({
          ok: false,
          platform: 'wechat_minigame',
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
