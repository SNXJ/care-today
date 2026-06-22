# CareToday

CareToday（陪你一起过今天）是一个面向患者、家人和朋友的陪伴支持应用，覆盖 **Web、Android / iOS（Flutter）、微信小程序** 三端，配套 Spring Boot 后端、应用内自动更新与扫码下载页。它不提供医疗诊断、治疗建议或用药判断，而是帮助一个家庭把复诊安排、身体记录、问医生清单、帮忙任务和陪伴留言整理在同一个空间里。

项目地址：[SNXJ/care-today](https://github.com/SNXJ/care-today.git)

## 项目定位

很多治疗过程里的压力不只来自疾病本身，也来自大量需要记住和协调的小事：什么时候复诊、报告放在哪里、想问医生什么、今天身体哪里不舒服、家人朋友能具体帮什么。

CareToday 希望把这些事变得更清楚一点：

- 患者不用一个人记住所有事情。
- 家人朋友可以把关心变成具体行动。
- 复诊前可以更快整理问题、症状和资料。
- 页面始终保持医疗边界，不替代医生意见。

## 下载与安装

- 扫码 / 打开下载页：**https://your-domain.example/download/**
- Android：在下载页点「下载 APK」直接安装；装好后 App 会**自动检查更新**（在「我的 → 检查更新」也可手动检查），有新版会弹窗下载并拉起安装。
- iPhone / iPad：暂未上架，敬请期待。
- 发版管理页（管理员）：**https://your-domain.example/manage/**，登录后上传新 APK、管理版本号。

## 界面预览

应用主界面 · 今天页（日程、下次复诊倒计时、身体记录、问医生、注意事项）：

| 桌面 | 移动 |
| --- | --- |
| ![应用主界面桌面](design-preview/preview.png) | ![应用主界面移动](design-preview/preview-mobile.png) |

App 下载页（线上实拍，扫码即可安装）：

| 桌面 | 手机 |
| --- | --- |
| ![下载页桌面](docs/screenshots/download-desktop.png) | ![下载页手机](docs/screenshots/download-mobile.png) |

登录与发版管理页（线上实拍）：

| Web 登录 | 发版管理 |
| --- | --- |
| ![Web 登录](docs/screenshots/web-login-desktop.png) | ![发版管理页](docs/screenshots/manage-login.png) |

> Flutter App 真机各页面（时间线连接线、身体趋势图、发布器弹层等）截图可放入 `docs/screenshots/` 后在此处补充。

## 当前状态

当前仓库已包含 Vue 3 + Vite Web、Flutter iOS/Android 客户端、UniApp 微信小程序、Spring Boot 后端 API、MySQL schema 和设计风格标准预览：

- `index.html`：Vue 应用入口
- `flutter_app/`：iOS 和 Android 原生客户端
- `uniapp/`：微信小程序客户端
- `backend/`：Spring Boot 3 Java 后端
- `backend/src/main/resources/db/migration/V1__init.sql`：Flyway 数据库迁移
- `backend/src/main/java/com/caretoday/api/release/`：App 版本检查与发布接口
- `deploy/docker-compose.yml`：MySQL、后端、Nginx 部署骨架
- `deploy/apk-admin/`：APK 上传管理页（`/manage/`）
- `deploy/download/`：扫码下载页（`/download/`）
- `deploy/UPDATE_DEPLOY.md`：应用内更新系统部署说明
- `design-preview/index.html`：设计风格标准页面
- `docs/screenshots/`：线上实拍截图（下载页、Web 应用、管理页）

后端已实现注册/登录、JWT 鉴权、空间成员权限校验、核心业务接口持久化、编辑/删除、成员退出/移除、账号删除、审计日志写入，以及 **App 版本管理与发布接口**。前端已接入基础 API：登录/注册、创建空间、加载空间数据，以及添加、编辑、删除日程、身体记录、问医生问题、帮忙任务、留言、资料和成员邀请。Flutter Android 端已实现**应用内自动更新**（下载 + 安装）并已配置**正式签名打包**；线上已发布 v1.0.0，可在下载页扫码安装。

## 设计风格标准

设计规范相关预览统一放在 `design-preview/` 目录，可直接作为视觉和前端实现参考。`design-preview/index.html` 把 `docs/design-style-guide.md` 中的规范转成可浏览页面，重点包括：

- 视觉方向：温柔纸面 + 轻量信息面板
- 色彩 token：基础色、功能色和使用边界
- 排版规则：标题 serif、正文 sans、字号层级和行高
- 布局规则：桌面左侧导航 + 主内容网格，移动端单列和底部导航预留
- 组件规则：卡片、按钮、标签、表单、Toast
- 文案规则：推荐表达、避免表达和医疗边界提示

## 功能规划

第一版计划支持：

- 登录与账号
- 创建陪伴空间
- 邀请家人/朋友加入空间
- 成员和权限管理
- 日历与复诊安排
- 身体状态记录
- 问医生清单
- 帮忙任务创建与认领
- 留言
- 资料/医嘱文本整理
- 隐私说明与免责声明

暂不支持：

- 在线问诊
- AI 医疗诊断
- 治疗方案推荐
- 用药判断
- 病情预测
- 商业药品、保险、医院推荐

## 技术规划

第一版当前技术栈：

- Frontend: Vue 3 + Vite
- Backend: Spring Boot 3 + Java 17
- Database: MySQL 8 + Flyway
- Auth: JWT + BCrypt
- Deploy: Nginx + HTTPS + Docker Compose

移动客户端当前已实现：

- Flutter iOS / Android 工程、原生安全 Token 存储和核心业务页面
- UniApp 微信小程序构建与平台更新检查

后续可考虑：

- 微信登录
- 用药或复诊提醒
- 文件上传与私有存储
- 资料导出
- 更细粒度权限

## 本地预览

设计风格标准页面可以直接打开：

```bash
open design-preview/index.html
```

预览 Vue 原型源码可安装依赖：

```bash
npm install
```

启动本地开发服务器：

```bash
npm run dev
```

然后访问：

```text
http://localhost:5173
```

后端本地构建：

```bash
cd backend
mvn clean package
```

后端运行需要 MySQL 8。配置示例见：

```text
backend/.env.example
```

后端 API 基础地址：

```text
http://localhost:3000/api
```

当前机器如果没有 Docker Compose 插件，可以直接运行：

```bash
./deploy/docker-run.sh
```

部署后访问：

```text
http://localhost:8080
https://localhost:8443
```

`deploy/docker-run.sh` 会为本地验证生成自签名证书到 `deploy/certs/`。浏览器首次访问 HTTPS 可能需要手动信任本地证书；正式生产环境应替换为有效域名证书。

## 移动端客户端

Flutter iOS / Android：

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```

UniApp 微信小程序：

```bash
cd uniapp
npm install
npm run type-check
npm run build:mp-weixin
```

详细配置见 `flutter_app/README.md` 和 `uniapp/README.md`。微信小程序正式发布需要小程序 AppID 和服务器域名白名单；Flutter 正式发布需要 Android/Apple 签名材料。

## 应用内更新与发布

Android 端内置自动更新；APK 托管、版本管理、上传与扫码下载都在自己的服务器上完成，部署细节见 `deploy/UPDATE_DEPLOY.md`。

- 版本检查（公开）：`GET /api/app/version`，返回最新版本与 APK 地址；无版本时 204。
- 发布管理（管理员，白名单账号）：`GET/POST/DELETE /api/app/versions`，APK 与 `releases.json` 存于服务器卷，Nginx 静态分发到 `/apk/`。
- 上传管理页：`/manage/`（`deploy/apk-admin/`，复用账号登录 + 管理员白名单 `ADMIN_ACCOUNTS`）。
- 扫码下载页：`/download/`（`deploy/download/`，含二维码，自动展示最新版本）。
- 客户端行为：Android 弹窗 → 带进度下载 → 拉起系统安装器（需 `REQUEST_INSTALL_PACKAGES`）；iOS/其他跳转下载页；支持「强制更新」。

发新版流程：递增 `flutter_app/pubspec.yaml` 的 `version: x.y.z+N` → `flutter build apk --release --split-per-abi`（正式签名见 `flutter_app/android/key.properties`，密钥务必离线备份）→ 在 `/manage/` 上传 `app-arm64-v8a-release.apk`，`versionCode` 填 `N`。已安装用户下次检查即可收到。

## 数据从哪里添加

当前数据有两个入口：

- Web 页面添加：登录后先创建陪伴空间，再在页面里添加、编辑或删除日程、身体记录、问医生问题、帮忙任务、留言、资料和成员邀请。成员邀请会生成本地邀请链接，受邀人登录后自动加入。前端会调用 `/api`，数据写入 MySQL。
- API 添加：可以直接调用 Spring Boot 后端接口，例如 `POST /api/auth/register`、`POST /api/spaces`、`POST/PATCH/DELETE /api/spaces/{spaceId}/events`。除注册和登录外，请求需要带 `Authorization: Bearer <token>`。

本地开发时，前端默认请求同源 `/api`。如果后端单独运行在 `http://localhost:3000`，可以配置：

```bash
VITE_API_BASE=http://localhost:3000/api npm run dev
```

生产部署时由 Nginx 把 `/api` 反向代理到后端。

## 医疗边界

CareToday 仅用于生活陪伴、就诊整理和家庭协作。

本项目不提供医疗诊断、治疗建议或用药判断。涉及治疗方案、用药调整和症状处理，请以主治医生或医院意见为准。如出现明显不适、症状加重或紧急情况，请及时联系医生、医院或当地急救服务。

## 隐私与安全

项目会涉及医疗健康相关的敏感个人信息。正式上线版本必须至少满足：

- 全站 HTTPS
- 后端接口鉴权
- 空间数据按成员权限隔离
- 密码加密存储
- 敏感操作记录审计日志
- 用户可退出空间或删除账号
- 不在前端暴露服务端密钥
- 不把病情数据写入公开日志

## 目录

```text
care-today/
  index.html                Vue 应用入口
  backend/                  Spring Boot 3 后端 API
  flutter_app/              Flutter iOS、Android 客户端
  uniapp/                   UniApp 微信小程序客户端
  specs/                    跨端需求与验收标准
  IMPLEMENTATION_PLAN.md    实施进度与门禁状态
  deploy/                   Docker Compose、Nginx、备份脚本
  deploy/apk-admin/         APK 上传管理页（/manage/）
  deploy/download/          扫码下载页（/download/）
  deploy/UPDATE_DEPLOY.md   应用内更新系统部署说明
  患者陪伴需求文档.md        产品需求文档
  README.md                 项目说明
  docs/design-style-guide.md 设计风格规范文档
  docs/screenshots/         线上实拍截图
  design-preview/index.html 设计风格标准页面
  design-preview/preview.png Web 原型桌面端截图
  design-preview/preview-mobile.png Web 原型移动端截图
```


## License

只要能帮助病患减轻一部分疼痛，得到陪伴和帮助，减轻负担。随意......
