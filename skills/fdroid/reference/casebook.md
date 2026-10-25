# Casebook: three real submissions

Anonymized. Each shows what the process actually looks like, including dead ends. Marks as in
`process.md`. Dates are real; people are described by role.

## Case A: Expo/React Native game, accepted, now on auto-update

Offline reaction-timer app, Expo SDK 54 / RN 0.81, npm, four ABI splits, own signing key,
reproducible.

- **Inclusion MR, ~2 weeks of iteration, merged 2026-09-28.** The reviewer's first message was
  "follow the template"; asked which parts, the answer was "every part". That meant: keep
  `npx expo prebuild -p android --clean`, patch JDK 17→21 as the template does, `scandelete:
  node_modules`, `scanignore` as single files (not packages), and for pnpm a hoisted layout so
  paths read `node_modules/...`. Then: "add `Binaries` and `AllowedAPKSigningKeys`".
- **The reproducibility dead end.** The first reference APK came from a cloud build of the same
  source. The reviewer: "your apk is built from a different source code. You need to apply the same
  patch first." Six local container attempts later four root causes were fixed (LAN IP in
  `resources.arsc`, `GRADLE_USER_HOME` path in `.so` files, Glide's random generated class name in
  dex, and `apksigner`'s `0xD935` padding conversion). The last one is what the two-run process
  removes: sign F-Droid's own unsigned APK with `--alignment-preserved true`.
- **ABI splits** were requested after the universal build passed ("now there are 4 large universal
  apks", then explicit size numbers). `abiFilters` silently produced universal APKs;
  `android.splits.abi` worked.
- **A tester review** found unused permissions (INTERNET, RECORD_AUDIO, SYSTEM_ALERT_WINDOW,
  storage). Fixed with `blockedPermissions` in app config, released as the next version.
- **Updates since:** the bot picks up the tag and commits the new blocks, no MR. Each release:
  bump, changelogs for the four final codes, fork Run 1, sign, GitHub release (creates the tag),
  Run 2, done. Releases 1.7.4 (2026-10-09) and 1.8.0 (2026-10-19) went out this way.
- **A surprise after the fork was green:** a maintainer added a sed removing the foojay toolchain
  resolver from the RN Gradle plugin, because the real build server is offline. Fork CI had never
  shown it. All four builds then verified and were listed on f-droid.org about five days after the
  tag.

## Case B: second Expo app by the same author, in review

Local-first catalog app, Expo SDK 57 / RN 0.86, monorepo (`subdir: app/android/app`), two ABIs.

- Reused Case A's recipe almost verbatim; differences were app-specific only (paths prefixed
  with `app/`, extra `scanignore` files, JDK seds for two animation libraries, two ABI blocks).
  It reached a green pipeline fast. [seen]
- Reviewer requests so far: enable R8 (done through a config plugin; `size-abis-r8.md`), keep a
  data provenance question honest (the app stopped bundling a catalog whose licence it could not
  confirm, an inclusion-policy lesson), and update the MR to the newest release. The author also
  dropped x86/x86_64 to keep the MR simple.
- Gap found later by comparing with Case A: the branch had no foojay sed, so its real build would
  fail even with a green fork pipeline. `check-recipe.py` now flags it.
- Lesson: when you have a recipe that was accepted, copy the **latest merged upstream version**,
  not your old branch.

## Case C: someone else's heavy Expo + Rust + Python-wheels app, MR open 2+ months

Read from the public MR; the author is not the user. Useful as a list of things that slow an MR.

- 100+ commits, many of the form "fix(fdroid): pin X". Reviewer asks repeated across rounds: use the
  Debian rustup package, `bookworm` not `bullseye`, move the wheel build from `prebuild` to `build`,
  set `subdir` and remove `output`, keep only the recipe in `metadata/` (no summary text), describe
  anti-features, keep auto-update on, add `Binaries` + `AllowedAPKSigningKeys`, reduce a 69 MB APK
  with ABI splits or minify.
- A rebase onto master **quietly reverted several accepted fixes**, prompting "Why do you keep
  reverting the fixes?" After any rebase, diff against what reviewers already approved.
- The author dropped `Binaries` after a pipeline reported a byte mismatch, listing dex, `.so`
  build-ids, `direct_url.json` paths and `resources.arsc` as impossible to match. A tester then
  noted the `reproducible-builds` label no longer fit. Our reading (inferred, from the comments):
  those causes only block a comparison against a reference built on another machine; signing
  F-Droid's own unsigned output (`reproducible.md`) sidesteps them, and a retried build job would
  show whether the recipe is deterministic. Dropping `Binaries` also means F-Droid signs with its own
  key permanently (`signing-keys.md`).
- A third-party tester pass found a launch crash on a real phone while all pipeline jobs were green.
  The author attributed it to the JavaScript engine swap (the scanner removes the prebuilt Hermes
  compiler, so the recipe packaged JavaScriptCore); the proposed fix was to keep Hermes and
  `scanignore` that one file as the template allows. [reported, not verified]
- Pipelines sometimes failed with all jobs red because of CI compute, and needed a maintainer to
  re-trigger. Wait for a human to say "triggered a pipeline"; don't force-push to retry.

## Patterns across the three

1. The accepted recipe is the template plus a handful of app-specific lines. Resist cleverness.
2. Reviewers repeat themselves when a fix gets lost. Keep a list of every reviewer request in the MR
   and check each still holds before each push.
3. Reproducibility is a process problem (sign their output), not mostly a toolchain problem.
4. Green CI does not mean installs and runs, and it does not mean the offline build server succeeds.
5. Size questions arrive late (after the first green build). Decide ABIs and R8 up front.
