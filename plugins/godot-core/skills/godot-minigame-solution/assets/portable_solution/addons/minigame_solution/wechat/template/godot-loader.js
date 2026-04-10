'use strict'

;(function installGodotLoader(globalObject) {
  var root = globalObject
  var gameGlobal = root.GameGlobal || (root.GameGlobal = {})
  var wxApi = root.wx

  function GodotLoader(_canvas, config) {
    this.config = config || {}
    this.currentText = (this.config.textConfig && this.config.textConfig.firstStartText) || '加载中'
    this.progress = 0
    this._show(this.currentText)
  }

  GodotLoader.prototype._show = function _show(text) {
    if (wxApi && typeof wxApi.showLoading === 'function') {
      try {
        wxApi.showLoading({
          title: String(text || '加载中').slice(0, 7),
          mask: true,
        })
        return
      } catch (_error) {}
    }
    console.log('[godot-loader]', text)
  }

  GodotLoader.prototype.updateProgress = function updateProgress(progress, text) {
    this.progress = progress
    if (text) {
      this.currentText = text
    }
    this._show(this.currentText)
  }

  GodotLoader.prototype.cleanup = function cleanup() {
    if (wxApi && typeof wxApi.hideLoading === 'function') {
      try {
        wxApi.hideLoading()
      } catch (_error) {}
    }
  }

  GodotLoader.prototype.fail = function fail(error) {
    this.cleanup()
    console.error('[godot-loader] start fail', error)
  }

  root.GodotLoader = GodotLoader
  gameGlobal.GodotLoader = GodotLoader
})(typeof globalThis !== 'undefined' ? globalThis : this)
