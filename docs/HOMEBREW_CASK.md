# Homebrew Cask Distribution

Homebrew Cask can install a DMG that contains an `.app` bundle. The official Homebrew Cask Cookbook documents the declarative cask format:

- https://docs.brew.sh/Cask-Cookbook

## Template

A starter cask is provided at:

```text
packaging/homebrew/Casks/hmcl-macos.rb
```

Before publishing a tap:

1. Replace `OWNER` with the GitHub owner.
2. Replace `REPO` if the repository name changes.
3. Set `version` to the stable HMCL version.
4. Set `sha256` to the DMG checksum.
5. Test with `brew install --cask --verbose ./packaging/homebrew/Casks/hmcl-macos.rb`.

## Stable Channel

The included cask targets the `stable` channel and the Apple Silicon (`aarch64`) artifact. `dev` builds are prereleases in this repository and should generally be exposed through a separate cask only if you intentionally want Homebrew users to install them.

Example names:

```text
hmcl-macos
hmcl-macos-intel
hmcl-macos-dev
```
