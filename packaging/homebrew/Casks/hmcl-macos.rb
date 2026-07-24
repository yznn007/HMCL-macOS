cask "hmcl-macos" do
  version "3.15.2"
  sha256 "REPLACE_WITH_DMG_SHA256"

  url "https://github.com/OWNER/HMCL-macOS/releases/download/v#{version}/HMCL-macOS-aarch64-v#{version}.dmg"
  name "HMCL-macOS"
  desc "macOS app bundle packaging for Hello Minecraft! Launcher"
  homepage "https://github.com/OWNER/HMCL-macOS"

  app "HMCL.app"

  zap trash: [
    "~/.hmcl",
    "~/Library/Application Support/hmcl",
  ]
end
