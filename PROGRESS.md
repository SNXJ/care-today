# Ralph: CareToday Flutter Mobile

## Iteration 4 - 2026-06-20

### Status

- [x] In Progress
- [ ] Blocked
- [ ] Complete

### What Was Done

- 将平台职责调整为 UniApp 小程序 + Flutter iOS/Android。
- 定义 Flutter 第一版范围、架构和构建验收标准。
- 新建 Flutter Android/iOS 工程，包标识统一为 `com.caretoday.app`。
- 实现 Android Keystore、iOS Keychain 安全 Token 存储。
- 实现登录、空间、五个主页面、统一发布和成员邀请。
- UniApp 已收敛为微信小程序专用，类型检查和构建通过。
- Flutter `analyze` 零问题，API/Widget 测试已编写。

### Blockers

- 当前沙箱禁止测试/Gradle所需的本地 socket，并阻断 Xcode 系统服务，因此原生构建无法在本线程完成。

### Next Step

在正常本机终端执行 `flutter test`、`flutter build apk --debug` 和 `flutter build ios --debug --no-codesign`。

### Files Changed

- `specs/flutter-mobile.md` - Flutter 跨端需求与验收标准。
- `IMPLEMENTATION_PLAN.md` - 新增 Flutter 实施阶段。
