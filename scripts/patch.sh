#!/usr/bin/env bash
set -euo pipefail

IPA="${1:?Usage: patch.sh input.ipa}"
ROOT="$PWD/work"
rm -rf "$ROOT"
mkdir -p "$ROOT"
unzip -q "$IPA" -d "$ROOT"

APP="$(find "$ROOT/Payload" -maxdepth 1 -type d -name '*.app' -print -quit)"
test -n "$APP"
PLIST="$APP/Info.plist"
FRAMEWORKS="$APP/Frameworks"
PLUGINS="$APP/PlugIns"
test -f "$PLIST"
mkdir -p "$FRAMEWORKS" "$PLUGINS"

echo "App: $APP"

# Remove TrollFools backup files left in Frameworks.
find "$FRAMEWORKS" -type f \( -name '*.bak' -o -name '*.backup' \) -print -delete || true

# Remove device whitelist and register the proven fbbridge:// URL scheme.
/usr/libexec/PlistBuddy -c 'Delete :UISupportedDevices' "$PLIST" 2>/dev/null || true
python3 scripts/patch_plist.py "$PLIST"

# Replace Safari extension with pinned golden clean build.
rm -rf "$PLUGINS/OpenInFacebookSafariExtension.appex"
ditto assets/OpenInFacebookSafariExtension.appex "$PLUGINS/OpenInFacebookSafariExtension.appex"

# Copy pinned resource bundle. Dylibs are injected with insert_dylib below.
rm -rf "$APP/FacebookPlus.bundle"
ditto assets/FacebookPlus.bundle "$APP/FacebookPlus.bundle"
cp assets/FacebookPlus.dylib "$FRAMEWORKS/FacebookPlus.dylib"
cp assets/FBAudioFix-v0.3.14.dylib "$FRAMEWORKS/FBAudioFix-v0.3.14.dylib"

TARGET="$FRAMEWORKS/FBSharedFramework"
test -f "$TARGET"

inject_if_missing() {
  local dylib="$1"
  local load="@executable_path/Frameworks/$dylib"
  if otool -L "$TARGET" | grep -Fq "$load"; then
    echo "Already injected: $load"
  else
    insert_dylib --inplace --no-strip-codesig "$load" "$TARGET"
  fi
}

inject_if_missing "FacebookPlus.dylib"
inject_if_missing "FBAudioFix-v0.3.14.dylib"

# Verify the exact golden ingredients before packaging.
python3 scripts/verify.py "$APP"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST" 2>/dev/null || echo unknown)"
OUT="$PWD/Facebook-${VERSION}-Plus-DeepLink-AudioFix.ipa"
rm -f "$OUT"
(
  cd "$ROOT"
  zip -qry "$OUT" Payload
)
echo "OUTPUT=$OUT"
