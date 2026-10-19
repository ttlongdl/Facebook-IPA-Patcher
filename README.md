# Facebook IPA Patcher

Build a sideload-ready **`FB <Facebook-version> Plus v<Plus-version>.ipa`** from a clean/decrypted Facebook IPA using GitHub Actions, **cyan / pyzule-rw**, Facebook Plus, and ShopeeBlocker.

> **Build status:** This README describes the current workflow. The updated automatic Facebook Plus release selection has not yet been validated by a successful end-to-end IPA build. A successful DEB build does not by itself guarantee that the injected IPA launches correctly.

## Features

- Downloads a clean Facebook IPA from the direct URL supplied when starting the workflow; no Facebook IPA is stored in this repository.
- Resolves the **latest published Facebook-Plus release** and downloads its matching **rootfull** DEB. It checks that the release contains the expected asset and that the DEB's embedded version matches the release tag. No pinned Facebook Plus version is needed.
- Downloads `ShopeeBlocker.dylib` from the newest matching **Rootless, versioned** ShopeeBlocker release that contains the asset; excludes tags with RootHide suffixes.
- Uses **cyan / pyzule-rw** to inject FacebookPlus and ShopeeBlocker into the **main Facebook executable**. ShopeeBlocker is intended to prevent accidental Shopee app handoffs and related “Open in Shopee” prompts while browsing Facebook.
- Embeds/normalizes CydiaSubstrate dependencies for sideloading and verifies that no `libroot` Mach-O dependency remains.
- Retains the integrated **FBAudioFix / DeepLinkBridge** logic in FacebookPlus; rejects standalone `FBAudioFix*.dylib` files in the app's `Frameworks` directory to avoid duplicate hooks.
- Registers `fbbridge://`, removes `UISupportedDevices`, and removes TrollFools backup leftovers.
- Removes the original app extensions and installs only the bundled **Open in Facebook** Safari Web Extension, reducing the extension/App ID footprint for sideloading.
- Verifies dylib links, embedded framework, Safari extension, bundle contents, and IPA ZIP integrity.
- Uploads the IPA as a GitHub Actions artifact (7-day retention) and publishes a GitHub Release tagged with Facebook, Facebook Plus, ShopeeBlocker versions and the workflow run number.

**Signing:** The workflow intentionally does **not** sign the resulting IPA or pass cyan's `-s` option. Sign/install it using Feather, SideStore, or another compatible signing method. Signing compatibility and runtime behavior still require on-device testing.

## Build an IPA

1. Open [Build Facebook Plus IPA](https://github.com/ttlongdl/Facebook-IPA-Patcher/actions/workflows/patch-facebook.yml) and select **Run workflow** on `main`.
2. Supply `ipa_url`: a **direct download link** to a clean/decrypted Facebook IPA. The link must return the actual IPA archive, not a webpage, login prompt, or redirect to an inaccessible file.
3. Wait for **Patch and verify IPA**, **Upload workflow artifact**, and **Publish GitHub Release** to succeed.
4. Download the resulting `FB <Facebook-version> Plus v<Plus-version>.ipa` from the run's artifact or [Releases](https://github.com/ttlongdl/Facebook-IPA-Patcher/releases).
5. Sign and install the IPA using your normal sideloading tool; test Facebook startup, login, feed/reels/story audio, downloading, Shopee link blocking, and the Safari bridge on your device.

The workflow installs `ldid` with Homebrew and installs cyan from the current upstream `pyzule-rw` source using `pipx`. Because this upstream installation is not pinned to a commit, upstream changes may affect future builds.

> **Privacy and distribution:** Do not commit or redistribute a clean Facebook IPA in this repository. Only use IPA files you are authorized to modify. Temporary file-host links may be accessible to anyone who has the URL; never upload signing certificates, provisioning profiles, Apple ID credentials, or other secrets.

## Facebook Plus release selection

Source: [ttlongdl/Facebook-Plus](https://github.com/ttlongdl/Facebook-Plus)

The patcher uses the latest published GitHub Release, not the latest commit or a GitHub Actions artifact. The release must contain:

```text
Facebook-Plus-v<VERSION>-rootfull.deb
```

The embedded DEB `Version` must exactly equal `<VERSION>`. If the release is missing its rootfull asset or its metadata disagrees, the workflow **fails instead of silently falling back** to an older tweak.

For **Facebook Plus v1.0.2-1**, the companion release must contain `Facebook-Plus-v1.0.2-1-rootfull.deb`. The rootless DEB is intended for jailbreak package managers, **not** IPA injection. Do not run the IPA patcher until that release has been published with the rootfull asset.

## ShopeeBlocker

Source: [ttlongdl/ShopeeBlocker](https://github.com/ttlongdl/ShopeeBlocker)

The workflow searches version tags such as `v0.1.4` and selects the first matching release containing `ShopeeBlocker.dylib`. It skips RootHide-suffixed releases. A newly published compatible ShopeeBlocker asset is picked up on the **next** IPA build; existing IPA releases are unchanged.

## Verification and limitations

The patcher checks:

- `FacebookPlus.dylib` and `ShopeeBlocker.dylib` exist and are linked into the main executable.
- `CydiaSubstrate.framework` exists and both tweak libraries link to it.
- No Mach-O library under the app has an unresolved `libroot` dependency.
- `fbbridge` is registered, `UISupportedDevices` is removed, and TrollFools backup files are absent.
- Only `OpenInFacebookSafariExtension.appex` remains, with the expected Safari extension identifier.
- No separate `FBAudioFix*.dylib` exists under `Frameworks`.
- The generated IPA passes `unzip -tq`.

These checks validate packaging and dependency structure; they **do not prove** that every tweak hook works, that signing succeeds, or that Facebook will not crash on a particular iOS/Facebook version.

## Feather personal source

After a successful IPA GitHub Release, you can manually run [Sync Feather Source](https://github.com/ttlongdl/Facebook-IPA-Patcher/actions/workflows/sync-feather-source.yml). It selects the latest eligible published IPA release and updates `ttlongdl/feather` → `personal-source.json`.

This separate workflow requires the `SOURCE_REPO_TOKEN` repository secret with appropriate write access to the Feather source repository. **Building an IPA does not automatically sync Feather.**

## Related repositories

- [Facebook-Plus](https://github.com/ttlongdl/Facebook-Plus) — tweak source and rootfull/rootless DEB releases.
- [ShopeeBlocker](https://github.com/ttlongdl/ShopeeBlocker) — Shopee link-blocking dylib releases.
- [Feather personal source](https://github.com/ttlongdl/feather) — optional sideload app source updated by the separate sync workflow.
