import os, plistlib, subprocess, sys
app=sys.argv[1]
plist=os.path.join(app,'Info.plist')
with open(plist,'rb') as f: p=plistlib.load(f)
assert 'UISupportedDevices' not in p
schemes=[s for d in p.get('CFBundleURLTypes',[]) for s in d.get('CFBundleURLSchemes',[])]
assert 'fbbridge' in schemes
required=[
 os.path.join(app,'Frameworks','FacebookPlus.dylib'),
 os.path.join(app,'Frameworks','FBAudioFix-v0.3.14.dylib'),
 os.path.join(app,'FacebookPlus.bundle'),
 os.path.join(app,'PlugIns','OpenInFacebookSafariExtension.appex'),
]
for x in required: assert os.path.exists(x), x
target=os.path.join(app,'Frameworks','FBSharedFramework.framework','FBSharedFramework')
out=subprocess.check_output(['otool','-L',target],text=True)
assert '@executable_path/Frameworks/FacebookPlus.dylib' in out
plus=os.path.join(app,'Frameworks','FacebookPlus.dylib')
plus_out=subprocess.check_output(['otool','-L',plus],text=True)
assert '@executable_path/Frameworks/FBAudioFix-v0.3.14.dylib' in plus_out
print('Verification OK: FBSharedFramework -> FacebookPlus -> FBAudioFix')
