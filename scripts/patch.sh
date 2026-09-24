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

# SideStore-friendly extension policy: remove every extension carried by the
# original Facebook IPA, then install only our Open in Facebook Safari extension.
# This keeps the App ID / extension footprint minimal for free Apple IDs.
rm -rf "$PLUGINS"
mkdir -p "$PLUGINS"
ditto assets/safari/OpenInFacebookSafariExtension.appex "$PLUGINS/OpenInFacebookSafariExtension.appex"

# Hard guard: the packaged app must contain exactly one .appex.
APPEX_COUNT="$(find "$PLUGINS" -maxdepth 1 -type d -name '*.appex' | wc -l | tr -d ' ')"
ONLY_APPEX="$(find "$PLUGINS" -maxdepth 1 -type d -name '*.appex' -print -quit)"
if [ "$APPEX_COUNT" -ne 1 ] || [ "$(basename "$ONLY_APPEX")" != "OpenInFacebookSafariExtension.appex" ]; then
  echo "ERROR: expected only OpenInFacebookSafariExtension.appex under PlugIns" >&2
  find "$PLUGINS" -maxdepth 1 -type d -name '*.appex' -print >&2 || true
  exit 1
fi

python3 scripts/verify.py "$APP"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
test -n "$VERSION"
PLUS_VERSION="${PLUS_VERSION:-1.0.1-4}"
OUT="$PWD/FB $VERSION Plus v$PLUS_VERSION.ipa"
rm -f "$OUT"
(
  cd "$ROOT"
  zip -qry "$OUT" Payload
)
unzip -tq "$OUT" >/dev/null
echo "Built: $OUT"
