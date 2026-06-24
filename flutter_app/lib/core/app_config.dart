/// 站点根地址。构建时通过 `--dart-define=CARE_ORIGIN=https://你的域名` 注入；
/// 不注入时使用占位符默认值（源码中不内嵌真实域名）。
const String careOrigin = String.fromEnvironment(
  'CARE_ORIGIN',
  defaultValue: 'https://your-domain.example',
);

/// 后端 API 基址。
const String careApiBase = '$careOrigin/api';
