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

TARGET="$(find "$FRAMEWORKS" -type f -name 'FBSharedFramework' -print -quit)"
if [ -z "$TARGET" ]; then
  echo "ERROR: FBSharedFramework binary not found under $FRAMEWORKS" >&2
  find "$FRAMEWORKS" -maxdepth 3 -print
  exit 1
fi
echo "Injection target: $TARGET"

inject_if_missing() {
  local dylib="$1"
  local load="@executable_path/Frameworks/$dylib"

  if otool -L "$TARGET" | grep -Fq "$load"; then
    echo "Already injected: $load"
    return 0
  fi

  echo ">>> Inject START: $dylib"
  # insert_dylib can hang on malformed/exhausted Mach-O headers. Kill it
  # deterministically so the workflow produces a useful failure instead of
  # burning the runner indefinitely.
  python3 - "$load" "$TARGET" <<'PY'
import subprocess, sys
load, target = sys.argv[1], sys.argv[2]
try:
    p = subprocess.run(
        ["insert_dylib", "--inplace", "--no-strip-codesig", load, target],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        timeout=30,
    )
except subprocess.TimeoutExpired as e:
    if e.stdout:
        print(e.stdout if isinstance(e.stdout, str) else e.stdout.decode(errors="replace"))
    print(f"ERROR: insert_dylib timed out after 30s for {load}", file=sys.stderr)
    sys.exit(124)

if p.stdout:
    print(p.stdout, end="" if p.stdout.endswith("\\n") else "\\n")
if p.returncode != 0:
    print(f"ERROR: insert_dylib exited {p.returncode} for {load}", file=sys.stderr)
    sys.exit(p.returncode)
PY
  echo ">>> Inject DONE: $dylib"

  if ! otool -L "$TARGET" | grep -Fq "$load"; then
    echo "ERROR: load command missing after injection: $load" >&2
    exit 1
  fi
}

inject_if_missing "FacebookPlus.dylib"
inject_if_missing "FBAudioFix-v0.3.14.dylib"
echo "Both dylib load commands verified."

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
