type UpdateManifest = {
  enabled: boolean;
  versionName: string;
  versionCode: number;
  title?: string;
  notes?: string;
  force?: boolean;
  packageType?: 'apk' | 'wgt';
  downloadUrl?: string;
};

const MANIFEST_URL = import.meta.env.VITE_APP_UPDATE_URL || 'https://your-domain.example/app-update.json';

export function checkForUpdates() {
  // #ifdef MP-WEIXIN
  const manager = uni.getUpdateManager();
  manager.onUpdateReady(() => {
    uni.showModal({ title: '新版本已准备好', content: '重启小程序即可使用最新版本。', showCancel: false, success: () => manager.applyUpdate() });
  });
  manager.onUpdateFailed(() => uni.showToast({ title: '更新下载失败，请稍后重试', icon: 'none' }));
  // #endif

  // #ifdef APP-PLUS
  uni.request({
    url: MANIFEST_URL,
    success(response) {
      const manifest = response.data as UpdateManifest;
      const current = Number(plus.runtime.versionCode || 0);
      if (!manifest?.enabled || manifest.versionCode <= current || !manifest.downloadUrl) return;
      uni.showModal({
        title: manifest.title || `发现新版本 ${manifest.versionName}`,
        content: manifest.notes || '建议更新后继续使用。',
        showCancel: !manifest.force,
        confirmText: '立即更新',
        success(result) {
          if (!result.confirm) return;
          if (manifest.packageType === 'wgt') installWgt(manifest.downloadUrl!);
          else plus.runtime.openURL(manifest.downloadUrl);
        },
      });
    },
  });
  // #endif
}

function installWgt(url: string) {
  uni.showLoading({ title: '下载更新中' });
  plus.downloader.createDownload(url, {}, (task: any, status: number) => {
    if (status !== 200) {
      uni.hideLoading();
      uni.showToast({ title: '更新包下载失败', icon: 'none' });
      return;
    }
    plus.runtime.install(task.filename, { force: false }, () => {
      uni.hideLoading();
      plus.runtime.restart();
    }, (error: any) => {
      uni.hideLoading();
      uni.showToast({ title: error?.message || '更新安装失败', icon: 'none' });
    });
  }).start();
}
