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

---

# 多 Agent 协作底座(Claude + Codex 通用)

> 引擎:**复发的 bug / 低效 → 写成规则进本文件 → 再进互评 checklist**。约定落到这里,Codex 才看得到,不再重复踩坑。
> care-today 是一仓多栈:web(Vite/JS,源码 `src/`)· `uniapp/`(uni-app)· `flutter_app/`(Flutter)· `backend/`(Java/Maven)。构建命令见上方各节。

## 分工(Claude ↔ Codex)
| 任务 | 主导 |
|---|---|
| 跨文件推理、需求/架构判断、判断题、不确定的业务规则 | **Claude(Opus)** |
| 规格明确的机械活(批量改、重命名、codegen 产物、样板、测试脚手架、按 spec 实现单件) | **Codex** |

顺序:Claude 出 spec/判定链 → Codex 落地 → 另一端互审。**同一文件/工单不要两端同时改**;并行用 `git worktree`。
交接 spec 模板:`目标文件 / 改动(精确到行为) / 不要碰 / 验收(可跑命令+边界态) / 参考`。

## 互为评审
一端实现产出 diff → **另一端独立**逐条过 → 报问题 → 实现方修。清单(踩到新坑就往里加):
- [ ] 边界态走过(空 / 半填充 / 0 / 超长)?
- [ ] 本栈 gotcha(见下)都规避?
- [ ] 复用检查做了(见下)?有没有重造已有组件?
- [ ] 没碰 user-owned 的 Web/backend(见 Backpressure)、没提交密钥?

## 高频 gotcha(踩一个记一个,现为空)
- _（暂无;每修一个反复出现的坑就补一行:现象 + 正确写法）_

## 复用强制门(写新组件前必过)
查 → 列候选 2-3 个 → 说不清为何不复用就**必须复用/扩展**。各子项目代码图谱(本地 AST,0-token,不入库):
- web:`cd src && ~/.local/bin/graphify query "现有的 X"`
- uniapp:`cd uniapp/src && ~/.local/bin/graphify query "现有的 X"`
- flutter:`cd flutter_app/lib && ~/.local/bin/graphify query "现有的 X"`
- backend:`cd backend && ~/.local/bin/graphify query "现有的 X"`
- 刷新(改完代码后):在对应目录内 `~/.local/bin/graphify update . --no-cluster`。

> 方法学与模板:`~/.claude/agent-kit/`。本文件入库共享;`graphify-out/`、`.agent-tools/` 本地忽略不提交。
