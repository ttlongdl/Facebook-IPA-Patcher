import os, plistlib, subprocess, sys

app=sys.argv[1]
plist=os.path.join(app,'Info.plist')
with open(plist,'rb') as f:
    p=plistlib.load(f)

assert 'UISupportedDevices' not in p
schemes=[s for d in p.get('CFBundleURLTypes',[]) for s in d.get('CFBundleURLSchemes',[])]
assert 'fbbridge' in schemes

required=[
    os.path.join(app,'Frameworks','FacebookPlus.dylib'),
    os.path.join(app,'FacebookPlus.bundle'),
    os.path.join(app,'PlugIns','OpenInFacebookSafariExtension.appex'),
]
for x in required:
    assert os.path.exists(x), x

# No TrollFools backup material may survive packaging.
for root, dirs, files in os.walk(app):
    for name in dirs + files:
        low=name.lower()
        assert 'troll-fools-backup' not in low, os.path.join(root,name)
        assert not low.endswith('.bak'), os.path.join(root,name)
        assert not low.endswith('.backup'), os.path.join(root,name)

target=os.path.join(app,'Frameworks','FBSharedFramework.framework','FBSharedFramework')
out=subprocess.check_output(['otool','-L',target],text=True)
assert '@executable_path/Frameworks/FacebookPlus.dylib' in out

# v1.0.1-2 has AudioFix/DeepLinkBridge integrated; reject the old standalone
# AudioFix payload so we cannot accidentally regress to the previous chain.
assert not os.path.exists(os.path.join(app,'Frameworks','FBAudioFix-v0.3.14.dylib'))

ext_plist=os.path.join(app,'PlugIns','OpenInFacebookSafariExtension.appex','Info.plist')
with open(ext_plist,'rb') as f:
    ext=plistlib.load(f)
assert ext.get('NSExtension',{}).get('NSExtensionPointIdentifier') == 'com.apple.Safari.web-extension'

print('Verification OK: Plus 1.0.1-2 loaded, fbbridge present, Safari extension installed, backups removed')
