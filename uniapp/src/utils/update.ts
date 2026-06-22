export function checkMiniProgramUpdate() {
  // #ifdef MP-WEIXIN
  const manager = uni.getUpdateManager();
  manager.onUpdateReady(() => {
    uni.showModal({
      title: '新版本已准备好',
      content: '重启小程序即可使用最新版本。',
      showCancel: false,
      success: () => manager.applyUpdate(),
    });
  });
  manager.onUpdateFailed(() => uni.showToast({ title: '更新下载失败，请稍后重试', icon: 'none' }));
  // #endif
}
