# Implementation Plan

## In Progress

- [ ] Iteration 5: 在允许本地 socket/Xcode 服务的环境执行测试与原生构建

## Completed

- [x] Iteration 1: 定义跨端需求、验收标准和独立工程边界
- [x] Iteration 1: 搭建 UniApp Vue 3 工程与公共 API/会话层
- [x] Iteration 1: 实现五个主视图、统一发布、个人与更新流程
- [x] Iteration 2: 安装依赖并修复跨端编译差异
- [x] Iteration 2: 类型检查、H5、微信小程序、App 资源构建全部通过
- [x] Iteration 3: 完成本地 H5 启动验证、配置样例和发布文档
- [x] Iteration 4: 明确 UniApp 仅负责小程序，Flutter 负责 iOS / Android
- [x] Iteration 4: 定义 Flutter 范围、架构和构建验收标准
- [x] Iteration 4: 搭建 Flutter Android/iOS 工程和原生安全存储
- [x] Iteration 4: 实现鉴权、空间、五个主页面、统一发布和成员邀请
- [x] Iteration 4: 收敛 UniApp 为微信小程序专用并验证构建
- [x] Iteration 5: Flutter 静态分析零问题并补充 API/Widget 测试

## Backlog

- [ ] Flutter 测试、Android APK 与 iOS 无签名构建（当前沙箱禁止本地 socket/Xcode 服务）
- [ ] 微信授权登录与订阅消息（需平台资质）
- [ ] 图片/文件上传与私有对象存储
