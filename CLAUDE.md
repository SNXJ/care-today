# care-today — 患者陪伴支持页

> 本文件供 Claude、Codex 及所有 AI 编码助手使用。每次改动请同步更新相关章节。

## 项目概述

患者陪伴 Web 应用，帮助家属/陪护人员管理日程、记录症状、沟通协作、查阅就医资料。
设计风格：温暖米色系 + 手写质感，目标用户为非技术背景的家庭照护者。

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端框架 | Vue 3（Composition API，`<script setup>`） |
| 构建工具 | Vite 5 |
| 样式 | 纯 CSS（`src/styles.css` 全局，无 CSS 框架） |
| 后端 | Java / Spring Boot（`backend/` 目录） |
| 构建后端 | Maven（`backend/pom.xml`） |
| 数据存储 | SQLite / H2（`backend/database/`） |

## 目录结构

```
support-page/
├── src/
│   ├── App.vue          # 单页主组件，包含全部页面逻辑与视图
│   ├── main.js          # Vue 入口
│   ├── api.js           # 后端 API 封装
│   ├── styles.css       # 全局样式（设计 token + 组件类）
│   └── assets/icons/    # SVG 图标（nav-*, action-*, status-*）
├── backend/             # Spring Boot 后端
│   └── src/main/        # Java 源码
├── dist/                # Vite 构建产物（勿手动编辑）
├── docs/                # 设计文档
├── backups/             # 自动备份
├── 患者陪伴需求文档.md   # 产品需求原始文档（重要参考）
└── CLAUDE.md            # 本文件
```

## 开发命令

```bash
# 前端开发服务器（localhost:5173）
npm run dev

# 生产构建
npm run build

# 预览构建产物
npm run preview
```

## 设计 Token（CSS 变量）

定义在 `src/styles.css` `:root` 块，修改样式请优先调整 token 而非具体组件：

```css
--paper        /* 页面底色 #fbf8f4 */
--panel        /* 面板底色 #fffdf9 */
--panel-strong /* 强调面板 #fff7ee */
--ink          /* 主文字 #2e2a27 */
--muted        /* 次要文字 */
--line         /* 边框线 #eadfd3 */
--rose         /* 主色（玫瑰红）*/
--sage         /* 辅色（草绿）*/
--amber        /* 强调色（琥珀）*/
--radius       /* 基础圆角 8px */
--font-title   /* Georgia serif 标题字体 */
--font-body    /* Avenir Next / PingFang 正文字体 */
```

## 组件命名惯例（CSS 类）

- `.card` — 通用卡片容器
- `.card-header / .card-body` — 卡片头尾
- `.schedule-row` — 日程行
- `.notice-row / .pinned-notice` — 通知行
- `.timeline-item` — 时间轴条目
- `.symptom-row` — 症状记录行
- `.small-btn` — 小操作按钮；`.small-btn.sage` 绿色，`.small-btn.danger` 红色
- `.tag` — 状态标签胶囊
- `.modal-backdrop / .confirm-dialog` — 模态弹窗

## 页面模块（App.vue `currentPage` 值）

| 值 | 页面 |
|----|------|
| `today` | 今日概览 |
| `calendar` | 日历 / 议程 |
| `body` | 身体状况 |
| `timeline` | 就医时间轴 |
| `messages` | 消息 / 备忘 |
| `files` | 文件 |
| `members` | 成员管理 |
| `help` | 帮助 |
| `privacy` | 隐私设置 |

## AI 协作注意事项

1. **不要引入任何 CSS 框架**（Tailwind、Bootstrap 等），保持纯 CSS 一致性。
2. **修改样式**时以 CSS 变量为先，避免硬编码颜色。
3. **新增图标**请放到 `src/assets/icons/`，文件名格式：`{分类}-{名称}.svg`。
4. **后端 API** 接口定义在 `src/api.js`，新功能先在此文件添加方法。
5. **单文件架构**：当前所有前端逻辑集中在 `App.vue`，拆分组件前请确认需求规模。
6. **中文优先**：用户界面文案、注释均使用中文。
7. **设计风格**：温暖米色调、圆润圆角（12–16px）、柔和阴影、无强烈对比色。

## 版本历史摘要

- v0.1–0.4：基础架构，今日/日历/身体/时间轴页面
- v0.5：视觉打磨（卡片动效、FAB 渐变）
- v0.6：置顶通知、身体摘要磁贴、分段控件、体温记录
- v0.7（进行中）：整体活跃温馨风格升级，CLAUDE.md 初始化
