# 代理人数字孪生

一款 iOS SwiftUI 应用，以全屏对话流的形式管理你的数字孪生代理人——每天自动按计划推送内容发布提醒，支持多平台、多人设，全程托管式执行。

![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Xcode](https://img.shields.io/badge/Xcode-15%2B-blue)

---

## 功能介绍

### 全屏聊天界面
- 整个页面是一个对话窗口，每天自动开启新的对话
- 页面始终停留在最新消息
- 底部固定输入框，随时向代理人发指令

### 每日自动触发流程
1. **启动** → 代理人发送早安问候 + 今日总览卡片（含时间轴）
2. **到达计划时间点** → 自动弹出待执行卡片，提示确认
3. **点击卡片** → 弹出确认界面 → 20–25 秒模拟进度条
4. **完成后** → 推送任务完成卡片至对话流

### 支持平台
| 平台 | 说明 |
|------|------|
| 朋友圈 | 微信朋友圈动态 |
| 小红书 | 图文/视频推送 |
| 公众号 | 图文推文发布 |
| 微信私聊 | 互动卡片推送 |

### 左侧抽屉面板
点击左上角三角按钮展开，包含：
- **切换人设** — 一键切换代理人风格
- **今日已执行** — 查看当天已完成任务
- **历史对话** — 查看过往日期的对话记录
- **OpenClaw 对话** — 与 OpenClaw AI 进行实时对话（需配置后端）

### 人设系统
内置 4 种默认人设，支持自定义：
- 👔 职场精英（专业严谨）
- ✨ 生活达人（亲切温暖）
- 🎨 创意博主（创意活泼）
- 🔬 知识领袖（简洁高效）

---

## 使用方式

### 环境要求
- Xcode 15 或以上
- iOS 16.0 或以上（真机或模拟器）
- macOS 13 Ventura 或以上

### 运行步骤

**1. 克隆仓库**
```bash
git clone https://github.com/zayme429/agent-digital-twin.git
cd agent-digital-twin
```

**2. 打开项目**
```bash
open AgentDigitalTwin.xcodeproj
```

**3. 选择模拟器或真机，点击运行（⌘R）**

无需额外依赖，项目不使用任何第三方库。

---

## 发指令给代理人

在底部输入框输入自然语言指令，代理人会响应：

| 指令示例 | 效果 |
|----------|------|
| `今天的计划` | 列出今日所有发布任务及状态 |
| `发朋友圈` | 立即创建朋友圈手动触发任务 |
| `推小红书` | 创建小红书推送任务 |
| `发公众号` | 创建公众号推文任务 |
| `发互动卡片` | 创建微信互动卡片任务 |
| `今日报告` | 输出今日运营数据汇总 |
| `当前人设` | 查看当前激活的代理人人设 |

---

## 项目结构

```
AgentDigitalTwin/
├── AgentDigitalTwinApp.swift      # App 入口，注入环境对象
├── Models.swift                   # 数据模型：Platform、ScheduleCard、TimelineItem
├── ScheduleManager.swift          # 核心调度器：每日会话、定时触发、时间轴管理
├── ContentView.swift              # 主界面：全屏聊天流 + 所有气泡组件
├── SideDrawerView.swift           # 左侧抽屉：人设切换、已执行列表、历史记录、OpenClaw 入口
├── ConfirmExecuteSheet.swift      # 任务确认底部弹窗
├── TaskProgressOverlay.swift      # 任务执行进度覆盖层
├── PersonaModel.swift             # 人设数据模型
├── PersonaManager.swift           # 人设状态管理
├── PersonaSelectorView.swift      # 人设选择组件
├── PersonaSettingsView.swift      # 人设配置管理页
├── OpenClawChatView.swift         # OpenClaw 对话界面
├── StarsBackground.swift          # 星空背景动画
├── HeaderView.swift               # 顶部状态栏组件
├── backend/                       # 后端服务
│   ├── server.py                  # Python 后端服务器（配置管理 + OpenClaw 转发）
│   ├── config.json                # 配置文件（自动生成）
│   ├── media/                     # 上传的图片文件
│   └── backups/                   # 配置备份
└── openclaw-plugin-http-inbound/  # OpenClaw HTTP Inbound Channel 插件
    ├── src/                       # 插件源码
    ├── mock-server.py             # 本地测试用 Mock Server
    └── 文档...                    # 详细文档
```

---

## OpenClaw AI 集成

本项目已集成 OpenClaw AI 对话功能。

### 快速开始

1. **启动后端服务器**
   ```bash
   cd backend
   python3 server.py
   ```

2. **配置 OpenClaw**
   - 打开浏览器访问 http://localhost:8765
   - 点击 "🔌 OpenClaw" 标签
   - 配置服务地址和 API Key
   - 使用测试功能验证连接

3. **在 iOS App 中使用**
   - 打开侧边栏（左上角三条横线）
   - 点击 "OpenClaw 对话"
   - 开始与 AI 对话

### 详细文档

- [OpenClaw 集成总结](OPENCLAW_INTEGRATION.md) - 完整的集成说明和使用指南
- [OpenClaw 迁移指南](OPENCLAW_MIGRATION_GUIDE.md) - 如何将 OpenClaw 集成到其他项目

---

## 说明

本项目为界面原型演示，所有「发布」操作均为模拟执行，不会实际调用任何平台 API。进度条动画时长随机在 20–25 秒之间。

---

## License

MIT
