# Facebook IPA Patcher

Build a sideload-ready **FB <version> Plus Plus.ipa** from a clean Facebook IPA.

## Current patch set

- Downloads the clean Facebook IPA from a direct URL supplied to GitHub Actions.
- Downloads the pinned Facebook Plus **v1.0.1-2 Injection.zip** from the Facebook-Plus fork release.
- Injects `FacebookPlus.dylib` and installs `FacebookPlus.bundle`.
- Uses the v1.0.1-2 build where **AudioFix + DeepLinkBridge are integrated**.
- Removes `UISupportedDevices`.
- Registers the `fbbridge` URL scheme.
- Removes TrollFools backup leftovers (`troll-fools-backup`, `*.bak`, `*.backup`).
- Installs `OpenInFacebookSafariExtension.appex`.
- Reads `CFBundleShortVersionString` from the IPA and names the result:
  `FB <version> Plus Plus.ipa`.
- Verifies the patched app before packaging.
- Uploads a workflow artifact and publishes/updates a GitHub Release tagged
  `fb-<version>-plus-plus`.

## Run

1. Open **Actions → Build Facebook Plus Plus IPA**.
2. Choose **Run workflow**.
3. Paste a direct-download URL for a clean Facebook IPA.
4. Run it.
5. When all verification passes, get the IPA from the workflow artifact or the generated GitHub Release.

The workflow intentionally fails before publishing a release if injection, plist patching, extension installation, cleanup, or verification fails.
