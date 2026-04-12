'use strict'

;(function installScreenAdapter(globalObject) {
  var root = globalObject
  var wxApi = root.wx

  function syncWindowInfo(info) {
    if (!root.window) {
      return
    }
    root.window.innerWidth = info.windowWidth || info.screenWidth || root.window.innerWidth
    root.window.innerHeight = info.windowHeight || info.screenHeight || root.window.innerHeight
  }

  if (!wxApi) {
    return
  }

  if (typeof wxApi.onWindowResize === 'function') {
    wxApi.onWindowResize(syncWindowInfo)
  }

  if (typeof wxApi.onDeviceOrientationChange === 'function') {
    wxApi.onDeviceOrientationChange(function onDeviceOrientationChange() {
      var info = typeof wxApi.getWindowInfo === 'function'
        ? wxApi.getWindowInfo()
        : wxApi.getSystemInfoSync()
      syncWindowInfo(info)
    })
  }
})(typeof globalThis !== 'undefined' ? globalThis : this)
