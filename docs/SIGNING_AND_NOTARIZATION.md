# Signing and Notarization

This project can build unsigned DMGs without Apple Developer credentials. For public distribution, signing and notarization are recommended.

Apple's notarization flow requires Developer ID signing and hardened runtime. See Apple's documentation:

- https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
- https://developer.apple.com/documentation/security/hardened-runtime

## Requirements

- Apple Developer Program membership.
- A `Developer ID Application` certificate installed in the build keychain.
- Xcode command line tools.
- A stored `notarytool` keychain profile.

Create a notarytool profile:

```bash
xcrun notarytool store-credentials HMCL_MACOS_NOTARY \
  --apple-id "APPLE_ID@example.com" \
  --team-id "TEAMID1234" \
  --password "app-specific-password"
```

## Manual Flow

Build the DMG:

```bash
./scripts/build-channel-dmg.sh --channel stable
```

Sign and notarize:

```bash
./scripts/sign-and-notarize.sh \
  --app dist/HMCL.app \
  --dmg dist/HMCL-macOS-stable-aarch64-vX.Y.Z.dmg \
  --identity "Developer ID Application: Your Name (TEAMID1234)" \
  --notary-profile HMCL_MACOS_NOTARY
```

The script:

1. Signs `HMCL.app` with hardened runtime.
2. Verifies the app signature.
3. Signs the DMG.
4. Submits the DMG to Apple's notary service.
5. Staples and validates the notarization ticket.

## GitHub Actions

For GitHub Actions, store certificates and notary credentials as repository secrets. A production workflow should import the Developer ID certificate into a temporary keychain before running `sign-and-notarize.sh`.

This repository does not include real signing credentials or Apple Developer account secrets.
