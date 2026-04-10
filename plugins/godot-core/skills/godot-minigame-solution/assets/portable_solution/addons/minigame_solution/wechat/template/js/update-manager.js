'use strict'

if (typeof wx !== 'undefined' && wx.getUpdateManager) {
  const updateManager = wx.getUpdateManager()

  updateManager.onCheckForUpdate(() => {})

  updateManager.onUpdateReady(() => {
    if (!wx.showModal) {
      updateManager.applyUpdate()
      return
    }
    wx.showModal({
      title: '发现新版本',
      content: '新版本已经准备好，是否立即重启应用？',
      success(res) {
        if (res.confirm) {
          updateManager.applyUpdate()
        }
      },
      fail() {
        updateManager.applyUpdate()
      },
    })
  })

  updateManager.onUpdateFailed(() => {})
}
