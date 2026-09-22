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

# Remove TrollFools leftovers anywhere inside the app, including the literal
# troll-fools-backup naming used by some injection paths.
find "$APP" \( -iname '*troll-fools-backup*' -o -iname '*.bak' -o -iname '*.backup' \) -print -exec rm -rf {} + 2>/dev/null || true

# Remove device whitelist and register fbbridge://.
python3 scripts/patch_plist.py "$PLIST"

# Install the clean Safari Web Extension.
rm -rf "$PLUGINS/OpenInFacebookSafariExtension.appex"
ditto assets/safari/OpenInFacebookSafariExtension.appex "$PLUGINS/OpenInFacebookSafariExtension.appex"

# Install the v1.0.1-2 injection payload. AudioFix + DeepLinkBridge are already
# integrated in this FacebookPlus build, so there is no second AudioFix dylib.
rm -rf "$APP/FacebookPlus.bundle"
ditto assets/injection/FacebookPlus.bundle "$APP/FacebookPlus.bundle"
cp assets/injection/FacebookPlus.dylib "$FRAMEWORKS/FacebookPlus.dylib"

TARGET="$(find "$FRAMEWORKS" -type f -name 'FBSharedFramework' -print -quit)"
if [ -z "$TARGET" ]; then
  echo "ERROR: FBSharedFramework binary not found under $FRAMEWORKS" >&2
  exit 1
fi
echo "Injection target: $TARGET"

LOAD="@executable_path/Frameworks/FacebookPlus.dylib"
if otool -L "$TARGET" | grep -Fq "$LOAD"; then
  echo "Already injected: $LOAD"
else
  python3 - "$LOAD" "$TARGET" <<'PY'
import os, signal, subprocess, sys, time
load, target = sys.argv[1], sys.argv[2]
p = subprocess.Popen(
    ["insert_dylib", "--inplace", "--no-strip-codesig", load, target],
    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
    start_new_session=True,
)
deadline = time.monotonic() + 30
while p.poll() is None and time.monotonic() < deadline:
    time.sleep(0.2)
if p.poll() is None:
    os.killpg(p.pid, signal.SIGKILL)
    out, _ = p.communicate()
    if out: print(out)
    raise SystemExit("ERROR: insert_dylib timed out")
out, _ = p.communicate()
if out: print(out, end="" if out.endswith("\n") else "\n")
if p.returncode:
    raise SystemExit(p.returncode)
PY
fi

otool -L "$TARGET" | grep -Fq "$LOAD" || {
  echo "ERROR: FacebookPlus load command missing after injection" >&2
  exit 1
}

python3 scripts/verify.py "$APP"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
test -n "$VERSION"
OUT="$PWD/FB $VERSION Plus Plus.ipa"
rm -f "$OUT"
(
  cd "$ROOT"
  zip -qry "$OUT" Payload
)
echo "Built: $OUT"
