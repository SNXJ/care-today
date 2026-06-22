# CareToday UniApp

这是 CareToday 的微信小程序客户端。iOS 和 Android 客户端位于 `../flutter_app/`。

## 开发与验证

```bash
npm install
npm run type-check
npm run build:mp-weixin
```

构建产物：

- 微信小程序：`dist/build/mp-weixin`

## 发布前配置

1. 复制 `.env.example` 为 `.env.local`，设置 API 地址。
2. 在 `src/manifest.json` 的 `mp-weixin.appid` 填入微信小程序 AppID。
3. 在微信公众平台把 API 域名 `https://your-domain.example` 加入 request 合法域名。
4. 使用微信开发者工具导入 `dist/build/mp-weixin`，审核上传。

## 更新机制

微信小程序启动时调用 `uni.getUpdateManager()`；新包在微信后台发布后，客户端下载完成会提示重启应用。

## 当前范围

已实现登录/注册、空间创建与选择、今天、时间线、分享、身体、注意事项、统一发布、成员邀请、隐私边界和小程序更新检查。
