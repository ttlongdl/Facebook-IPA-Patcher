# Facebook IPA Patcher

One-shot patcher for a clean Facebook IPA dumped with TrollDecrypt.

## Golden patch set

- FacebookPlus dylib + resource bundle, with the working DeepLink bridge merged into FacebookPlus.
- Clean OpenInFacebookSafariExtension using `fbbridge://open?url=...`.
- FBAudioFix v0.3.14.

## Phone workflow

1. Dump a clean Facebook IPA.
2. Create a GitHub Release in this repository.
3. Attach the clean `.ipa` as a Release asset and publish it.
4. The `Patch Facebook IPA` workflow runs automatically.
5. Download `Facebook-<version>-Plus-DeepLink-AudioFix.ipa` from the same Release or the workflow artifact.

The patcher removes TrollFools `.bak` files from Frameworks, removes `UISupportedDevices`, registers `fbbridge`, installs the clean Safari extension, adds FacebookPlus resources, injects FacebookPlus + FBAudioFix into FBSharedFramework, verifies the result, and repacks the IPA.

Binary golden assets live under `assets/`.
