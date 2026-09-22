#!/usr/bin/env bash
set -euo pipefail

IPA="${1:?Usage: patch.sh input.ipa}"
ROOT="$PWD/work"
CYAN_OUT="$RUNNER_TEMP/facebook-cyan.ipa"
rm -rf "$ROOT" "$CYAN_OUT"

# Let cyan/pyzule-rw do the Mach-O work: extract the rootfull DEB, normalize
# jailbreak dependencies (notably CydiaSubstrate), embed required frameworks,
# add the Frameworks rpath and weak-inject FacebookPlus into the main executable.
# Deliberately do NOT pass -s: the final IPA is signed later by Feather/SideStore.
cyan -i "$IPA" -o "$CYAN_OUT" -f assets/FacebookPlus-rootfull.deb -u
unzip -tq "$CYAN_OUT" >/dev/null
mkdir -p "$ROOT"
unzip -q "$CYAN_OUT" -d "$ROOT"

APP="$(find "$ROOT/Payload" -maxdepth 1 -type d -name '*.app' -print -quit)"
test -n "$APP"
PLIST="$APP/Info.plist"
PLUGINS="$APP/PlugIns"
test -f "$PLIST"
mkdir -p "$PLUGINS"

echo "App: $APP"

# Remove injection leftovers/backups if the input IPA carried any.
find "$APP" \( -iname '*troll-fools-backup*' -o -iname '*.bak' -o -iname '*.backup' \) -print -exec rm -rf {} + 2>/dev/null || true

# Register fbbridge:// after cyan has completed its app rewrite.
python3 scripts/patch_plist.py "$PLIST"

# Install the clean Safari Web Extension last so cyan cannot remove it.
rm -rf "$PLUGINS/OpenInFacebookSafariExtension.appex"
ditto assets/safari/OpenInFacebookSafariExtension.appex "$PLUGINS/OpenInFacebookSafariExtension.appex"

python3 scripts/verify.py "$APP"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
test -n "$VERSION"
OUT="$PWD/FB $VERSION Plus Plus.ipa"
rm -f "$OUT"
(
  cd "$ROOT"
  zip -qry "$OUT" Payload
)
unzip -tq "$OUT" >/dev/null
echo "Built: $OUT"
