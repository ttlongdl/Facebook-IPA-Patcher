# Facebook IPA Patcher — Triple-Tweak (release-driven)

Build a sideload-ready Facebook IPA from your own decrypted Facebook IPA with **three independent rootless DEBs**:

- [Facebook Plus](https://github.com/ttlongdl/Facebook-Plus) **v1.0.4-1** (pinned and verified against the published release tag and `control` version)
- [FBAudioFix](https://github.com/ttlongdl/FBAudioFix) — **stable 0.3.20**, built from the repository's main branch (including its standalone diagnostic logging)
- [ShopeeBlocker](https://github.com/ttlongdl/ShopeeBlocker) — standalone, built from its repository's current main branch

The [Build Facebook Plus Triple-Tweak IPA](.github/workflows/patch-facebook.yml) workflow is based on the successfully tested cyan three-DEB pipeline from Facebook-Plus. It also builds and injects the **Open in Facebook Safari extension** and custom icons. **FBAudioFix is not integrated into FBPlus**.

## Build and install

1. Open [Actions → Build Facebook Plus Triple-Tweak IPA](https://github.com/ttlongdl/Facebook-IPA-Patcher/actions/workflows/patch-facebook.yml) and select **Run workflow** on `main`.
2. Paste a direct download URL to your own decrypted Facebook IPA. Optionally enter a custom bundle ID.
3. After success, download `Facebook-Plus-Triple-Tweak` from the workflow artifacts, or the IPA from the versioned GitHub Release.
4. Sign the IPA, **including its Safari app extension**, with Feather or another compatible signer. Test Facebook, FBPlus settings, FBAudioFix, Shopee blocking, Story/Reels downloads and the Safari extension on-device.

For this release, the output IPA is named `FB <Facebook-version> Plus v1.0.4-1.ipa` and must be signed for installation. The workflow creates a versioned release tag of the form `fb-<facebook-version>-plus-v<FBPlus-version>-triple-build-<run-number>` **only after** successful injection and ZIP validation.

## CI and version integrity

The pipeline checks out the latest published FBPlus release tag, requires **v1.0.4-1**, verifies it matches the FBPlus `control` version, builds its rootless DEB, and verifies the embedded DEB Version matches `control`. It builds FBAudioFix from its main branch and requires both `control` and the built DEB to report stable version `0.3.20`; ShopeeBlocker is also built from its main branch. All three are passed together to cyan, alongside the Safari extension and icon metadata. The workflow fails if expected DEBs or the Safari extension are missing. It validates the output ZIP before publishing.

**Status (2026-11-03):** Facebook Plus v1.0.4-1 was synced upstream-first from v1.0.4, and the Triple-Tweak test workflow on `3rdnext` commit `5ddd08a` passed build, injection and Files-sharing verification. The user successfully installed and signed the IPA and tested Facebook login, two-level settings, Vietnamese, Story photo/video (including delayed video), Reels/Cinema Mode, Safari Open in Facebook, FBAudioFix audio, ShopeeBlocker and Files sharing. Independent Like Feed/Reels confirmation and Ads/Suggested filtering remain **not fully tested**. The patcher creates a **new versioned IPA release** when manually run after the Facebook Plus v1.0.4-1 DEB release; the older Facebook 585.0.0 + v1.0.3-1 release remains historical.

**Sync Feather Source:** After the IPA release is published, run [Sync Feather Source](https://github.com/ttlongdl/Facebook-IPA-Patcher/actions/workflows/sync-feather-source.yml) on `main`. It requires the latest published non-prerelease `fb-*` release to use **FBPlus v1.0.4-1**, validates the IPA filename and matches the current Facebook Plus DEB release, then updates the Facebook entry in [`ttlongdl/feather/personal-source.json`](https://github.com/ttlongdl/feather/blob/main/personal-source.json), preserves other apps, and verifies the remote update. The repository secret `SOURCE_REPO_TOKEN` must have **Contents: read/write** access to `ttlongdl/feather`. IPA build and Feather sync remain separate manual workflows. **Do not run Sync Feather Source until the new IPA build and its GitHub Release succeed.** For future FBPlus upgrades, update the version pins in `patch-facebook.yml` and `sync-feather-source.yml` together.

## Legacy files

`scripts/patch.sh`, `scripts/verify.py`, and the bundled legacy Safari extension ZIP belong to the **previous rootfull/integrated-audio pipeline**. They are retained only for historical reference and **are not invoked** by the new workflow. Do not run the old script to produce a new triple-tweak IPA.

## Security and distribution

Use only IPA files you have permission to modify. Do not commit an IPA, Apple signing certificates, provisioning profiles, or secrets. The workflow's URL is masked in logs; temporary download links can still be accessible to anyone who possesses them. GitHub Releases may make generated IPA files publicly accessible.

## Related projects

- [Facebook-Plus](https://github.com/ttlongdl/Facebook-Plus) — upstream-first FBPlus and versioned DEBs
- [FBAudioFix](https://github.com/ttlongdl/FBAudioFix) — independent audio tweak
- [ShopeeBlocker](https://github.com/ttlongdl/ShopeeBlocker) — independent link-blocking tweak
- [Feather personal source](https://github.com/ttlongdl/feather) — optional personal IPA source

The existing `Sync Feather Source` workflow remains separate; building an IPA does not automatically update the Feather source.
