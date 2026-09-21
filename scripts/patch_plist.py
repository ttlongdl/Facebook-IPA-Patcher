import plistlib, sys

path=sys.argv[1]
with open(path,'rb') as f:
    p=plistlib.load(f)

p.pop('UISupportedDevices', None)
types=p.setdefault('CFBundleURLTypes', [])
if not types:
    types.append({'CFBundleURLSchemes': []})

all_schemes=[]
for item in types:
    all_schemes.extend(item.get('CFBundleURLSchemes', []))

if 'fbbridge' not in all_schemes:
    target=None
    for item in types:
        schemes=item.get('CFBundleURLSchemes')
        if isinstance(schemes,list) and ('fb' in schemes or 'fb-www-link' in schemes):
            target=item
            break
    if target is None:
        target=types[0]
    target.setdefault('CFBundleURLSchemes', []).append('fbbridge')

with open(path,'wb') as f:
    plistlib.dump(p,f,fmt=plistlib.FMT_BINARY,sort_keys=False)

print('fbbridge registered; UISupportedDevices removed')
