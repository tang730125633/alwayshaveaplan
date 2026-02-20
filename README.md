# Always Have a Plan ✨

> 🌫️ **毛玻璃效果增强版** - 让每一刻都有计划，成为更好的自己

[English](#english) | [中文](#中文)

---

## 中文

### 🎯 这是什么？

一个帮助你保持专注的 macOS 应用。每次解锁 Mac 时，它会：
- 📅 **有日程时**：显示当前正在进行的事项和进度
- 💭 **无日程时**：用一个深刻的问题唤醒你的自我觉察

### ✨ 本版本的特色改进

相比原版，这个版本做了以下优化：

#### 🌫️ **macOS 原生毛玻璃效果**
- 使用 `NSVisualEffectView` 实现真正的系统级毛玻璃模糊
- 背景透过桌面，更有沉浸感和现代感
- 事件卡片采用半透明玻璃质感，层次分明

#### 💪 **更有力量的激励文案**
- 原版："你想干什么？"
- **新版**："**你正在成为什么样的人？**"
- 副标题强调深度思考："你此时要做什么事情别着急，请好好思考一下，当下最重要的事情是什么？"
- 更符合 Dan Koe 人生操作系统理念，强调身份认同

#### ⏱️ **优化的显示时长**
- 自动隐藏时间从 3 秒延长到 10 秒
- 给你更多时间看清当前任务

### 应用截图

<div align="center">

| 无日程状态 | 当前日程 |
|:---------:|:--------:|
| ![无日程](screenshots/no-events.png) | ![当前日程](screenshots/current-event.png) |

*毛玻璃效果 + 激励文案，让每一刻都有意义*

</div>

### 核心理念

> **每一刻都应该有计划地度过。**

当你解锁 Mac 时，不应该漫无目的地打开浏览器或社交媒体。这个应用会：
- ✅ 提醒你当前应该做什么
- ✅ 让你思考"我正在成为什么样的人"
- ✅ 避免时间在无意识中流失

### 功能特性

- 🔓 **解锁检测**：自动在解锁或唤醒 Mac 时显示
- 📅 **日历集成**：读取所有日历的事件
- ⏱️ **进度追踪**：实时显示事件进度和剩余时间
- 🌫️ **毛玻璃效果**：macOS 原生视觉效果，精致现代
- 💪 **激励文案**：深刻的问题唤醒自我觉察
- 🎨 **精美动画**：流畅的淡入淡出效果
- ⌨️ **防止误退出**：禁用 Command+Q
- 🔄 **开机自启**：自动注册为登录项

### 系统要求

- macOS 14.0 或更高版本
- 日历访问权限

### 安装方法

#### 方式一：从源码构建（推荐）

```sh
# 克隆仓库
git clone https://github.com/tang730125633/alwayshaveaplan.git
cd alwayshaveaplan

# 构建发行版
./build-release.sh

# 复制到应用程序文件夹
cp -r run/release/AlwaysHaveAPlan.app /Applications/
```

#### 方式二：开发模式运行

```sh
# 克隆仓库
git clone https://github.com/tang730125633/alwayshaveaplan.git
cd alwayshaveaplan

# 直接运行
swift run
```

### 使用说明

1. **首次启动**：根据提示授予日历访问权限
2. **添加日程**：在系统日历中添加你的日常安排
3. **锁屏解锁**：按 `Control + Command + Q` 锁屏，然后解锁
4. **查看效果**：
   - 有日程时：看到当前事件和进度
   - 无日程时：看到激励问题

### 自定义配置

你可以修改以下参数来定制应用：

**自动隐藏时长**（`Sources/App/AppController.swift`）：
```swift
self.windowManager.showFloatingEvents(events, autoHideAfter: 10)  // 改为你想要的秒数
```

**激励文案**（`Sources/App/Views/FloatingPromptView.swift`）：
```swift
Text("你正在成为什么样的人？")  // 改为你喜欢的问题
```

**毛玻璃材质**（`Sources/App/Views/FloatingPromptView.swift`）：
```swift
VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
// 可选材质：.thin, .ultraThin, .thick, .hudWindow 等
```

### 开发

```sh
# 开发模式运行（终端保持打开，Ctrl+C 退出）
swift run

# 构建
swift build

# 构建发行版
./build-release.sh

# 清理缓存
rm -rf .build
```

### 技术架构

- **Swift + SwiftUI**：现代化的 macOS 开发
- **EventKit**：系统日历集成
- **NSVisualEffectView**：原生毛玻璃效果
- **DistributedNotificationCenter**：解锁检测

详细架构说明请查看 [CLAUDE.md](CLAUDE.md)。

### 致谢

本项目基于 [ChrisZou/alwayshaveaplan](https://github.com/ChrisZou/alwayshaveaplan) 进行优化改进。

感谢原作者提供的优秀基础框架！

### 改进日志

**v1.1.0** (2026-02-20)
- ✨ 添加 macOS 原生毛玻璃效果
- 💪 更新激励文案："你正在成为什么样的人？"
- ⏱️ 延长自动隐藏时间至 10 秒
- 🎨 优化视觉效果和动画

**v1.0.0** (原版)
- 🔓 解锁检测功能
- 📅 日历集成
- ⏱️ 进度追踪

### 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件。

### 联系方式

- GitHub: [@tang730125633](https://github.com/tang730125633)
- 问题反馈: [Issues](https://github.com/tang730125633/alwayshaveaplan/issues)

---

## English

### 🎯 What is this?

A macOS app that helps you stay intentional with your time. Every time you unlock your Mac:
- 📅 **With events**: Shows your current schedule and progress
- 💭 **Without events**: Confronts you with a powerful question

### ✨ Enhanced Features in This Version

Compared to the original version, this fork includes:

#### 🌫️ **Native macOS Frosted Glass Effect**
- Implemented with `NSVisualEffectView` for true system-level blur
- Background shows through your desktop for immersive experience
- Event cards use translucent glass material with depth

#### 💪 **More Powerful Motivational Copy**
- Original: "What do you want to do?"
- **Enhanced**: "**What kind of person are you becoming?**"
- Subtitle emphasizes deep thinking about priorities
- Aligns with Dan Koe's life operating system philosophy

#### ⏱️ **Optimized Display Duration**
- Auto-hide extended from 3 to 10 seconds
- More time to absorb your current task

### Screenshots

<div align="center">

| No Events | Current Event |
|:---------:|:------------:|
| ![No Events](screenshots/no-events.png) | ![Current Event](screenshots/current-event.png) |

*Frosted glass effect + motivational copy = intentional living*

</div>

### Philosophy

> **Every moment should have a plan.**

When you unlock your Mac, you shouldn't mindlessly open browsers or social media. This app:
- ✅ Reminds you what you should be doing
- ✅ Makes you think "What kind of person am I becoming?"
- ✅ Prevents time from slipping away unconsciously

### Features

- 🔓 **Unlock Detection**: Automatically shows when you unlock or wake your Mac
- 📅 **Calendar Integration**: Reads from all your calendars
- ⏱️ **Progress Tracking**: Real-time progress and remaining time
- 🌫️ **Frosted Glass**: Native macOS visual effects, refined and modern
- 💪 **Motivational Copy**: Powerful questions for self-awareness
- 🎨 **Beautiful Animations**: Smooth fade-in/out effects
- ⌨️ **No Accidental Quit**: Command+Q disabled
- 🔄 **Auto-start**: Registers as login item automatically

### Requirements

- macOS 14.0 or later
- Calendar access permission

### Installation

#### Option 1: Build from Source (Recommended)

```sh
# Clone the repository
git clone https://github.com/tang730125633/alwayshaveaplan.git
cd alwayshaveaplan

# Build release version
./build-release.sh

# Copy to Applications folder
cp -r run/release/AlwaysHaveAPlan.app /Applications/
```

#### Option 2: Development Mode

```sh
# Clone the repository
git clone https://github.com/tang730125633/alwayshaveaplan.git
cd alwayshaveaplan

# Run directly
swift run
```

### Usage

1. **First Launch**: Grant Calendar access when prompted
2. **Add Events**: Add your daily schedule to system Calendar
3. **Lock & Unlock**: Press `Control + Command + Q` to lock, then unlock
4. **See the Effect**:
   - With events: See current event and progress
   - Without events: See motivational question

### Customization

You can modify these parameters to customize the app:

**Auto-hide Duration** (`Sources/App/AppController.swift`):
```swift
self.windowManager.showFloatingEvents(events, autoHideAfter: 10)  // Change to your preferred seconds
```

**Motivational Copy** (`Sources/App/Views/FloatingPromptView.swift`):
```swift
Text("What kind of person are you becoming?")  // Change to your preferred question
```

**Frosted Glass Material** (`Sources/App/Views/FloatingPromptView.swift`):
```swift
VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
// Available materials: .thin, .ultraThin, .thick, .hudWindow, etc.
```

### Development

```sh
# Run in development mode (terminal stays open, Ctrl+C to quit)
swift run

# Build
swift build

# Build release version
./build-release.sh

# Clean cache
rm -rf .build
```

### Architecture

- **Swift + SwiftUI**: Modern macOS development
- **EventKit**: System calendar integration
- **NSVisualEffectView**: Native frosted glass effect
- **DistributedNotificationCenter**: Unlock detection

For detailed architecture, see [CLAUDE.md](CLAUDE.md).

### Credits

This project is an enhanced fork of [ChrisZou/alwayshaveaplan](https://github.com/ChrisZou/alwayshaveaplan).

Thanks to the original author for the excellent foundation!

### Changelog

**v1.1.0** (2026-02-20)
- ✨ Added native macOS frosted glass effect
- 💪 Updated motivational copy: "What kind of person are you becoming?"
- ⏱️ Extended auto-hide duration to 10 seconds
- 🎨 Improved visual effects and animations

**v1.0.0** (Original)
- 🔓 Unlock detection
- 📅 Calendar integration
- ⏱️ Progress tracking

### License

MIT License - see [LICENSE](LICENSE) file for details.

### Contact

- GitHub: [@tang730125633](https://github.com/tang730125633)
- Issues: [Report here](https://github.com/tang730125633/alwayshaveaplan/issues)

---

<div align="center">

**Made with ❤️ by Tang**

*Stay intentional. Become who you want to be.*

</div>
