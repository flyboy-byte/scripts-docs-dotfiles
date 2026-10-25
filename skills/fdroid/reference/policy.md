# Inclusion policy, in practice

Authoritative and current: https://f-droid.org/docs/Inclusion_Policy/ and
https://f-droid.org/docs/Anti-Features/ . Re-read them when it matters; the sections below were
checked against them on 2026-10-25. Marks as in `process.md`.

## Hard requirements [docs]

- **Free software licence.** FLOSS as judged by DFSG / FSF / OSI (via SPDX). Artwork and fonts
  may use looser licences but must allow redistribution and be validly licensed or public domain.
- **A FLOSS build toolchain.** Debian-packaged tools; proprietary build tools (e.g. Oracle JDK,
  some pre-release toolchains) are forbidden.
- **No proprietary tracking, ads or analytics libraries**: Google Play Services, Firebase,
  Crashlytics, closed ad/tracking SDKs. Offer a FLOSS alternative or a flavour without them.
- **Prebuilt binaries only from allowed sources.** Debian main; Maven Central, Google Maven,
  OSS Sonatype, OSS JFrog, JitPack, Clojars (the binary must still be freely licensed, being in
  the repository is not enough); the Android SDK, Flutter SDK and Hermes may use their official
  prebuilts; PyPI wheels, Nix cache, Rust/rustup, Go and Node.js are acceptable, and Debian
  packages are preferred wherever possible. Everything else comes from source.
- **No API keys signed up by F-Droid.** Keys supplied by a third party get included in both
  binaries and source.
- **Donation links must be verified by upstream** (funding file, README, same-account message, or
  the app's own website).
- **No infringement.** Trademarks and copyrights; a clashing application ID (matching someone
  else's domain) is rejected automatically.
- **No downloading executable code without opt-in consent** (add-ons, self-update). Consent must
  be as easy to decline as to accept and must say it bypasses F-Droid's checks.
- **Application ID**: unique; preferably from a domain you own. A fork needs a fresh ID plus new
  name, icon and strings.

## Quality bar (reviewers apply judgment) [docs]

- Actively maintained, and the author commits to maintaining it.
- Works and implements what the description says. Wrappers of websites should add native
  features. No demos.
- Provides unique value over similar apps already in the repo. Rebrands with no improvement are out.
- Actively developed for **at least 3 months**, unless it has proven users, the author already
  maintains other F-Droid apps, or it was built for an event.
- Suitable for all users including children; historical precedent counts.

## Anti-features (disclosed, not necessarily blocking) [docs]

Set in the recipe's `AntiFeatures:` (whole app) or a build's `antifeatures:` (one version).
Explain the reason in the app's description. Current list from the metadata reference:

| Value | Meaning |
| --- | --- |
| `Ads` | contains advertising |
| `KnownVuln` | known security vulnerability found by the scanners |
| `NonFreeAdd` | promotes non-free add-ons |
| `NonFreeAssets` | non-free media (CC-NC, CC-ND art, sounds, ...) |
| `NonFreeDep` | needs a non-free app installed (not bundled) |
| `NonFreeNet` | promotes or depends entirely on a proprietary network service |
| `TetheredNet` | depends entirely on one hard-to-replace service instance (no simple setting to point it elsewhere) |
| `Tracking` | tracks or reports activity by default, or a feature can't be used without sharing data (including crash-log upload and update checks without permission); opt-in and off by default avoids it |
| `NoSourceSince` | upstream source no longer available |
| `NSFW` | content the user may not want visible everywhere |

The anti-features page also lists `DisabledAlgorithm` (signed with an unsafe algorithm). The
lists drift; check the page before assigning one.

## Permissions [seen]

Reviewers and testers compare the permission list in the Code Quality report with what the app
does.
- Remove permissions the app doesn't use. Frameworks add them silently (Expo/RN: `INTERNET`,
  `RECORD_AUDIO`, `SYSTEM_ALERT_WINDOW`, storage; media players: `ACCESS_NETWORK_STATE`).
- If `INTERNET` is declared, a tester will watch the network (PCAPdroid). No traffic observed
  means "remove the permission"; traffic at start means `NonFreeNet`/`TetheredNet` may apply.
- Runtime permissions should be requested when the feature is used, not at first launch.
  `MANAGE_EXTERNAL_STORAGE` is questioned; use the Storage Access Framework.
- State the final list in the changelog or privacy text if the app makes promises.

## Metadata expectations [docs]

- Fastlane/Triple-T metadata in the app repo (`en-US` required) with summary, description, icon,
  changelog; screenshots are valued.
- An issue tracker and a way to contact the author.
- Releases tagged and auto-update on, unless there's a stated reason.
- English support, or declare the lack in the description.
- No terms to accept beyond the FOSS licence. Don't add an in-app webview where opening the
  browser would do.

## Judgment calls to put to the user, not decide

- Accepting an anti-feature rather than removing the dependency.
- Keeping a feature that needs a permission the reviewer questions.
- Whether the app is similar enough to an existing F-Droid app to need a justification.
- Whether to give up reproducible builds (see `signing-keys.md`: that choice is permanent).
