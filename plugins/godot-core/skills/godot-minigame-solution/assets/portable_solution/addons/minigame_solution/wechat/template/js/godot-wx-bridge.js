'use strict'

function safeCall(fn, fallback) {
  try {
    const value = fn()
    return value === undefined ? fallback : value
  } catch (_error) {
    return fallback
  }
}

function toJson(value) {
  try {
    return JSON.stringify(value == null ? {} : value)
  } catch (_error) {
    return '{}'
  }
}

function fromJson(text, fallback) {
  if (!text) {
    return fallback
  }
  try {
    return Object.assign({}, fallback, JSON.parse(text))
  } catch (_error) {
    return fallback
  }
}

function normalizeRelativePath(relativePath) {
  return String(relativePath || '')
    .replace(/^user:\/\//, '')
    .replace(/^\/+/, '')
}

function getUserDataPath() {
  return safeCall(() => wx.env.USER_DATA_PATH, '')
}

function resolveUserPath(relativePath) {
  const userDataPath = getUserDataPath()
  const normalized = normalizeRelativePath(relativePath)
  if (!userDataPath) {
    return normalized
  }
  return normalized ? `${userDataPath}/${normalized}` : userDataPath
}

function ensureUserDirectory(filePath) {
  const fs = safeCall(() => wx.getFileSystemManager(), null)
  if (!fs || !filePath) {
    return
  }
  const userRoot = getUserDataPath()
  if (!userRoot) {
    return
  }
  const pieces = filePath.replace(`${userRoot}/`, '').split('/').slice(0, -1)
  let current = userRoot
  pieces.forEach((piece) => {
    current = `${current}/${piece}`
    safeCall(() => fs.mkdirSync(current, true))
  })
}

function readUserFileJson(relativePath) {
  const fs = safeCall(() => wx.getFileSystemManager(), null)
  const fullPath = resolveUserPath(relativePath)
  if (!fs || !fullPath) {
    return toJson({ ok: false, exists: false, error: 'fs_unavailable' })
  }
  try {
    const data = fs.readFileSync(fullPath, 'utf8')
    return toJson({ ok: true, exists: true, data, fullPath })
  } catch (error) {
    const message = String(error && (error.errMsg || error.message || error))
    if (message.includes('no such file') || message.includes('not exists')) {
      return toJson({ ok: true, exists: false, data: '', fullPath })
    }
    return toJson({ ok: false, exists: false, error: message, fullPath })
  }
}

function writeUserFileJson(relativePath, content) {
  const fs = safeCall(() => wx.getFileSystemManager(), null)
  const fullPath = resolveUserPath(relativePath)
  if (!fs || !fullPath) {
    return toJson({ ok: false, error: 'fs_unavailable' })
  }
  try {
    ensureUserDirectory(fullPath)
    fs.writeFileSync(fullPath, String(content || ''), 'utf8')
    return toJson({ ok: true, fullPath })
  } catch (error) {
    return toJson({ ok: false, error: String(error && (error.errMsg || error.message || error)), fullPath })
  }
}

let sharePayload = {
  title: 'Godot Mini-game',
  imageUrl: '',
  query: '',
  path: '',
}

let shareHookInstalled = false
function ensureShareHook() {
  if (shareHookInstalled || typeof wx === 'undefined' || !wx.onShareAppMessage) {
    return
  }
  shareHookInstalled = true
  wx.onShareAppMessage(() => ({
    title: sharePayload.title || 'Godot Mini-game',
    imageUrl: sharePayload.imageUrl || undefined,
    query: sharePayload.query || '',
    path: sharePayload.path || undefined,
  }))
}

const rewardedAds = {}
function getRewardedAd(adUnitId) {
  if (!rewardedAds[adUnitId]) {
    rewardedAds[adUnitId] = wx.createRewardedVideoAd({ adUnitId })
  }
  return rewardedAds[adUnitId]
}

const bridge = {
  isAvailable() {
    return typeof wx !== 'undefined'
  },
  getLaunchOptionsJson() {
    return toJson(safeCall(() => wx.getLaunchOptionsSync(), {}))
  },
  getEnterOptionsJson() {
    return toJson(safeCall(() => wx.getEnterOptionsSync(), {}))
  },
  getSystemInfoJson() {
    return toJson(safeCall(() => wx.getSystemInfoSync(), {}))
  },
  getMenuButtonRectJson() {
    return toJson(safeCall(() => wx.getMenuButtonBoundingClientRect(), {}))
  },
  readUserFileJson(relativePath) {
    return readUserFileJson(relativePath)
  },
  writeUserFileJson(relativePath, content) {
    return writeUserFileJson(relativePath, content)
  },
  onShow(callback) {
    if (typeof wx !== 'undefined' && wx.onShow) {
      wx.onShow((payload) => callback(toJson(payload || {})))
    }
  },
  onHide(callback) {
    if (typeof wx !== 'undefined' && wx.onHide) {
      wx.onHide(() => callback('{}'))
    }
  },
  configureSharePayloadJson(payloadJson) {
    sharePayload = Object.assign({}, sharePayload, fromJson(payloadJson, {}))
    ensureShareHook()
    safeCall(() => wx.showShareMenu && wx.showShareMenu({ menus: ['shareAppMessage', 'shareTimeline'] }))
    return true
  },
  login(callback) {
    if (typeof wx === 'undefined' || !wx.login) {
      callback(toJson({ ok: false, error: 'login_unavailable' }))
      return
    }
    wx.login({
      success(res) {
        callback(toJson({ ok: true, data: res || {}, error: '' }))
      },
      fail(error) {
        callback(toJson({ ok: false, error: String(error && (error.errMsg || error.message || error)) }))
      },
    })
  },
  loadSubpackageJson(name, callback) {
    if (typeof wx === 'undefined' || !wx.loadSubpackage) {
      callback(toJson({ ok: false, name, loaded: false, error: 'load_subpackage_unavailable' }))
      return
    }
    const task = wx.loadSubpackage({
      name,
      success() {
        callback(toJson({ ok: true, name, loaded: true, error: '' }))
      },
      fail(error) {
        callback(toJson({ ok: false, name, loaded: false, error: String(error && (error.errMsg || error.message || error)) }))
      },
    })
    if (task && task.onProgressUpdate) {
      task.onProgressUpdate(() => {})
    }
  },
  showRewardedAdJson(adUnitId, placement, callback) {
    if (typeof wx === 'undefined' || !wx.createRewardedVideoAd) {
      callback(toJson({ ok: false, completed: false, error: 'rewarded_ad_unavailable', placement }))
      return
    }
    let ad
    try {
      ad = getRewardedAd(adUnitId)
    } catch (error) {
      callback(toJson({ ok: false, completed: false, error: String(error && (error.errMsg || error.message || error)), placement }))
      return
    }

    let finished = false
    const cleanup = () => {
      safeCall(() => ad.offLoad && ad.offLoad(onLoad))
      safeCall(() => ad.offClose && ad.offClose(onClose))
      safeCall(() => ad.offError && ad.offError(onError))
    }
    const finish = (payload) => {
      if (finished) {
        return
      }
      finished = true
      cleanup()
      callback(toJson(payload))
    }
    const onLoad = () => {
      try {
        const showResult = ad.show()
        if (showResult && typeof showResult.catch === 'function') {
          showResult.catch(onError)
        }
      } catch (error) {
        onError(error)
      }
    }
    const onClose = (res) => {
      const completed = !!(res && res.isEnded)
      finish({
        ok: completed,
        completed,
        error: completed ? '' : 'closed_early',
        placement,
      })
    }
    const onError = (error) => {
      finish({
        ok: false,
        completed: false,
        error: String(error && (error.errMsg || error.message || error)),
        placement,
      })
    }

    safeCall(() => ad.onLoad && ad.onLoad(onLoad))
    safeCall(() => ad.onClose && ad.onClose(onClose))
    safeCall(() => ad.onError && ad.onError(onError))

    try {
      const loadResult = ad.load()
      if (loadResult && typeof loadResult.then === 'function') {
        loadResult.then(onLoad).catch(onError)
      } else if (!ad.onLoad) {
        onLoad()
      }
    } catch (error) {
      onError(error)
    }
  },
  vibrateShort() {
    safeCall(() => wx.vibrateShort && wx.vibrateShort({ type: 'light' }))
    return true
  },
  trackEventJson(payloadJson) {
    const payload = fromJson(payloadJson, {})
    safeCall(() => console.log('[godotWx.trackEvent]', payload))
    return true
  },
}

globalThis.godotWx = bridge
