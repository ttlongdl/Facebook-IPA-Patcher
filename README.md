# Facebook IPA Patcher

Build a sideload-ready **FB <version> Plus Plus.ipa** from a clean/decrypted Facebook IPA using GitHub Actions.

## What it does

- Downloads the clean Facebook IPA from the direct URL supplied to the workflow.
- Downloads the pinned **Facebook Plus v1.0.1-3 rootfull** package and verifies its SHA-256.
- Uses **cyan / pyzule-rw** to inject Facebook Plus into the main Facebook executable.
- Uses the libroot-free sideload build and lets cyan normalize/embed the required CydiaSubstrate framework.
- Keeps **AudioFix + DeepLinkBridge** integrated in FacebookPlus.dylib.
- Removes `UISupportedDevices` and registers the `fbbridge` URL scheme.
- Removes TrollFools backup leftovers.
- Installs the **Open in Facebook** Safari Web Extension.
- Verifies that FacebookPlus is injected, CydiaSubstrate is embedded, and no `libroot` dependency remains.
- Verifies the final ZIP and publishes **FB <version> Plus Plus.ipa** as both a workflow artifact and GitHub Release.

The output is intentionally left for your sideloading tool/certificate signer to sign. The workflow does not use cyan's TrollStore/AppSync fake-sign mode.

## Run it in your own fork

1. Fork this repository.
2. Open your fork's **Actions** tab and enable workflows if GitHub asks.
3. Open **Build Facebook Plus Plus IPA**.
4. Choose **Run workflow**.
5. Upload your clean/decrypted Facebook IPA to a temporary file host and paste its **direct-download URL**. **Filebin** (https://filebin.net) is a simple option: upload the IPA, open/copy the URL for the actual file (not just the bin page), and paste that URL into the workflow. Dropbox or another host is also fine as long as the URL downloads the IPA directly.
6. Run the workflow.
7. After all verification passes, get the resulting IPA from the workflow artifact or generated GitHub Release.
8. Sign/install the output with your normal sideloading method (for example Feather or SideStore).

> Do not commit or redistribute the clean Facebook IPA in this repository. Supply it to the workflow by direct URL. Treat temporary file hosts as link-accessible storage: do not upload signing certificates, passwords, provisioning profiles, or other sensitive files.

## Facebook Plus

The tweak source, jailbreak packages, sideload-neutral injection payload, releases, and changelog live in the companion **Facebook-Plus** repository:

https://github.com/ttlongdl/Facebook-Plus

Current pinned tweak build: **v1.0.1-3**.

## Verification

Publishing is blocked if the patcher detects a missing injection, missing CydiaSubstrate framework, a remaining `libroot` dependency, missing `fbbridge`, invalid Safari extension, TrollFools backup material, the obsolete standalone FBAudioFix dylib, or a corrupt output ZIP.
