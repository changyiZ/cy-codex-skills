'use strict'

require('./weapp-adapter')
require('./js/inline-assets')
require('./js/fs-sync')
require('./js/subpackage-loader')
require('./js/update-manager')
require('./js/platform-api-probe')
require('./js/godot-wx-bridge')
require('./plugins/screen-adapter')
require('./godot-loader')

;(function bootstrap() {
  var buildStamp = '__BUILD_STAMP__'
  var executable = 'engine/godot'
  var mainPack = 'game.data.bin'
  var engineSubpackage = 'engine'
  var shareTitle = '__SHARE_TITLE__'
  var shareImageUrl = '__SHARE_IMAGE_URL__'
  var loaderConfig = {
    textConfig: {
      firstStartText: '首次加载请稍候',
      downloadingText: ['正在加载资源', '加载中', '请稍候'],
      compilingText: '引擎初始化中',
      initText: '准备进入游戏',
      completeText: '开始游戏',
    },
  }

  console.log('[godot-wx] build stamp ' + buildStamp)

  if (typeof globalThis !== 'undefined') {
    globalThis.__godotWxBuildStamp = buildStamp
    globalThis.godotMinigameRuntime = {
      getPlatformName: function () {
        return 'wechat_minigame'
      },
      getBuildStamp: function () {
        return buildStamp
      },
      getRuntimeJson: function () {
        return ''
      },
    }
  }
  if (typeof GameGlobal !== 'undefined') {
    GameGlobal.__godotWxBuildStamp = buildStamp
    GameGlobal.godotMinigameRuntime = globalThis.godotMinigameRuntime
  }

  if (globalThis.godotWx && typeof globalThis.godotWx.configureSharePayloadJson === 'function') {
    globalThis.godotWx.configureSharePayloadJson(JSON.stringify({
      title: shareTitle,
      imageUrl: shareImageUrl,
    }))
  }

  var activeLoader = null
  if (typeof GodotLoader === 'function') {
    try {
      activeLoader = new GodotLoader(canvas, loaderConfig)
      if (typeof GameGlobal !== 'undefined') {
        GameGlobal.godotLoader = activeLoader
      }
    } catch (error) {
      console.warn('[godot-wx] loader init failed', error)
    }
  }

  function updateLoader(progress, text) {
    if (!activeLoader || typeof activeLoader.updateProgress !== 'function') {
      return
    }
    activeLoader.updateProgress(progress, text)
  }

  function cleanupLoader() {
    if (activeLoader && typeof activeLoader.cleanup === 'function') {
      activeLoader.cleanup()
    }
  }

  function failLoader(error) {
    if (activeLoader && typeof activeLoader.fail === 'function') {
      activeLoader.fail(error)
    } else {
      console.error('[godot-wx] start fail', error)
    }
  }

  function loadEngineRuntime() {
    return new Promise(function (resolve, reject) {
      if (!globalThis.godotWxSubpackages || typeof globalThis.godotWxSubpackages.load !== 'function') {
        try {
          require('./engine/godot')
          resolve()
        } catch (error) {
          reject(error)
        }
        return
      }
      updateLoader(0, '加载引擎子包')
      globalThis.godotWxSubpackages.load(
        engineSubpackage,
        function onProgress(progress) {
          var ratio = progress && typeof progress.progress === 'number'
            ? progress.progress / 100
            : 0
          updateLoader(ratio, '加载引擎子包')
        },
        function onDone(error) {
          if (error) {
            reject(error)
            return
          }
          try {
            require('./engine/godot')
            resolve()
          } catch (requireError) {
            reject(requireError)
          }
        }
      )
    })
  }

  function startEngine() {
    if (typeof Engine !== 'function') {
      throw new Error('Engine is not available')
    }

    // The current WeChat route can start and interact normally even when the
    // built-in Godot mbedTLS module fails PSA initialization. Keep the exact
    // signature here so the warning stays traceable without polluting DevTools
    // error reporting; revisit only if runtime features start depending on
    // Godot-side TLS/Crypto APIs.
    function isNonFatalEngineStderr(args) {
      var text = Array.prototype.slice.call(args).map(function (value) {
        return String(value)
      }).join(' ')
      return (
        text.indexOf('Failed to initialize psa crypto. The mbedTLS modules will not work.') !== -1 ||
        text.indexOf('initialize_mbedtls_module (modules/mbedtls/register_types.cpp:96)') !== -1
      )
    }

    function toArrayBuffer(data) {
      if (data instanceof ArrayBuffer) {
        return data
      }
      if (ArrayBuffer.isView(data)) {
        return data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength)
      }
      throw new Error('Unsupported main pack payload type')
    }

    function decodeBase64Chunk(chunk) {
      if (typeof wx !== 'undefined' && typeof wx.base64ToArrayBuffer === 'function') {
        try {
          return wx.base64ToArrayBuffer(chunk)
        } catch (_error) {}
      }

      var alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
      var table = {}
      for (var i = 0; i < alphabet.length; i += 1) {
        table[alphabet.charAt(i)] = i
      }

      var clean = String(chunk || '').replace(/[^A-Za-z0-9+/=]/g, '')
      var padding = 0
      if (clean.endsWith('==')) {
        padding = 2
      } else if (clean.endsWith('=')) {
        padding = 1
      }
      var outputLength = Math.floor((clean.length * 3) / 4) - padding
      var output = new Uint8Array(outputLength)
      var outIndex = 0

      for (var cursor = 0; cursor < clean.length; cursor += 4) {
        var c1 = table[clean.charAt(cursor)] || 0
        var c2 = table[clean.charAt(cursor + 1)] || 0
        var c3 = clean.charAt(cursor + 2) === '=' ? 0 : (table[clean.charAt(cursor + 2)] || 0)
        var c4 = clean.charAt(cursor + 3) === '=' ? 0 : (table[clean.charAt(cursor + 3)] || 0)
        var triple = (c1 << 18) | (c2 << 12) | (c3 << 6) | c4
        if (outIndex < outputLength) {
          output[outIndex] = (triple >> 16) & 0xff
          outIndex += 1
        }
        if (outIndex < outputLength) {
          output[outIndex] = (triple >> 8) & 0xff
          outIndex += 1
        }
        if (outIndex < outputLength) {
          output[outIndex] = triple & 0xff
          outIndex += 1
        }
      }

      return output.buffer
    }

    function loadInlineMainPackBuffer() {
      var inlineAssets = globalThis.__godotWxInlineAssets || {}
      var chunks = inlineAssets[mainPack]
      if (!Array.isArray(chunks) || chunks.length === 0) {
        return null
      }
      console.log('[godot-wx] inline asset hit', mainPack, 'chunks=' + chunks.length)
      var parts = chunks.map(function (chunk) {
        return new Uint8Array(decodeBase64Chunk(chunk))
      })
      var totalLength = parts.reduce(function (sum, part) {
        return sum + part.byteLength
      }, 0)
      var merged = new Uint8Array(totalLength)
      var offset = 0
      parts.forEach(function (part) {
        merged.set(part, offset)
        offset += part.byteLength
      })
      return merged.buffer
    }

    function loadMainPackBuffer() {
      var inlineMainPack = loadInlineMainPackBuffer()
      if (inlineMainPack) {
        var inlineView = new Uint8Array(inlineMainPack, 0, Math.min(8, inlineMainPack.byteLength))
        console.log('[godot-wx] main pack buffer ready', mainPack, inlineMainPack.byteLength, Array.prototype.slice.call(inlineView))
        if (!inlineMainPack.byteLength) {
          throw new Error('Main pack buffer is empty')
        }
        return Promise.resolve(inlineMainPack)
      }
      var fsUtils = globalThis.fsUtils
      if (!fsUtils || typeof fsUtils.localFetch !== 'function') {
        throw new Error('fsUtils.localFetch is not available for main pack load')
      }
      updateLoader(0, '加载主包')
      return fsUtils.localFetch(mainPack).then(function (buffer) {
        var arrayBuffer = toArrayBuffer(buffer)
        var view = new Uint8Array(arrayBuffer, 0, Math.min(8, arrayBuffer.byteLength))
        console.log('[godot-wx] main pack buffer ready', mainPack, arrayBuffer.byteLength, Array.prototype.slice.call(view))
        if (!arrayBuffer.byteLength) {
          throw new Error('Main pack buffer is empty')
        }
        return arrayBuffer
      })
    }

    function installMainPackAliases(engine, mainPackBuffer) {
      var normalizedMainPack = mainPack.replace(/^\/+/, '')
      var aliases = [
        normalizedMainPack,
        '/' + normalizedMainPack,
        executable + '.pck',
        '/' + executable + '.pck',
      ]
      aliases.forEach(function (aliasPath) {
        engine.copyToFS(aliasPath, mainPackBuffer)
        console.log('[godot-wx] main pack alias installed', aliasPath, mainPackBuffer.byteLength)
      })
    }

    var engine = new Engine({
      canvas: canvas,
      executable: executable,
      unloadAfterInit: true,
      focusCanvas: true,
      experimentalVK: false,
      onProgress: function (current, total) {
        var progress = total > 0 ? current / total : 0
        updateLoader(progress, loaderConfig.textConfig.downloadingText[0])
      },
      onPrint: function () {
        console.log.apply(console, Array.prototype.slice.call(arguments))
      },
      onPrintError: function () {
        if (isNonFatalEngineStderr(arguments)) {
          return
        }
        console.error.apply(console, Array.prototype.slice.call(arguments))
      },
    })

    globalThis.godotWxEngine = engine
    updateLoader(0, loaderConfig.textConfig.compilingText)
    return engine.init(executable).then(function () {
      return loadMainPackBuffer()
    }).then(function (mainPackBuffer) {
      updateLoader(1, '写入主包')
      installMainPackAliases(engine, mainPackBuffer)
      updateLoader(1, loaderConfig.textConfig.initText)
      return engine.start({
        args: ['--main-pack', mainPack],
      })
    }).then(function () {
      cleanupLoader()
      console.log('[godot-wx] engine started')
    })
  }

  loadEngineRuntime().then(startEngine).catch(function (error) {
    failLoader(error)
  })
})()
