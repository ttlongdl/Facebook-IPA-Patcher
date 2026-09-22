import os, plistlib, subprocess, sys

app = sys.argv[1]
plist = os.path.join(app, 'Info.plist')
with open(plist, 'rb') as f:
    p = plistlib.load(f)

assert 'UISupportedDevices' not in p
schemes = [s for d in p.get('CFBundleURLTypes', []) for s in d.get('CFBundleURLSchemes', [])]
assert 'fbbridge' in schemes

frameworks = os.path.join(app, 'Frameworks')
plus = os.path.join(frameworks, 'FacebookPlus.dylib')
bundle = os.path.join(app, 'FacebookPlus.bundle')
appex = os.path.join(app, 'PlugIns', 'OpenInFacebookSafariExtension.appex')
for x in (plus, bundle, appex):
    assert os.path.exists(x), x

# No TrollFools backup material may survive packaging.
for root, dirs, files in os.walk(app):
    for name in dirs + files:
        low = name.lower()
        assert 'troll-fools-backup' not in low, os.path.join(root, name)
        assert not low.endswith('.bak'), os.path.join(root, name)
        assert not low.endswith('.backup'), os.path.join(root, name)

# The sideload payload itself must be libroot-free.
plus_deps = subprocess.check_output(['otool', '-L', plus], text=True)
assert 'libroot' not in plus_deps, plus_deps

# cyan should normalize the substrate dependency and embed its framework.
assert 'CydiaSubstrate.framework/CydiaSubstrate' in plus_deps, plus_deps
substrate = os.path.join(frameworks, 'CydiaSubstrate.framework', 'CydiaSubstrate')
assert os.path.isfile(substrate), substrate

# cyan injects into the main app executable, not FBSharedFramework.
exe_name = p['CFBundleExecutable']
main_exe = os.path.join(app, exe_name)
assert os.path.isfile(main_exe), main_exe
main_deps = subprocess.check_output(['otool', '-L', main_exe], text=True)
assert 'FacebookPlus.dylib' in main_deps, main_deps

# Reject unresolved libroot anywhere in Mach-O dependencies under the app.
bad = []
for root, _, files in os.walk(app):
    for name in files:
        path = os.path.join(root, name)
        try:
            deps = subprocess.check_output(['otool', '-L', path], text=True, stderr=subprocess.DEVNULL)
        except (subprocess.CalledProcessError, OSError):
            continue
        if 'libroot' in deps:
            bad.append(path)
assert not bad, 'libroot dependency remains in: ' + ', '.join(bad)

# AudioFix/DeepLinkBridge are integrated into FacebookPlus.dylib.
assert not os.path.exists(os.path.join(frameworks, 'FBAudioFix-v0.3.14.dylib'))

# SideStore/free-account build must carry exactly one extension: our Safari bridge.
plugins = os.path.join(app, 'PlugIns')
appexes = []
if os.path.isdir(plugins):
    appexes = sorted(
        name for name in os.listdir(plugins)
        if name.endswith('.appex') and os.path.isdir(os.path.join(plugins, name))
    )
assert appexes == ['OpenInFacebookSafariExtension.appex'], appexes

ext_plist = os.path.join(appex, 'Info.plist')
with open(ext_plist, 'rb') as f:
    ext = plistlib.load(f)
assert ext.get('NSExtension', {}).get('NSExtensionPointIdentifier') == 'com.apple.Safari.web-extension'

print('Verification OK: Plus 1.0.1-3 is libroot-free, cyan main injection present, substrate embedded, only the Safari bridge extension retained')
