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
  # Run insert_dylib in its own process group. Some failure paths can leave a
  # descendant holding stdout open, so subprocess.run(timeout=...) alone is
  # insufficient. Kill the entire process group after 30 seconds.
  python3 - "$load" "$TARGET" <<'PY'
import os, signal, subprocess, sys, time

load, target = sys.argv[1], sys.argv[2]
p = subprocess.Popen(
    ["insert_dylib", "--inplace", "--no-strip-codesig", load, target],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    start_new_session=True,
)

deadline = time.monotonic() + 30
while p.poll() is None and time.monotonic() < deadline:
    time.sleep(0.2)

if p.poll() is None:
    print(f"ERROR: insert_dylib hung for 30s: {load}", file=sys.stderr, flush=True)
    os.killpg(p.pid, signal.SIGKILL)
    try:
        out, _ = p.communicate(timeout=5)
    except subprocess.TimeoutExpired:
        out = ""
    if out:
        print(out, end="" if out.endswith("\n") else "\n")
    sys.exit(124)

out, _ = p.communicate()
if out:
    print(out, end="" if out.endswith("\n") else "\n")
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
echo "FacebookPlus load command verified in FBSharedFramework."

# FBSharedFramework has no room for a second LC_LOAD_DYLIB. Chain AudioFix
# through FacebookPlus instead: FBSharedFramework -> FacebookPlus -> AudioFix.
PLUS="$FRAMEWORKS/FacebookPlus.dylib"
AUDIO_LOAD="@executable_path/Frameworks/FBAudioFix-v0.3.14.dylib"
if otool -L "$PLUS" | grep -Fq "$AUDIO_LOAD"; then
  echo "AudioFix already chained through FacebookPlus."
else
  echo ">>> Chain AudioFix START: FacebookPlus.dylib -> FBAudioFix"
  printf 'y\n' | insert_dylib --inplace --no-strip-codesig "$AUDIO_LOAD" "$PLUS"
  echo ">>> Chain AudioFix DONE"
fi
otool -L "$PLUS" | grep -Fq "$AUDIO_LOAD" || {
  echo "ERROR: AudioFix dependency missing from FacebookPlus.dylib" >&2
  exit 1
}
echo "FacebookPlus + chained AudioFix verified."

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
