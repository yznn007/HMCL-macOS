# HMCL-macOS

简体中文 | [English](README.md)

为 [Hello Minecraft! Launcher](https://github.com/HMCL-dev/HMCL) 提供 macOS App Bundle 与 DMG 打包。

HMCL-macOS 会将 HMCL 官方 `.jar` 文件封装成标准 macOS `.app`，再打包为可拖拽安装的 `.dmg`。本项目不修改 HMCL 本体。

## 下载

发布产物来自上游 HMCL GitHub Releases，并使用与上游一致的版本 tag：

| 上游 Release 类型 | 产物 | GitHub Release 类型 |
| --- | --- | --- |
| 非 prerelease | `HMCL-macOS-aarch64-vX.Y.Z.dmg` / `HMCL-macOS-x64-vX.Y.Z.dmg` | 正式 Release |
| prerelease | `HMCL-macOS-aarch64-vX.Y.Z.dmg` / `HMCL-macOS-x64-vX.Y.Z.dmg` | Prerelease |

请在本仓库的 Releases 页面下载需要的 `.dmg`。

## 安装

1. 下载 `.dmg`。
2. 打开 `.dmg`。
3. 将 `HMCL.app` 拖入 `Applications`。
4. 从“应用程序”、Launchpad、Spotlight 或 Dock 启动 HMCL。

如果 macOS 因为应用未签名而阻止打开，请在 Finder 中按住 Control 点击应用，然后选择“打开”。

## 本项目做什么

- 从 HMCL 上游 GitHub Releases 下载 HMCL。
- 在上游 release notes 提供 SHA-256 时进行校验。
- 创建标准 `HMCL.app` 应用包。
- 为应用包加入 HMCL 官方 macOS 图标。
- 将 HMCL 固定存放为应用包内的 `Contents/Resources/HMCL.jar`。
- 在应用包内记录上游版本、打包通道和目标架构。
- 将应用包打包成带 `Applications` 快捷入口的 `.dmg`。
- 使用 GitHub Actions 发布 `stable` 和 `dev` 两个打包通道构建。

## App Bundle 结构

```text
HMCL.app
└── Contents
    ├── Info.plist
    ├── MacOS
    │   └── HMCL
    └── Resources
        ├── HMCL.jar
        ├── HMCL.version
        ├── HMCL.channel
        ├── HMCL.arch
        └── AppIcon.icns
```

启动器日志会写入：

```text
~/.hmcl/hmcl-app-launcher.log
```

## 本地构建

为指定打包通道构建 DMG：

```bash
./scripts/build-channel-dmg.sh --channel stable --arch aarch64
./scripts/build-channel-dmg.sh --channel stable --arch x64
./scripts/build-channel-dmg.sh --channel dev --arch aarch64
```

产物会输出到 `dist/`：

```text
dist/HMCL-macOS-<arch>-<tag>.dmg
```

也可以分步执行：

```bash
./scripts/download-hmcl-channel.sh --channel stable --output-dir downloads/stable/aarch64
./scripts/build-hmcl-app.sh downloads/stable/aarch64/HMCL-*.jar --version vX.Y.Z --arch aarch64 --output-dir dist/stable/aarch64
./scripts/create-dmg.sh --app dist/stable/aarch64/HMCL.app --version aarch64-vX.Y.Z --output-dir dist/stable/aarch64
```

## 图标

仓库包含来自上游仓库的 HMCL 官方 macOS 图标源文件，以及由它生成的 `.icns` 文件：

```text
assets/icons/HMCL-official-icon-mac.png
assets/icons/AppIcon.icns
```

可使用以下命令重新生成：

```bash
./scripts/create-official-icon.sh
```

如果要从上游仓库刷新图标源文件并重新生成 `.icns`，可以运行：

```bash
./scripts/create-official-icon.sh --refresh
```

## GitHub Actions

自动发布工作流位于：

```text
.github/workflows/build-releases.yml
```

它会定时运行，也可以手动触发。工作流使用 matrix 构建打包通道和 macOS 架构：

```text
stable, dev
aarch64, x64
```

每种上游 Release 类型都会从上游 GitHub Releases 下载 jar，在 release notes 提供 SHA-256 时进行校验，分别构建各架构的 `HMCL.app`、生成 `.dmg`、上传 artifact，然后在对应版本尚未发布时创建 GitHub Release；如果 Release 已存在，则把当前 DMG 资产上传并覆盖到该 Release。每次运行都会显式同步 GitHub Release 状态：上游非 prerelease 构建会作为普通 Release 并成为 Latest；上游 prerelease 构建会作为 Prerelease，并且不会成为 Latest。

Release tag 直接使用上游 HMCL tag。架构不写入 Release tag；同一个版本的 Release 中会包含所有架构对应的 DMG 资产。

```text
<tag>
```

示例：

```text
v3.15.2
v3.17.0.351
```

每个 Release 中会包含类似这样的架构资产：

```text
HMCL-macOS-aarch64-v3.15.2.dmg
HMCL-macOS-x64-v3.15.2.dmg
```

HMCL 本体基于 Java。这里的架构拆分主要是面向 macOS 用户的分发和元数据拆分：`aarch64` 面向 Apple Silicon Mac，`x64` 面向 Intel Mac。

## 上游发布模型

本项目以上游 HMCL GitHub Releases 为准，而不是使用官网下载 API。

通道映射：

```text
stable -> 最新的非 prerelease GitHub Release
dev    -> 最新的 prerelease GitHub Release
```

详见 [UPSTREAM.md](UPSTREAM.md)。

## Java 要求

HMCL 需要 Java。应用启动器会按以下顺序查找 Java：

1. `$JAVA_HOME/bin/java`
2. `/usr/libexec/java_home`
3. `which java`

如果找不到 Java，应用会弹出 macOS 对话框提示。

## 签名与公证

未签名构建可用于本地测试，但面向公众分发的 macOS 软件建议使用 Developer ID 签名和 notarization。

详见：

```text
docs/SIGNING_AND_NOTARIZATION.md
```

辅助脚本：

```bash
./scripts/sign-and-notarize.sh
```

## Homebrew Cask

仓库提供了稳定版通道的 Homebrew Cask 模板：

```text
packaging/homebrew/Casks/hmcl-macos.rb
```

详见：

```text
docs/HOMEBREW_CASK.md
```

发布 tap 前请替换模板中的 GitHub owner 和 SHA-256。

## 仓库结构

```text
scripts/
├── download-hmcl-channel.sh
├── build-hmcl-app.sh
├── create-dmg.sh
├── build-channel-dmg.sh
├── create-official-icon.sh
└── sign-and-notarize.sh
```

- `download-hmcl-channel.sh`：从上游 GitHub Releases 下载指定打包通道，并在可用时校验 SHA-256。
- `build-hmcl-app.sh`：从 jar 创建 `HMCL.app`。
- `create-dmg.sh`：创建可拖拽安装的 DMG。
- `build-channel-dmg.sh`：运行完整通道构建流程。
- `create-official-icon.sh`：从上游官方图标源重新生成 `assets/icons/AppIcon.icns`。
- `sign-and-notarize.sh`：签名应用，并可选择提交 notarization 和 staple。

## 许可证

本仓库中的打包脚本和文档使用 MIT License。

HMCL 本体由上游 HMCL 项目分发，采用 GPLv3 并包含附加条款。本项目不修改 HMCL。包含 `HMCL.jar` 的发布产物应保留上游项目、源码和许可证引用。

上游：

- https://github.com/HMCL-dev/HMCL

## 非目标

本项目不修改 HMCL，不捆绑 Minecraft，不绕过 Java 依赖，也不提供 Minecraft/Microsoft 账号相关功能。
