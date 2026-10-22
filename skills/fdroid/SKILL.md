---
name: fdroid
description: Get an Android app into F-Droid and keep it updated, with Claude doing the legwork - new-app inclusion (RFP, fdroiddata merge request, metadata YAML, fastlane store text), reproducible builds signed with the developer's own key (Binaries, AllowedAPKSigningKeys, the two-run signing process, byte-comparison failures), ABI splits, auto-updates from tags, reading fdroiddata CI and the real build server logs, and finding out why a release isn't showing on f-droid.org. Strongest on Expo / React Native; covers plain Gradle and Flutter from the official templates. Use when asked to publish to or release on F-Droid, write or fix fdroiddata metadata, answer an F-Droid reviewer, fix a failed F-Droid pipeline or build, make a build reproducible, sign reference APKs, or check whether an update went live.
---

# fdroid: getting an app into F-Droid and keeping it there

F-Droid does not take your APK. It builds the app itself, from your source, on an offline
Debian build server, following a recipe (`metadata/<appid>.yml`) in the `fdroiddata` repo on
GitLab. Everything here follows from that:

- **The recipe is the product.** Volunteers review it, and the build server runs it. It has to
  work from a clean checkout of a tagged commit with no network beyond what `sudo:` installs.
- **Reproducible builds let your signature ship.** With `Binaries` + `AllowedAPKSigningKeys`,
  F-Droid rebuilds, checks its build is byte-identical to the APK you published, and ships
  *your* signed APK, so users can move between F-Droid, Play and GitHub without reinstalling.
  If an app goes in without it, F-Droid signs with its own key and **that can't be changed
  later**. Set it up before inclusion.
- **Maintainer time is the scarce resource.** Reviewers ask for the official template, followed
  exactly. A clean, template-shaped MR with green pipelines gets merged; a clever one stalls.

The user is the author of record on the MR and owns the signing key. Confirm with them before
anything outward-facing (forking, pushing to the fork, opening or commenting on the MR, creating
GitHub releases or tags) unless they've told you to go ahead. **Never print, log or commit a
keystore password**; pass them through environment variables (`scripts/sign-reference.sh` does).

## Files

- `reference/process.md` - the whole lifecycle: RFP, the MR, CI jobs and which failures are
  expected, review, merge, auto-updates, the real build server, when it appears on f-droid.org.
- `reference/metadata.md` - the YAML fields that matter, version codes, `VercodeOperation`,
  `$$VERCODE$$`, `binary:`, scanner fields, the formatting CI enforces, fastlane store text.
- `reference/reproducible.md` - the two-run signing process, why signing flags matter, how to
  triage a byte-comparison failure, a catalogue of known non-determinism causes and fixes.
- `reference/react-native-expo.md` - the recipe that works for Expo / RN (prebuild, JDK 21,
  foojay, LAN-IP, ABI splits, permissions that survive prebuild). Read for any RN app.
- `reference/other-stacks.md` - plain Gradle and Flutter: what the templates say, what to check.
- `reference/policy.md` - inclusion criteria, non-free dependencies, anti-features, permissions.
- `reference/troubleshooting.md` - symptom → cause → fix, from real failures.
- `scripts/` - read-only helpers plus the signer; each prints usage with `-h`:
  - `fdroid-status.sh <appid>` - what f-droid.org lists, what upstream metadata says, recent
    commits to the recipe (bot updates and maintainer edits), and the real build-server result
    for each version code.
  - `fetch-ci-apks.sh <fork> <job-id> <dir>` - download the unsigned APKs from a fork's
    `fdroid build` job (needs `glab`).
  - `apk-inspect.sh <apk>...` - version, ABIs present, permissions, signer cert, sha256.
  - `sign-reference.sh` - sign F-Droid's unsigned APKs the only way that byte-compares, and
    refuse unless the cert matches the expected fingerprint.
  - `apk-diff.sh <a.apk> <b.apk>` - which entries differ, grouped by class (dex, .so,
    baseline profile, resources, ...), or "entries identical, ZIP structure differs".

## Where the state lives

Keep one F-Droid doc in the **app's own repo** (e.g. `fdroid/README.md` or a section of its
state doc): a dated status line, the appid, the fdroiddata fork and branch, the cert
fingerprint, the release runbook as it actually works for this app, and an attempt log
(`attempt → change → result`) for any reproducibility work. Read it before acting; update it
after every pipeline result. Keystore paths and aliases can go in a gitignored local note;
passwords never go anywhere.

## Pick the job

| The user wants | Read | Then |
| --- | --- | --- |
| A new app into F-Droid | `policy.md`, `process.md`, `metadata.md`, the stack file | Policy check → fastlane text in the app repo → recipe on a fork branch → Run 1 → sign → Run 2 → MR |
| To release an update | the app's F-Droid doc, `process.md` "Updates" | Version bump + changelogs → push, don't tag → fork Run 1 → sign → GitHub release (creates the tag) → Run 2 → let checkupdates do it |
| A failed pipeline / build | `troubleshooting.md` | Read the failing job's log first; change one thing |
| Byte comparison failing | `reproducible.md` | `apk-diff.sh` → name the differing class → one fix |
| "Did the update go out?" | - | `fdroid-status.sh <appid>` and report each layer separately |
| To answer a reviewer | `process.md` "Review" | Do what they ask, in their words, then reply with what changed and the pipeline link |

## Rules that come from real failures

1. **Follow the official template for the stack exactly** (`templates/` in fdroiddata), then
   compare with recent merged recipes for the same stack (`grep -l <keyword> metadata/*.yml`
   upstream). When a reviewer says "follow the template", they mean every part.
2. **Start every fork branch from a freshly fetched `upstream/master`.** Maintainers edit
   recipes directly upstream (e.g. adding a line the offline server needs); an old fork branch
   silently drops their fixes.
3. **Fork CI is not the build server.** Fork pipelines have internet; the real build server
   doesn't. Something that downloads during the Gradle build (a JDK toolchain resolver, a
   plugin, a Maven repo the scanner doesn't know) passes on the fork and fails after merge.
   After every release, check the real log: `https://monitor.f-droid.org/builds/log/<appid>/<code>`.
4. **Don't run local `fdroid rewritemeta` to fix formatting.** Its output can differ from the
   CI version. Push, and if the CI `fdroid rewritemeta` job fails, apply its printed diff
   exactly. One iteration.
5. **Reference APKs are F-Droid's own unsigned output, signed by you** with
   `--v1-signing-enabled false --alignment-preserved true`, and the cert is checked against
   `AllowedAPKSigningKeys` *before* upload. Never a store/EAS build, never a build from the
   developer's working tree.
6. **All reference APKs are on the GitHub release before the tag exists**, because
   `checkupdates` acts on the tag. `gh release create vX.Y.Z --target <sha>` with the APKs
   attached creates both at once.
7. **One variable class per attempt** when chasing reproducibility. Name the differing class
   from evidence (`apk-diff.sh`) before changing anything, and record each attempt.
8. **The `commit:` field is a full SHA**, never a tag or branch, and only the latest version's
   blocks stay in a new-app MR.
9. **Durable fixes go where the recipe can't undo them.** If the recipe regenerates
   `android/` (Expo prebuild), hand edits there are thrown away: use app config / config
   plugins, or a `prebuild:` sed in the recipe.
10. **Report each layer separately and say how you know**: fork pipeline, upstream metadata,
    build-server log, f-droid.org listing. "Built and verified, not yet in the index" is a
    normal state that can last days.

## Never

Commit or echo signing passwords; upload a reference APK whose cert you didn't verify; push a
`Binaries:`/`binary:` URL before the APK is there; force-push or rebase a fork branch that an
open MR reviewer is mid-review on without saying so in the MR; open more than one app per MR;
argue a reviewer's decision about their repo; promise the user a date for appearing on
f-droid.org.
