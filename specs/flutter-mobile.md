# Flutter iOS / Android 客户端需求与验收标准

## 平台职责

- `uniapp/`：仅负责微信小程序。
- `flutter_app/`：负责 Android 和 iOS 原生应用。
- 两端共同复用现有 Spring Boot REST API，不复制业务后端。

## Flutter 第一版范围

- 手机号或邮箱密码登录、注册、登录态安全持久化、失效退出。
- 创建/选择陪伴空间、加载成员和七类核心数据。
- 五个主页面：今天、时间线、分享、身体、注意。
- 统一发布：分享、日程、身体评分、体温、体重、症状、注意事项、问医生、文本资料。
- 个人页：成员列表、生成邀请链接、隐私与医疗边界、退出登录。
- Android/iOS 使用相同交互和视觉语言，并适配安全区域、软键盘和系统深浅色设置。

## 架构

- `core/`：主题、常量、错误处理、安全存储。
- `data/`：HTTP 客户端、API、JSON 模型。
- `features/session/`：会话状态与启动恢复。
- `features/home/`：五个主视图和统一发布。
- 状态管理采用 `ChangeNotifier` + Provider，避免第一版引入代码生成。
- Token 使用系统安全存储；普通偏好不存医疗数据。

## 暂不包含

- 微信授权登录、推送、系统日历写入。
- 图片/文件上传、评论点赞、AI 医疗问答。
- App Store / Google Play 自动发布。

## 验收标准

1. `dart format --output=none --set-exit-if-changed .` 通过。
2. `flutter analyze` 通过。
3. `flutter test` 通过，至少覆盖版本比较、会话启动和登录页关键状态。
4. `flutter build apk --debug` 成功并产出可安装 APK。
5. `flutter build ios --debug --no-codesign` 成功，证明 iOS 工程可编译。
6. Android 包名和 iOS Bundle ID 均为 `com.caretoday.app`。

