# CareToday UniApp

这是 CareToday 的跨端客户端，复用仓库现有 Spring Boot API，可构建 H5、微信小程序和 App 资源。

## 开发与验证

```bash
npm install
npm run type-check
npm run dev:h5
npm run build:h5
npm run build:mp-weixin
npm run build:app
```

构建产物：

- H5：`dist/build/h5`
- 微信小程序：`dist/build/mp-weixin`
- App 资源：`dist/build/app`

## 发布前配置

1. 复制 `.env.example` 为 `.env.local`，按环境设置 API 和更新清单地址。
2. 在 `src/manifest.json` 填入真实 DCloud AppID；Android/iOS 正式包需在 HBuilderX 配置证书和包名。
3. 在 `src/manifest.json` 的 `mp-weixin.appid` 填入微信小程序 AppID。
4. 在微信公众平台把 API 域名 `https://your-domain.example` 加入 request 合法域名。
5. 使用微信开发者工具导入 `dist/build/mp-weixin`，审核上传。
6. 使用 HBuilderX 导入本目录或 `dist/build/app`，云打包/本地打包生成 APK、AAB 或 IPA。

## 更新机制

- 微信小程序：启动时调用 `uni.getUpdateManager()`；新包在微信后台发布后，客户端下载完成会提示重启应用。
- App：启动时读取 `VITE_APP_UPDATE_URL` 指向的 JSON。版本号高于本地时，可打开 APK 地址，或下载并安装 WGT 热更新包。
- H5：继续由现有 Nginx/静态文件部署更新，不弹 App 更新提示。

版本清单示例位于仓库根目录 `public/app-update.json`。发布新 App 时：

1. 同步提高 `src/manifest.json` 的 `versionName` 和 `versionCode`。
2. 上传 APK/WGT 到 HTTPS 地址。
3. 更新 `public/app-update.json` 的版本、说明、包类型和下载地址。
4. 先发布安装包，再发布版本清单，避免客户端拿到无效地址。

`enabled` 可作为总开关；`force` 仅应用于确有兼容或安全风险的版本。WGT 只能更新前端资源，新增原生模块或权限时必须发布完整安装包。

## 当前范围

已实现登录/注册、空间创建与选择、今天、时间线、分享、身体、注意事项、统一发布、成员邀请、隐私边界和跨端更新检查。微信授权登录、订阅消息、图片/文件上传和系统级提醒不在第一版范围。
