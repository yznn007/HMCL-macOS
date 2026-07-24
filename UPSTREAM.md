# HMCL Upstream Release Model

This project uses the upstream HMCL GitHub repository as the source of truth for packaged builds.

Upstream repository:

```text
https://github.com/HMCL-dev/HMCL
```

## Sources

HMCL lists multiple download locations, including the official website, GitHub Releases, and CNB Releases. HMCL-macOS intentionally uses GitHub Releases so builds are tied to upstream repository tags, release metadata, and assets.

## Release Selection

HMCL-macOS only packages the latest upstream non-prerelease GitHub Release:

```text
stable -> latest non-prerelease GitHub Release
```

The project does not package upstream prerelease builds.

## Assets

For a selected upstream release, HMCL-macOS downloads the matching jar asset:

```text
HMCL-<version>.jar
```

If the release notes contain a SHA-256 checksum for the jar asset, the downloaded file is verified before packaging.

The macOS app icon is generated from the official upstream icon source:

```text
HMCL/src/main/resources/assets/img/icon-mac.png
```

## Packaging Policy

- `stable` is published as a normal GitHub Release in this repository.
- Every run explicitly syncs the repository release state as `prerelease=false` and `make_latest=true`.
- Public release tags use the upstream HMCL tag directly, without a `stable` prefix.

Each version release contains separate macOS DMG assets for supported architectures:

```text
HMCL-macOS-aarch64-<tag>.dmg
HMCL-macOS-x64-<tag>.dmg
```

## Licensing

HMCL is distributed under GPLv3 with upstream additional terms. This repository only automates macOS packaging and does not modify HMCL itself. Releases that include HMCL.jar should retain upstream source, license, and project links.
