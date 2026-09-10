<p align="center">
  <img src="app.png" alt="SoundBridge" width="600">
</p>

<h1 align="center">SoundBridgePlus</h1>

<p align="center">
  A free, open-source macOS system-wide volume controller for HDMI and DisplayPort monitors with 10-band EQ and Launch-at-Login support.
  <br>
  <em>本项目基于原作者 <a href="https://github.com/chenjy16">@chenjy16</a> 的开源项目 <a href="https://github.com/chenjy16/SoundBridge">SoundBridge</a> 进行二次开发与功能增强。</em>
</p>

<p align="center">
  <a href="https://github.com/cn-404-not-found/SoundBridgePlus/releases">Download</a> · 
  <a href="#-soundbridgeplus-增强特性-whats-new-in-plus">Plus 特性</a> · 
  <a href="#-致谢与声明-credits--acknowledgements">致谢</a> · 
  <a href="#how-it-works">How It Works</a> · 
  <a href="#building-from-source">Build</a>
</p>

---

## ✨ SoundBridgePlus 增强特性 (What's New in Plus)

- 🔊 **彻底解决音频爆音与死锁（Anti-Popping & Self-Healing SPSC Buffer）**：
  - **严格单写者 SPSC 环形缓冲区**：重构了虚拟驱动与音频引擎之间的跨进程通信协议，严守驱动仅写 `write_index`、Host 仅写 `read_index` 的铁律，彻底根除原版中因多进程并发篡改读指针引发的 64 位整数无符号下溢与永久爆音死循环；
  - **自动对齐与自愈恢复**：增加了指针越界检测与自愈机制，遇到极端时钟抖动或缓冲区溢出时，由 Host 消费端平滑重设安全水位，彻底消除“一旦爆音无法自愈、必须多次退出重启”的痛点；
  - **纯净直通（Bit-perfect Passthrough）**：在虚拟设备与物理硬件同采样率（如主流 48kHz）下启用纯净直通，旁路容易在跨 Buffer 处产生波形阶跃断裂的简易线性重采样器，消除“噼啪”碎杂音；
  - **RT-Safe 实时音频渲染优化**：在 CoreAudio 实时渲染回调中缓存共享内存裸指针，彻底移除互斥锁与动态堆分配，杜绝音频线程优先级反转引起的硬件缓冲区断音。
- 🚀 **开机自启动（Launch at Login）**：基于 macOS 13+ 官方原生 `SMAppService.mainApp` API 实现，可在菜单栏控制面板或设置中一键开启/关闭开机自启，状态与 macOS 系统设置（通用 → 登录项）双向同步。
- 🔒 **纯净离线体验（移除启动自动更新）**：彻底移除了原项目中的 Sparkle 依赖及启动时的联网检查逻辑，拒绝静默联网请求，启动更快速、更纯粹。
- ⚙️ **快捷设置入口（Settings Window）**：菜单栏面板底部新增设置按钮，快速调出包含通用自启选项与系统驱动信息的设置窗口。
- 🛡️ **内置自动签名（Ad-hoc Code Signing）**：构建脚本自带代码签名机制，满足系统登录项的安全准入要求，本地构建直接可用，无需 Apple Developer ID 证书。

---

## 🙏 致谢与声明 (Credits & Acknowledgements)

本项目是基于原作者 **[chenjy16](https://github.com/chenjy16)** 开发的优秀开源项目 **[SoundBridge](https://github.com/chenjy16/SoundBridge)** 进行的定制与功能增强（Plus 版本）。

在此特别由衷感谢原作者 **[chenjy16](https://github.com/chenjy16)** 打造了如此优秀的 macOS 虚拟音频驱动架构，解决了大量外接显示器用户的音量调节痛点！

- **原版项目地址**：[https://github.com/chenjy16/SoundBridge](https://github.com/chenjy16/SoundBridge)
- **底层驱动库**：特别感谢 [gavv/libASPL](https://github.com/gavv/libASPL) 提供的 Audio Server Plugin Library。

所有原始架构与核心代码版权归原作者所有，本项目遵循原项目的 MIT 开源协议。

---

## Why SoundBridge?

Many external monitors connected via HDMI or DisplayPort have fixed-volume audio output — macOS shows the volume slider grayed out. SoundBridge solves this by inserting a virtual audio driver between your apps and the physical device, giving you full software volume control through the menu bar.

No kernel extensions. No background daemons you can't see. Just a lightweight menu bar app.

## Features

- System-wide volume control for fixed-volume HDMI/DisplayPort audio
- Menu bar app with volume slider and mute toggle
- Keyboard volume keys work as expected
- 10-band parametric EQ with preset support
- Automatic device detection and hot-plug support
- Universal binary (Apple Silicon + Intel)
- Guided onboarding with one-click driver install
- Launch at login support (macOS 13+ SMAppService)
- Pure offline experience with no auto-update checks on launch
- Rock-solid lock-free SPSC audio ring buffer with self-healing to prevent crackling and underflow
- Code signed and notarized

## Requirements

- macOS 13.0+ (Ventura) or later
- HDMI or DisplayPort audio output

## Installation

1. Download the latest `.dmg` from [Releases](https://github.com/cn-404-not-found/SoundBridgePlus/releases)
2. Drag `SoundBridgePlus.app` to Applications
3. Launch SoundBridgePlus — the onboarding wizard will guide you through driver installation
4. Your HDMI/DisplayPort audio device will appear with a working volume slider

To uninstall, use the "Uninstall" option in the SoundBridgePlus menu bar dropdown.

## How It Works

SoundBridge uses a four-component architecture:

```
┌─────────────────┐     ┌──────────────────────┐     shared memory     ┌─────────────────┐     ┌─────────────────┐
│   Menu Bar App   │────▶│   HAL Virtual Driver  │◀──────────────────▶│   Host Engine    │────▶│  Physical Device │
│   (SwiftUI)      │     │   (C++ CoreAudio)     │    /tmp/soundbridge  │   (Swift)        │     │  (HDMI/DP)       │
└─────────────────┘     └──────────────────────┘                      └─────────────────┘     └─────────────────┘
       UI controls              Proxy device                            DSP + rendering
       volume/mute              captures audio                          gain + EQ
```

### Components

| Component | Language | Location | Role |
|-----------|----------|----------|------|
| App | Swift / SwiftUI | `apps/mac/SoundBridgeApp/` | Menu bar UI, onboarding, driver installer, volume control via CoreAudio API |
| Driver | C++ | `packages/driver/` | HAL plugin that creates virtual proxy devices, captures audio into shared memory ring buffers |
| Host | Swift | `packages/host/` | Background process that reads from shared memory, applies gain/DSP, renders to physical hardware |
| DSP | C/C++ | `packages/dsp/` | 10-band parametric EQ engine with C ABI, used by Host via Objective-C++ bridge |

### Audio Chain

1. macOS routes audio to the SoundBridge proxy device (appears as "Device via SoundBridge")
2. The HAL driver writes audio frames into a shared memory ring buffer (`/tmp/soundbridge-<uid>`)
3. The Host process reads from the ring buffer, applies software gain (from the volume slider) and optional EQ
4. Processed audio is rendered to the real physical output device

Volume control uses CoreAudio's `kAudioDevicePropertyVolumeScalar` on the proxy device. The driver stores the value in shared memory, and the Host applies it as a linear gain multiplier with smoothing to avoid clicks.

## Project Structure

```
SoundBridge/
├── apps/mac/SoundBridgeApp/    # SwiftUI menu bar application
│   └── Sources/
│       ├── App/                # App entry point, lifecycle
│       ├── Views/              # MenuBarView, SettingsWindow, Onboarding
│       ├── Services/           # VolumeController, IPCController, DriverInstaller, LaunchAtLoginManager
│       └── Resources/          # Icons, fonts, images
├── packages/
│   ├── driver/                 # CoreAudio HAL virtual driver (C++)
│   │   ├── src/Plugin.cpp      # Driver runtime logic
│   │   ├── include/            # RFSharedAudio.h (shared memory protocol)
│   │   └── vendor/libASPL/     # HAL plugin C++ wrapper
│   ├── host/                   # Background audio host (Swift)
│   │   └── Sources/
│   │       └── SoundBridgeHost/
│   │           ├── Audio/      # AudioRenderer, AudioEngine
│   │           ├── Devices/    # DeviceDiscovery, DeviceRegistry
│   │           └── Services/   # SharedMemoryManager, DSPProcessor
│   └── dsp/                    # DSP engine (C/C++)
│       ├── include/            # Public C API
│       ├── src/                # Biquad filters, limiter, engine
│       ├── bridge/             # Objective-C++ wrapper for Swift
│       └── tests/              # 33 automated tests
├── tools/                      # Build, sign, notarize, DMG scripts
├── Makefile                    # Development shortcuts
└── .github/workflows/          # Release CI (build + sign + notarize + DMG)
```

## Building from Source

### Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode Command Line Tools (`xcode-select --install`)
- CMake (`brew install cmake`)
- Git (for submodule management)

检查依赖是否就绪：

```bash
make install-deps
```

### Clone & Initialize

项目依赖 git submodule（HAL 驱动使用的 [libASPL](https://github.com/gavv/libASPL) 库），克隆后必须初始化：

```bash
git clone https://github.com/cn-404-not-found/SoundBridgePlus.git
cd SoundBridgePlus
git submodule update --init --recursive
```

> ⚠️ 如果跳过 submodule 初始化，构建 HAL Driver 时会报错：`does not contain a CMakeLists.txt file`。

### Quick Build

```bash
# 构建所有组件（DSP、Driver、Host、App），输出 universal binary（arm64 + x86_64）
make build

# 运行应用
make run
```

`make build` 会自动完成以下步骤：
1. 从 git tag 更新版本号到各组件的 Info.plist / CMakeLists.txt
2. 构建 DSP 库（C++，universal）
3. 构建 HAL 虚拟驱动（C++，universal，依赖 libASPL）
4. 构建 Audio Host（Swift，universal）
5. 构建 Menu Bar App（Swift，universal）
6. 创建 `dist/SoundBridgePlus.app` 应用包

构建产物位于 `dist/SoundBridgePlus.app`。

### 常用命令

| 命令 | 说明 |
|------|------|
| `make build` | 构建所有组件（DSP、Driver、Host、App） |
| `make bundle` | 仅创建 .app 包（需先 build） |
| `make run` | 运行已构建的应用 |
| `make dev` | 重置状态 + 构建 + 运行（完整的开发流程，会触发 onboarding） |
| `make clean` | 清理所有构建产物 |
| `make rebuild` | clean + 完整重新构建 |
| `make quick` | 仅重新构建 Swift 代码（更快的迭代速度） |
| `make test` | 运行 DSP 测试套件 |
| `make update-version` | 从 git tag 更新各组件版本号 |

### 打包与分发

```bash
# 代码签名
make sign

# 验证签名
make verify

# 创建 DMG 安装包（含拖拽到 Applications 的布局）
make dmg

# 完整发布流程：构建 → 签名 → 验证 → DMG
make full-release
```

| 命令 | 说明 |
|------|------|
| `make sign` | 使用 Developer ID 证书对 .app 进行代码签名 |
| `make verify` | 验证所有组件的代码签名 |
| `make dmg` | 创建带拖拽安装布局的 DMG 文件 |
| `make release` | 构建 + 签名 + 验证 |
| `make full-release` | 构建 + 签名 + 验证 + DMG（完整流水线） |
| `make test-release` | 测试已签名的 release 构建 |

> 代码签名需要有效的 Apple Developer ID 证书。如果仅本地开发测试，可以跳过签名步骤直接使用 `make build` + `make run`。

### 手动构建各组件

如果需要单独构建某个组件：

```bash
# 1. DSP 库（C++）
cmake -S packages/dsp -B packages/dsp/build -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
cmake --build packages/dsp/build

# 2. HAL 驱动（C++，依赖 libASPL submodule）
cmake -S packages/driver -B packages/driver/build -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
cmake --build packages/driver/build

# 3. Host 引擎（Swift）
cd packages/host && swift build -c release

# 4. Menu Bar 应用（Swift）
cd apps/mac/SoundBridgeApp && swift build -c release
```

### 构建产物

```
dist/
└── SoundBridgePlus.app/
    └── Contents/
        ├── MacOS/
        │   ├── SoundBridgeApp          # 主程序（Menu Bar 应用）
        │   └── SoundBridgeHost         # 后台音频引擎
        ├── Resources/
        │   ├── SoundBridgeDriver.driver/  # HAL 虚拟驱动
        │   └── ...                        # 图标、字体等资源
        └── Info.plist
```

## Release Pipeline

Releases are automated via GitHub Actions. When you publish a release with a `vX.Y.Z` tag:

1. Builds all components as universal binaries (arm64 + x86_64)
2. Creates the `.app` bundle
3. Code signs with Developer ID certificate
4. Notarizes with Apple
5. Creates a signed and notarized DMG
6. Uploads assets to the GitHub Release

Required repository secrets: `APPLE_CERTIFICATE`, `APPLE_CERTIFICATE_PASSWORD`, `KEYCHAIN_PASSWORD`, `APPLE_ID`, `APPLE_ID_PASSWORD`, `APPLE_TEAM_ID`.

## Contributing

Contributions are welcome. The codebase is structured so each component can be built and tested independently:

- DSP changes: `make test` runs the C++ test suite
- Driver changes: rebuild and `sudo killall coreaudiod` to reload
- Host/App changes: `make quick` for fast Swift-only rebuilds

## License

MIT
