# HMCL-macOS

[简体中文](README.zh-CN.md) | English

macOS App Bundle and DMG packaging for [Hello Minecraft! Launcher](https://github.com/HMCL-dev/HMCL).

HMCL-macOS packages the official HMCL `.jar` files into a standard macOS `.app`, then distributes them as drag-and-drop `.dmg` installers. It does not modify HMCL itself.

## Downloads

Releases are built from the latest upstream HMCL non-prerelease GitHub Release and use the same version tag as upstream:

| Upstream release type | Output | GitHub Release type |
| --- | --- | --- |
| non-prerelease | `HMCL-macOS-aarch64-vX.Y.Z.dmg` / `HMCL-macOS-x64-vX.Y.Z.dmg` | Release |

Download the appropriate `.dmg` from this repository's Releases page.

## Installation

1. Download the `.dmg`.
2. Open the `.dmg`.
3. Drag `HMCL.app` into `Applications`.
4. Launch HMCL from Applications, Launchpad, Spotlight, or Dock.

If macOS blocks the app because it is unsigned, open it from Finder with Control-click, then choose Open.

## What This Project Does

- Downloads HMCL from the upstream HMCL GitHub Releases.
- Verifies SHA-256 checksums published in upstream release notes when available.
- Creates a standard `HMCL.app` bundle.
- Adds the official HMCL macOS icon to the app bundle.
- Stores HMCL as `Contents/Resources/HMCL.jar` inside the app.
- Records the upstream version and target architecture in the app bundle.
- Stores HMCL runtime data in `~/Library/Application Support/HMCL`.
- Stores HMCL dependency caches in `~/Library/Caches/HMCL`.
- Packages the app as a `.dmg` with an `Applications` shortcut.
- Publishes the latest upstream non-prerelease build with GitHub Actions.

## App Bundle Layout

```text
HMCL.app
└── Contents
    ├── Info.plist
    ├── MacOS
    │   └── HMCL
    └── Resources
        ├── HMCL.jar
        ├── HMCL.version
        ├── HMCL.arch
        └── AppIcon.icns
```

Launcher logs are written to:

```text
~/Library/Logs/HMCL-macOS/hmcl-app-launcher.log
```

The app uses a reverse-DNS bundle identifier:

```text
io.github.yznn007.hmcl-macos
```

## Build Locally

Build a DMG for the latest upstream non-prerelease release:

```bash
./scripts/build-channel-dmg.sh --channel stable --arch aarch64
./scripts/build-channel-dmg.sh --channel stable --arch x64
```

The output is written to `dist/`:

```text
dist/HMCL-macOS-<arch>-<tag>.dmg
```

You can also run the steps separately:

```bash
./scripts/download-hmcl-channel.sh --channel stable --output-dir downloads/stable/aarch64
./scripts/build-hmcl-app.sh downloads/stable/aarch64/HMCL-*.jar --version vX.Y.Z --arch aarch64 --output-dir dist/stable/aarch64
./scripts/create-dmg.sh --app dist/stable/aarch64/HMCL.app --version aarch64-vX.Y.Z --output-dir dist/stable/aarch64
```

## Icon

The repository includes the official HMCL macOS icon source from the upstream repository and a generated `.icns` file:

```text
assets/icons/HMCL-official-icon-mac.png
assets/icons/AppIcon.icns
```

Regenerate it with:

```bash
./scripts/create-official-icon.sh
```

Refresh the source image from the upstream repository and regenerate the `.icns` file with:

```bash
./scripts/create-official-icon.sh --refresh
```

## GitHub Actions

The release workflow is defined in:

```text
.github/workflows/build-releases.yml
```

It runs on a schedule and can also be triggered manually. The workflow builds the latest upstream non-prerelease release for macOS architectures:

```text
aarch64, x64
```

For the latest upstream non-prerelease release, it downloads the upstream GitHub release jar, verifies the checksum published in release notes when available, builds both architecture-specific `HMCL.app` bundles, creates `.dmg` assets, uploads the artifacts, and then either creates the matching version GitHub Release or uploads the current DMG assets to the existing release. Every run explicitly syncs the GitHub Release state as a normal release and marks it as Latest.

Release tags use the upstream HMCL tag directly. Architecture is not part of the release tag; each release contains all architecture-specific DMG assets for that version.

```text
<tag>
```

Examples:

```text
v3.15.2
```

Each release contains separate assets such as:

```text
HMCL-macOS-aarch64-v3.15.2.dmg
HMCL-macOS-x64-v3.15.2.dmg
```

HMCL itself is Java-based. The architecture split is a distribution and metadata split for macOS users: `aarch64` targets Apple Silicon Macs, and `x64` targets Intel Macs.

## Upstream Release Model

This project follows HMCL's upstream GitHub Releases instead of the website download API.

Selection rule:

```text
latest upstream non-prerelease GitHub Release
```

See [UPSTREAM.md](UPSTREAM.md) for details.

## Java Requirement

HMCL requires Java. The app launcher searches for Java in this order:

1. `$JAVA_HOME/bin/java`
2. `/usr/libexec/java_home`
3. `which java`

If Java cannot be found, the app shows a macOS dialog.

## Signing and Notarization

Unsigned builds work for local testing, but public macOS distribution should use Developer ID signing and notarization.

See:

```text
docs/SIGNING_AND_NOTARIZATION.md
```

Helper script:

```bash
./scripts/sign-and-notarize.sh
```

## Homebrew Cask

A starter Homebrew Cask is provided for the latest upstream non-prerelease build:

```text
packaging/homebrew/Casks/hmcl-macos.rb
```

See:

```text
docs/HOMEBREW_CASK.md
```

Replace the placeholder owner and SHA-256 before publishing a tap.

## Repository Layout

```text
scripts/
├── download-hmcl-channel.sh
├── build-hmcl-app.sh
├── create-dmg.sh
├── build-channel-dmg.sh
├── create-official-icon.sh
└── sign-and-notarize.sh
```

- `download-hmcl-channel.sh`: downloads the latest upstream non-prerelease HMCL release and verifies SHA-256 when available.
- `build-hmcl-app.sh`: creates `HMCL.app` from a jar.
- `create-dmg.sh`: creates the drag-and-drop DMG.
- `build-channel-dmg.sh`: runs the full non-prerelease build pipeline.
- `create-official-icon.sh`: regenerates `assets/icons/AppIcon.icns` from the official upstream icon source.
- `sign-and-notarize.sh`: signs an app and optionally notarizes/staples a DMG.

## License

The packaging scripts and documentation in this repository are licensed under the MIT License.

HMCL itself is distributed by the upstream HMCL project under GPLv3 with additional terms. This project does not modify HMCL. Releases that include `HMCL.jar` should retain upstream project, source, and license references.

Upstream:

- https://github.com/HMCL-dev/HMCL

## Non-goals

This project does not modify HMCL, bundle Minecraft, bypass Java requirements, or provide Minecraft/Microsoft account functionality.
