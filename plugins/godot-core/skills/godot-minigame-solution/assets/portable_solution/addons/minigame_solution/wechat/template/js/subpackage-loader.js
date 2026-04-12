'use strict'

;(function installSubpackageLoader(globalObject) {
  var root = globalObject
  var wxApi = root.wx
  var state = {
    loaded: {},
  }

  function load(name, onProgress, onDone) {
    if (!wxApi || typeof wxApi.loadSubpackage !== 'function') {
      if (typeof onDone === 'function') {
        onDone(new Error('wx.loadSubpackage is not available'))
      }
      return null
    }
    if (state.loaded[name]) {
      if (typeof onDone === 'function') {
        onDone(null, { name: name, loaded: true, cached: true })
      }
      return null
    }
    var task = wxApi.loadSubpackage({
      name: name,
      success: function success() {
        state.loaded[name] = true
        if (typeof onDone === 'function') {
          onDone(null, { name: name, loaded: true })
        }
      },
      fail: function fail(error) {
        if (typeof onDone === 'function') {
          onDone(new Error(error && error.errMsg ? error.errMsg : 'loadSubpackage failed'))
        }
      },
    })
    if (task && typeof task.onProgressUpdate === 'function' && typeof onProgress === 'function') {
      task.onProgressUpdate(onProgress)
    }
    return task
  }

  root.godotWxSubpackages = {
    load: load,
    isLoaded: function isLoaded(name) {
      return !!state.loaded[name]
    },
  }
})(typeof globalThis !== 'undefined' ? globalThis : this)
