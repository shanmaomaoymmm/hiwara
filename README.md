# Hiwara

![GitHub](https://img.shields.io/github/license/shanmaomaoymmm/hiwara)
![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/shanmaomaoymmm/hiwara?include_prereleases)
![GitHub issues](https://img.shields.io/github/issues/shanmaomaoymmm/hiwara)
![GitHub repo size](https://img.shields.io/github/repo-size/shanmaomaoymmm/hiwara)
![GitHub Repo stars](https://img.shields.io/github/stars/shanmaomaoymmm/hiwara?style=social)

🕹️ 基于 Tauri v2 的跨平台Iwara客户端 | Iwara for Tauri v2

此应用兼容最新版Iwara网站，桌面端支持Windows、MacOS、Linux，移动端支持Android和iOS，使用Tauri、Vue和Typescript编写。后期计划支持鸿蒙系统。  
This app is compatible with the latest Iwara website. It supports Windows, macOS, and Linux on desktop, and Android and iOS on mobile. Built with Tauri, Vue, and TypeScript. Plans to support HarmonyOS in the future.

<img src="./app-icon.png" width="200px">

## 📱 支持平台 | Supported Platforms

* Windows
* MacOS
* Linux
* Android
* iOS

## 🛠️ 环境搭建 | Development environment setup

### Rust 环境搭建 | Rust Environment Setup

访问以下链接查看如何搭建Rust环境。  
You can refer to the following links to set up the Rust environment.

<https://rust-lang.org/>

### Nodejs 环境搭建 | Nodejs Environment Setup

访问以下链接查看如何搭建Nodejs环境。  
You can refer to the following links to set up the Nodejs environment.

<https://nodejs.org>


### Tauri 环境搭建 | Tauri Environment Setup

访问以下链接查看如何搭建Tauri环境。  
Visit the following links to set up the Tauri environment.

<https://tauri.app/zh-cn/start/prerequisites/>

### Android 环境搭建 | Android Environment Setup

安装Android Studio并安装以下SDK工具  
Install Android Studio and install the following SDK tools

* Android SDK Platform
* Android SDK Platform-Tools
* NDK (Side by side)
* Android SDK Build-Tools
* Android SDK Command-line Tools

设置 `JAVA_HOME` 环境变量  
Set the `JAVA_HOME` environment variable

```bash
# Linux
export JAVA_HOME=/opt/android-studio/jbr

# MacOS
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

# Windows
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Android\Android Studio\jbr", "User")
```

配置 `ANDROID_HOME` 和 `NDK_HOME` 环境变量  
Set `ANDROID_HOME` and `NDK_HOME` environment variables

```bash
#Linux
export ANDROID_HOME="$HOME/Android/Sdk"
export NDK_HOME="$ANDROID_HOME/ndk/$(ls -1 $ANDROID_HOME/ndk)"

#MacOS
export ANDROID_HOME="$HOME/Library/Android/sdk"
export NDK_HOME="$ANDROID_HOME/ndk/$(ls -1 $ANDROID_HOME/ndk)"

#Windows
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LocalAppData\Android\Sdk", "User")
$VERSION = Get-ChildItem -Name "$env:LocalAppData\Android\Sdk\ndk"
[System.Environment]::SetEnvironmentVariable("NDK_HOME", "$env:LocalAppData\Android\Sdk\ndk\$VERSION", "User")
```

使用 `rustup` 添加 Android 编译目标  
Add the Android targets with `rustup`

```bash
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
```

### iOS 环境搭建 | iOS environment setup

安装 Xcode 和 Homebrew  
Install Xcode and Homebrew

<https://developer.apple.com/xcode/>  
<https://brew.sh/>

使用 Homebrew 安装 Cocoapods  
Install Cocoapods using Homebrew

```bash
brew install cocoapods
```

在终端中使用 `rustup` 将 iOS 添加为编译目标  
Add the iOS targets with `rustup` in Terminal

```bash
rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim
```

## 📲 运行 | Running

在项目的根目录下执行以下命令安装依赖  
Run the following command to install dependencies

```bash
npm install
```

运行程序  
Run the program

```bash
npx tauri dev
```

连接手机后，使用以下命令运行到移动端  
After connecting the phone, run the following command to run to the mobile phone

```bash
# Android
npx tauri android run
```

## 📦 打包App | Packaging App

### Windows & Android

Windows 打包脚本 [`package_app.ps1`](package_app.ps1) 同时支持 Windows 和 Android 打包。
The [`package_app.ps1`](package_app.ps1) script supports both Windows and Android packaging.

```powershell
.\package_app.ps1
```

该脚本会自动检查 Rust target 并构建 Windows 和 Android 应用。  
It automatically checks Rust targets and builds both Windows and Android apps.

**Windows 手动打包 | Manual Windows build：**

```powershell
npx tauri build --target x86_64-pc-windows-msvc    # x64
npx tauri build --target aarch64-pc-windows-msvc   # ARM64
npx tauri build --target i686-pc-windows-msvc      # x86
```

**Android 手动打包 | Manual Android build：**

```bash
# 开发调试（连接手机后）/ Run on connected device
npx tauri android run

# 打包 APK / Build APK
npm run tauri android build -- --apk --split-per-abi
```

> Android 打包前需先完成 Android 环境搭建（见上方环境搭建章节）  
> Android build requires the Android environment setup (see the setup section above)

---

### Linux

#### 脚本打包 | Script packaging

- [`package_app_linux_arm64.sh`](package_app_linux_arm64.sh) — ARM64 交叉编译（deb / rpm / appimage）

```bash
./package_app_linux_arm64.sh
```

> ARM64 交叉编译需要 ARM64 系统库。x86_64 和 ARM64 的 WebKit 库无法共存，运行前需移除冲突包。  
> ARM64 cross-compilation requires ARM64 system libraries. x86_64 and ARM64 WebKit libraries conflict, remove conflicting packages before running:

```bash
sudo apt remove -y libwebkit2gtk-4.1-dev libxdo-dev libayatana-appindicator3-dev
```

#### Docker 打包（推荐） | Docker packaging（recommended）

Docker 打包脚本 [`package_app_linux_docker.sh`](package_app_linux_docker.sh) 在隔离环境中构建，无需安装本地系统依赖，支持多架构一键打包。
The [`package_app_linux_docker.sh`](package_app_linux_docker.sh) script builds in an isolated environment without local system dependencies, supporting multi-architecture one-click packaging.

**支持的架构 | Supported architectures：**

| 架构 | Dockerfile | 构建方式 | Build type | 输出目录 | Output dir |
|------|-----------|---------|------------|---------|------------|
| x86_64 | [`docker/Dockerfile.x64`](docker/Dockerfile.x64) | 原生编译 | Native | `docker/release/x64/` |
| ARM64 | [`docker/Dockerfile.arm64`](docker/Dockerfile.arm64) | 交叉编译 | Cross-compile | `docker/release/arm64/` |
| RISC-V 64 | [`docker/Dockerfile.riscv64`](docker/Dockerfile.riscv64) | 交叉编译 | Cross-compile | `docker/release/riscv64/` |

**基本使用 | Basic usage：**

```bash
# x64 + ARM64 all formats (default)
./package_app_linux_docker.sh

# Specify architectures and bundle formats
./package_app_linux_docker.sh --arch x64 arm64 --bundle deb rpm

# Build only x64 deb package
./package_app_linux_docker.sh --arch x64 --bundle deb

# Build only RISC-V 64
./package_app_linux_docker.sh --arch riscv64
```

**离线构建（不连 Docker Hub）| Offline build (no Docker Hub)：**

基础镜像通过 `debootstrap` 从 USTC 镜像本地构建，无需从 Docker Hub 拉取。
The base image is built locally via `debootstrap` from USTC mirror, no Docker Hub required.

```bash
# First run: automatically builds the local base image
./package_app_linux_docker.sh --local-base

# Force rebuild all images (including base image)
./package_app_linux_docker.sh --local-base -f
```

**基础镜像来源优先级 | Base image priority：**

1. 本地已有 `debian:trixie-slim` → 直接使用
   Local `debian:trixie-slim` exists → use directly
2. `--local-base` → 通过 `debootstrap` 从 USTC 构建
   `--local-base` → build via `debootstrap` from USTC mirror
3. 以上都不满足 → 从 Docker Hub 拉取
   Otherwise → pull from Docker Hub

> 依赖详见 [`docker/setup-docker-base.sh`](docker/setup-docker-base.sh) 和 Dockerfile 中的 apt 安装步骤。
> See [`docker/setup-docker-base.sh`](docker/setup-docker-base.sh) and the apt install steps in the Dockerfiles for details.

#### 手动打包 | Manual packaging

**安装 Linux 构建依赖 | Install build dependencies：**

```bash
# Debian / Ubuntu
sudo apt install -y \
  libwebkit2gtk-4.1-dev libxdo-dev \
  libayatana-appindicator3-dev librsvg2-dev libssl-dev

# Fedora
sudo dnf install webkit2gtk4.1-devel xdo-devel \
  libappindicator-gtk3-devel librsvg2-devel openssl-devel

# Arch
sudo pacman -S webkit2gtk-4.1 xdo libappindicator-gtk3 librsvg openssl
```

**构建 | Build：**

```bash
npm install
npm run build

# 默认当前架构 / Current architecture
npx tauri build

# 指定架构和格式 / Specify target and bundle format
npx tauri build --target x86_64-unknown-linux-gnu --bundles "deb,rpm,appimage"
npx tauri build --target aarch64-unknown-linux-gnu --bundles "deb,rpm,appimage"
```

**支持格式 | Supported bundle formats：**

| 格式 | 说明 | Description |
|---|---|---|
| `deb` | Debian/Ubuntu 安装包 | Debian/Ubuntu package |
| `rpm` | Fedora/RHEL 安装包 | Fedora/RHEL package |
| `appimage` | 便携式应用 | Portable application |

> Linux 打包依赖详见 [Tauri Linux Prerequisites](https://tauri.app/zh-cn/start/prerequisites/#linux)

---

### macOS

#### 脚本打包（推荐） | Script packaging (recommended)

zsh 打包脚本 [`package_app_macos.sh`](package_app_macos.sh) 一键完成双架构构建、自签名和 Universal DMG。  
The [`package_app_macos.sh`](package_app_macos.sh) script provides one-click build, signing, and Universal DMG creation.

```bash
./package_app_macos.sh
```

脚本执行流程：  
The script will:

1. 检查 Xcode 和 Rust target  
   Check Xcode and Rust targets
2. 构建 Intel + Apple Silicon 的 `.app`  
   Build `.app` for both architectures
3. Ad-hoc 自签名  
   Ad-hoc sign with `codesign -s -`
4. `lipo` 合并为 Universal Binary，`hdiutil` 创建 DMG  
   Merge with `lipo` and create DMG with `hdiutil`

**输出产物 | Output：**

```
src-tauri/target/universal/Hiwara-universal.dmg      # 通用 DMG
src-tauri/target/universal/Hiwara.app                # 通用 App（x86_64 + arm64）
```

**如需正式签名（分发给其他用户）| For distribution with Developer ID signing：**

```bash
cp doc/macos-packaging-config.md package_app_macos.env
# 编辑 package_app_macos.env 配置签名信息
# Edit the config file with your Developer ID credentials
./package_app_macos.sh
```

> 配置文档详见 [`doc/macos-packaging-config.md`](doc/macos-packaging-config.md)
> 查看可用签名证书：`security find-identity -v -p basic`

**注意事项 | Notes：**

- 首次运行需编译 Rust 后端，约 15-30 分钟  
  First build compiles Rust backend (~15-30 min)
- 构建中断后可重新运行，已编译部分会缓存  
  Re-run if interrupted, already compiled crates are cached

#### 手动打包 | Manual packaging

手动打包步骤详见 [`doc/macos-packaging-manual.md`](doc/macos-packaging-manual.md)  
See [`doc/macos-packaging-manual.md`](doc/macos-packaging-manual.md) for manual packaging steps.

**快速命令 | Quick commands：**

```bash
# 构建指定架构 / Build for specific architecture
npx tauri build --target x86_64-apple-darwin       # Intel
npx tauri build --target aarch64-apple-darwin      # Apple Silicon

# 合并 Universal Binary / Create Universal Binary
lipo -create \
    src-tauri/target/x86_64-apple-darwin/release/hiwara \
    src-tauri/target/aarch64-apple-darwin/release/hiwara \
    -output path/to/universal/hiwara

# 创建 DMG / Create DMG
hdiutil create -volname "Hiwara" -srcfolder Hiwara.app -ov -format UDZO Hiwara-universal.dmg
```

## 🗓️ 开发进度 | Development progress

* ✅ 登录 | Login
* ✅ 订阅列表 | Subscriptions
* ✅ 视频列表 | Video list
* ✅ 插画列表 | Image list
* ✅ 视频播放 | Video playback
* ✅ 插画查看 | Image viewer
* ✅ 个人主页 | User profile
* ✅ 空间查看 | Space view
* ✅ 搜索 | Search
* ✅ 关注、订阅、收藏、评论 | Follow, subscribe, favorite, comment
* ✅ 分析及外链下载 | Analysis and external link downloads
* ⬜ 播放列表 | Playlist
* ✅ 历史记录 | History
* ✅ 关注列表 | Following list
* ✅ 粉丝列表 | Followers list
* ✅ 设置 | Settings
* ✅ 桌面端适配 | Desktop adaptation
* ✅ 平板电脑适配 | Tablet adaptation
* ✅ 暗黑模式 | Dark mode
* ✅ 离线缓存及下载 | Offline caching and downloading
* ✅ 论坛浏览 | Forum browsing
* ✅ 论坛发帖 | Forum posting
* ✅ 多语言支持 | Multi-language support
* ✅ Aria2支持 | Aria2 support
* ⬜ DLAN支持 | DLNA support
* ⬜ DoH 支持 | DoH support
* ⬜ 鸿蒙系统支持 | HarmonyOS support
* 🛑 视频上传 | Video upload
* 🛑 插画上传 | Illustration upload

\* 标⬜表示当前功能计划但未完成，标✅表示当前功能已实现，标🛑表示该功能暂不考虑。  
\* ⬜ indicates planned but incomplete features, ✅ indicates completed features, 🛑 indicates features not currently considered.

## 🌏 语言适配 | Multilingual support

* 简体中文 | 简体中文 | Chinese Simplified
* 繁体中文 | 繁體中文 | Chinese Traditional
* 英语 | English | English
* 日语 | 日本語 | Japanese
* 韩语 | 한국어 | Korean
* 法语 | Français | French
* 西班牙语 | Español | Spanish
* 葡萄牙语 | Português | Portuguese
* 德语 | Deutsch | German
* 意大利语 | Italiano | Italian
* 俄语 | Русский | Russian
* 乌克兰语 | Українська | Ukrainian
* 泰语 | ภาษาไทย | Thai
* 越南语 | Tiếng Việt | Vietnamese
* 高棉语 | ភាសាខ្មែរ | Khmer
* 印地语 | हिन्दी | Hindi
* 阿拉伯语 | العربية | Arabic
* 希伯来语 | עברית | Hebrew
* 藏文 | བོད་ཡིག | Tibetan
* 维吾尔语 | ئۇيغۇر تىلى | Uyghur
* 哈萨克语 | қазақ тілі | Kazakh
* 蒙古语 | монгол хэл | Mongolian

## 📕 旧版本 | Old version

以下为旧版 Hiwara 项目链接  
Links to old versions of the Hiwara project
 
v1: <https://github.com/shanmaomaoymmm/hiwara/tree/uniapp>  
v2: <https://github.com/shanmaomaoymmm/hiwara_v2>

⚠ 注意:旧版因性能和安全问题已停止维护。  
⚠ Note: The old version is no longer maintained due to performance and security issues.

## 📘 参考文档 | Reference document

<https://tauri.app/>  
<https://vuetifyjs.com/>  
<https://fontawesome.com/>
