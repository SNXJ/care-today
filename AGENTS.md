# Project Operations

## Existing Web

- Install: `npm install`
- Build: `npm run build`

## UniApp

- Install: `cd uniapp && npm install`
- WeChat build: `npm run build:mp-weixin`
- Type check: `npm run type-check`

## Flutter Mobile

- Dependencies: `cd flutter_app && flutter pub get`
- Format: `dart format --output=none --set-exit-if-changed .`
- Analyze: `flutter analyze`
- Test: `flutter test`
- Android APK: `flutter build apk --debug`
- iOS compile: `flutter build ios --debug --no-codesign`

## Backpressure

- Keep UniApp work inside `uniapp/`; existing Web/backend changes may be user-owned.
- Type check and all three builds must pass before completion.
- Production WeChat upload requires a mini-program AppID and platform domain allowlist.
- Flutter production release requires Android signing and Apple Developer credentials.
