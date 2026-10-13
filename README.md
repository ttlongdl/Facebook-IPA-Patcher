# Facebook IPA Patcher

Build a sideload-ready **FB <version> Plus v<plus-version>.ipa** from a clean/decrypted Facebook IPA using GitHub Actions.

## What it does

- Downloads the clean Facebook IPA from the direct URL supplied to the workflow.
- Downloads the pinned **Facebook Plus v1.0.1-9 rootfull** release package and the **latest Rootless ShopeeBlocker.dylib** from [ShopeeBlocker releases](https://github.com/ttlongdl/ShopeeBlocker/releases). The selection filters version tags like `v0.1.4` and skips RootHide releases like `v0.1.4-roothide`, regardless of GitHub's Latest badge.
- Uses **cyan / pyzule-rw** to inject Facebook Plus **and ShopeeBlocker** into the main Facebook executable. ShopeeBlocker blocks accidental Shopee deep links and the correlated **Open in Shopee** popup while browsing Facebook.
- Uses the libroot-free sideload build and lets cyan normalize/embed the required CydiaSubstrate framework.
- Keeps **AudioFix + DeepLinkBridge** integrated in FacebookPlus.dylib.
- Removes `UISupportedDevices` and registers the `fbbridge` URL scheme.
- Removes TrollFools backup leftovers.
- Installs the **Open in Facebook** Safari Web Extension.
- Verifies that **both FacebookPlus and ShopeeBlocker** are embedded and linked into the Facebook executable, CydiaSubstrate is embedded, and no `libroot` dependency remains.
- Verifies the final ZIP and publishes **FB <version> Plus v<plus-version>.ipa** as both a workflow artifact and GitHub Release.

The output is intentionally left for your sideloading tool/certificate signer to sign. The workflow deliberately does **not** pass cyan's `-s` fake-sign option; testing confirmed `-s` did not fix the free-AltStore tweak-loading issue, which was instead resolved by the Facebook Plus v1.0.1-9 iOS 15 deployment target.

## Run it in your own fork

1. Fork this repository.
2. Open your fork's **Actions** tab and enable workflows if GitHub asks.
3. Open **Build Facebook Plus IPA**.
4. Choose **Run workflow**.
5. Upload your clean/decrypted Facebook IPA to a temporary file host and paste its **direct-download URL**. **Filebin** (https://filebin.net) is a simple option: upload the IPA, open/copy the URL for the actual file (not just the bin page), and paste that URL into the workflow. Dropbox or another host is also fine as long as the URL downloads the IPA directly.
6. Run the workflow.
7. After all verification passes, get the resulting IPA from the workflow artifact or generated GitHub Release.
8. Sign/install the output with your normal sideloading method (for example Feather or SideStore).

> Do not commit or redistribute the clean Facebook IPA in this repository. Supply it to the workflow by direct URL. Treat temporary file hosts as link-accessible storage: do not upload signing certificates, passwords, provisioning profiles, or other sensitive files.

## ShopeeBlocker

ShopeeBlocker is always on: if you accidentally tap a Shopee link while scrolling Facebook, it prevents the handoff to the Shopee app and suppresses the correlated in-app-browser popup (where tapping either OK or Cancel can otherwise open Shopee). The GitHub Actions workflow fetches `ShopeeBlocker.dylib` from the most recent **Rootless** versioned release that actually contains it. No pinned ShopeeBlocker version or manual dylib upload is needed. Updates to the ShopeeBlocker release will be picked up on the **next IPA build**; they do not change already-published Facebook IPAs.

Source and releases: https://github.com/ttlongdl/ShopeeBlocker

## Facebook Plus

The tweak source, jailbreak packages, sideload-neutral injection payload, releases, and changelog live in the companion **Facebook-Plus** repository:

https://github.com/ttlongdl/Facebook-Plus

Current pinned tweak build: **v1.0.1-9**.

## Verification

Publishing is blocked if the patcher detects a missing FacebookPlus or ShopeeBlocker injection, missing CydiaSubstrate framework, a remaining `libroot` dependency, missing `fbbridge`, invalid Safari extension, TrollFools backup material, the obsolete standalone FBAudioFix dylib, or a corrupt output ZIP.
