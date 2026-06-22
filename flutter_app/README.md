# CareToday Flutter Mobile

CareToday 的 iOS / Android 客户端。微信小程序继续由 `../uniapp/` 负责。

## 技术结构

- `lib/core`：原生安全 Token 存储通道。
- `lib/data`：REST API 客户端与错误模型。
- `lib/features/session`：登录态、空间与业务数据状态。
- `lib/main.dart`：登录、空间、五个主页面、统一发布和成员页。
- Android Token 使用 Keystore + AES/GCM；iOS Token 使用 Keychain。

## 本地运行

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Android 调试 APK：

```bash
flutter build apk --debug
```

产物位置：`build/app/outputs/flutter-apk/app-debug.apk`。

iOS 无签名编译：

```bash
flutter build ios --debug --no-codesign
```

正式发布时需要配置 Android 长期签名证书，以及 Apple Developer Team、证书和 Provisioning Profile。

## 配置

- API 默认地址：`https://your-domain.example/api`。
- Android Application ID：`com.caretoday.app`。
- iOS Bundle ID：`com.caretoday.app`。
- 版本：`pubspec.yaml` 的 `version` 字段。

