# Inclusion policy, in practice

Authoritative: https://f-droid.org/docs/Inclusion_Policy/ and
https://f-droid.org/docs/Anti-Features/ . Read them at the time; policy changes. Marks as in
`process.md`.

## What gets an app rejected [docs]

- **Not FOSS.** Needs an OSI/FSF-style free licence (MIT, GPL, Apache-2.0, ...). "Source
  available", non-commercial or no-licence code is out.
- **Non-free dependencies in the build.** Google Play Services / Firebase / Crashlytics, closed
  ad and analytics SDKs, proprietary maps. These are scanned in source and in binaries.
- **Pre-built binaries in the repo or fetched at build time** that aren't built from source.
  The scanner flags `.so`, `.jar`, `.aar` blobs; a few well-known ones (Hermes compiler) are
  allowed through `scanignore`, file by file.
- **Can't be built reproducibly or at all** from the repo on the build server.
- **Duplicates** an existing app with no clear difference (the MR asks you why yours is
  different).

## Anti-features (disclosed, not blocking)

If the app does these, they're listed on the app page. They go in the recipe's `AntiFeatures:`
field and are the reviewer's call. Common ones: `Ads`, `Tracking`, `NonFreeNet` (depends on a
closed network service), `NonFreeAdd`, `NonFreeDep`, `UpstreamNonFree`, `KnownVuln`,
`NoSourceSince`. An app with none is the goal.

## Permissions

Reviewers and testers compare the manifest with what the app does. [seen]
- Drop permissions the app doesn't use. Frameworks add them silently (Expo/RN: `INTERNET`,
  `RECORD_AUDIO`, `SYSTEM_ALERT_WINDOW`, storage; media players: `ACCESS_NETWORK_STATE`).
- An "offline, no network" claim must match: no `INTERNET`, no sockets, links open in the system
  browser.
- State the final permission list in the changelog or privacy text if the app makes promises.

## Metadata expectations [docs]

- Upstream repo has fastlane metadata (summary, description, icon, changelog, screenshots,
  `en-US`).
- An issue tracker and a way to contact the author.
- Releases are tagged and auto-update is on, unless there's a stated reason.
- Not required but valued: a privacy statement, screenshots of the real app, a README that says
  what it is.

## Judgment calls to put to the user, not decide

- Whether to accept an anti-feature rather than remove the dependency.
- Whether to keep a feature that needs a permission the reviewer questions.
- Whether the app is similar enough to an existing F-Droid app to need a justification.
