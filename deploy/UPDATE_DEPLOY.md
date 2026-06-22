# 应用内更新 + APK 发布系统 部署说明

本次新增：Android 应用内自动更新、版本管理后端、上传管理页。先走 `your-domain.example/apk` 路径（暂不新建子域名/证书）。

## 组成

| 部分 | 位置 |
|------|------|
| 版本检查接口（公开） | `GET /api/app/version` |
| 发布管理接口（管理员） | `GET/POST/DELETE /api/app/versions` |
| APK 静态分发 | `https://your-domain.example/apk/<file>.apk` |
| 上传管理页 | `https://your-domain.example/manage/` |
| APK 与元数据存储 | docker 卷 `care_today_apk`（后端 `/data/releases`，nginx 只读挂载） |

## 一、服务器部署（ECS, root@<YOUR_SERVER_IP>）

```bash
cd /path/to/support-page          # 项目目录
git pull                          # 拉取本次改动

# 1) 配置管理员账号（能登录上传的邮箱/手机号，逗号分隔）
#    写到 deploy/.env（docker compose 会自动读取）
echo 'ADMIN_ACCOUNTS=admin@example.com' >> deploy/.env
# 可选：APK_BASE_URL 默认 https://your-domain.example/apk，无需改

# 2) 重建并重启后端 + nginx（后端会在容器内重新 mvn package）
cd deploy
docker compose up -d --build backend nginx

# 3) 验证
curl -i https://your-domain.example/api/app/version    # 还没发版时返回 204
```

> `ADMIN_ACCOUNTS` 里的账号必须是已注册的正式账号；上传页用它登录。
> 多个管理员用逗号分隔：`ADMIN_ACCOUNTS=a@x.com,13800000000`。

## 二、发布一个新版本

1. 打开 `https://your-domain.example/manage/`，用管理员账号登录。
2. 填 `versionName`（如 `1.0.1`）、`versionCode`（整数，**必须比上一版大**）、更新说明，选 APK 文件，可勾选「强制更新」。
3. 点「上传发布」。客户端下次启动或在「我的 → 检查更新」时即可收到。

### 客户端 versionCode 怎么定
- App 的当前版本号 = `flutter_app/pubspec.yaml` 里 `version: 1.0.0+N` 的 `+N`（buildNumber）。
- 更新判断逻辑：服务器 `versionCode > 本机 buildNumber` 才提示更新。
- 所以每次发版前：先把 pubspec 的 `+N` 递增，`flutter build apk --release` 出包，上传时 `versionCode` 填同一个 `N`。

## 三、平台行为
- **Android**：弹窗 → 下载（带进度）→ 自动拉起系统安装器。首次需在系统里允许本应用「安装未知应用」。
- **iOS / 其他**：弹窗 → 跳转 `apkUrl`（暂指向下载页；上架 App Store 后改成商店地址即可）。

## 四、回滚 / 删除
- 管理页每个版本有「删除」按钮（同时删除 APK 文件）。
- 删除最新版后，客户端会回落到次新版本作为「最新」。

## 五、迁移到独立子域名 apk.your-domain.example（以后）
1. DNS：`apk.your-domain.example` A 记录 → `<YOUR_SERVER_IP>`。
2. 用 certbot 申请证书，新增 nginx server 块（server_name apk.your-domain.example），把现有 `/apk/`、`/manage/`、`/api/` location 复制过去。
3. 把后端 `APK_BASE_URL` 改为 `https://apk.your-domain.example/apk`，重启后端。
