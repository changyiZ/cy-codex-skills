'use strict'

var messageType = {
  config: 0,
  writeFile: 1,
}

var createSharedArrayBuffer = worker.createSharedArrayBuffer
var getFileSystemManager = worker.getFileSystemManager
var fs = getFileSystemManager ? getFileSystemManager() : null

function compareVersion(v1, v2) {
  return v1
    .split('.')
    .map(function mapVersion(part) { return part.padStart(2, '0') })
    .join('') >= v2
    .split('.')
    .map(function mapVersion(part) { return part.padStart(2, '0') })
    .join('')
}

worker.onMessage(function onMessage(result) {
  var type = result.type
  var payload = result.payload

  if (type === messageType.writeFile) {
    var filePath = payload.filePath
    var data = payload.data
    var isSharedBuffer = payload.isSharedBuffer
    var content = isSharedBuffer ? data.buffer : data

    if (!fs) {
      console.error('getFileSystemManager不存在')
      return
    }

    fs.writeFile({
      filePath: filePath,
      data: content,
      success: function success() {
        worker.postMessage({
          type: messageType.writeFile,
          payload: {
            isok: true,
            filePath: filePath,
          },
        })
      },
      fail: function fail(error) {
        worker.postMessage({
          type: messageType.writeFile,
          payload: {
            isok: false,
            filePath: filePath,
            err: error,
          },
        })
      },
    })
    return
  }

  if (type === messageType.config) {
    var systemInfo = payload.systemInfo
    var platform = String(systemInfo.platform || '').toLowerCase()
    var version = String(systemInfo.version || '0.0.0')
    var isAndroid = platform === 'android'
    var isClientValid = compareVersion(version, '8.0.18')

    worker.postMessage({
      type: messageType.config,
      payload: {
        supportWorkerFs: isAndroid && !!fs && isClientValid,
        supportSharedBuffer: isAndroid && !!createSharedArrayBuffer,
      },
    })
  }
})
