# Troubleshooting: symptom → cause → fix

Look at the failing job's log before anything else:
`glab api "projects/<you>%2Ffdroiddata/jobs/<id>/trace" | tail -120`. Marks as in `process.md`.

## Fork pipeline jobs

| Job / symptom | Cause | Fix |
| --- | --- | --- |
| `fdroid rewritemeta` fails, prints a diff | YAML not in canonical form | Apply the printed diff exactly. Don't run local rewritemeta. [seen] |
| `schema validation` fails: `binary` required | Run 1 with `AllowedAPKSigningKeys` set but no `binary:` | Expected in Run 1. Passes in Run 2. [seen] |
| `checkupdates` fails (Run 1) | The tag doesn't exist yet | Expected. Create the release/tag, it passes in Run 2. [seen] |
| `checkupdates` fails (later) | Version file not where the recipe says; `UpdateCheckMode` regex doesn't match; tag points at a commit with old version | Fix the app repo's version file or the regex; read the job log for what it parsed. [seen] |
| `check source code` / scanner finding | A flagged binary or non-free library | Remove it, or `scanignore` the exact file if it's a known-good blob (Hermes). Never wide globs. [seen] |
| `fdroid build` fails in Gradle config | Needs network (toolchain resolver, plugin repos), or JDK mismatch | RN: foojay sed, JDK 21 seds. Check "Could not resolve" lines. [seen] |
| `fdroid build` fails: NDK not found | Wrong `ndk:` | Use the exact version the project's Gradle expects; the server installs it. [seen] |
| Build passes but 4 universal APKs | `abiFilters` used instead of `splits` | `react-native-expo.md` ABI section. [seen] |
| Build OOM / killed | Gradle workers | Raise `org.gradle.jvmargs` in `gradle.properties` via sed; lower parallelism. [seen] |
| `check apk` fails: signature / `binary` | Reference APK problem | See below. |
| Pipeline never starts / "needs verification" | GitLab account verification | Tell the user; don't try to work around. [docs] |

## Byte comparison failures

1. Did you sign **their** unsigned APK (`<appid>_<code>.apk` from that job's artifacts) with
   `--v1-signing-enabled false --alignment-preserved true`? If not, redo it. [seen]
2. Is `binary:` pointing at the right ABI file for this block, and is the file there (open the
   URL)? [seen]
3. Cert fingerprint equals `AllowedAPKSigningKeys`? [seen]
4. Did the recipe change after Run 1 (even one sed)? Then the unsigned APK changed. Re-download
   from the newest build job and re-sign. [seen]
5. Still failing: `apk-diff.sh`, name the class, use the table in `reproducible.md`. One change
   per attempt.

## After merge or release

| Symptom | Cause | Fix |
| --- | --- | --- |
| Fork Run 2 green, real build fails | Fork has internet, server doesn't | Read `monitor.f-droid.org/builds/log/<appid>/<code>`; look for downloads or "Could not resolve"; fix in the recipe and tell the user (a maintainer may fix it for you) [seen] |
| Bot hasn't added the new version | Tag not pushed, tag not matching `UpdateCheckMode`, checkupdates runs periodically | `git ls-remote --tags origin`; check the regex; wait; look at the recipe's commit history upstream [seen] |
| Bot added blocks but the build failed on compare | Reference APK missing at `binary:` URL when the bot ran | Upload the APK to the release; the next build run retries [seen] |
| Build verified, f-droid.org still shows old version | Index publish lag | Normal: hours to a few days. Check the API again later. [seen] |
| Users can't upgrade from another store | Different signing cert | Make F-Droid publish *your* signed APK (reproducible), and align Play to the same key. [seen] |
| Beta tag got packaged | `UpdateCheckMode: Tags` too broad; recipe reads version from a file the beta changed | Restrict regex (`Tags ^v[\d.]+$`) and keep committed version at last stable on beta tags. [seen] |
| Maintainer commit appeared on your recipe | They fixed something the server needed | Read the diff (`fdroid-status.sh` shows recent commits), copy the change into your notes and future branches. [seen] |

## Review and process situations

| Symptom | Cause | Fix |
| --- | --- | --- |
| Every job in a pipeline failed in seconds | No CI compute, or the pipeline needs a maintainer to start | Open one job trace; wait for a maintainer to trigger it. Don't force-push to retry. [seen] |
| A maintainer says "why do you keep reverting the fixes?" | A rebase or sync dropped accepted changes | Diff the new head against the last reviewed commit; restore; list reviewer requests in the MR. [seen] |
| Reviewer: "your apk is built from a different source code" | Reference APK wasn't built from the recipe's output | Sign F-Droid's unsigned APK instead (`reproducible.md`). [seen] |
| Reviewer: "install rustup / use bookworm / move to build / set subdir, drop output" | Template parity | Do exactly that in every block. [seen] |
| Reviewer: "enable R8" or "apply ABI split" | Size | `size-abis-r8.md`. [seen] |
| Label `reproducible-builds` but no `Binaries` | Label doesn't match the recipe | Add verified `Binaries`, or ask a maintainer to remove the label; note the permanent key consequence (`signing-keys.md`). [seen] |
| Release is newer than the open MR's version | MR recipe is stale | Update the MR to the latest release ("if you release a new version please update this MR"). [seen] |
| App starts in CI screenshots but crashes on a phone | Engine swap, missing keep rules after R8, stripped class | Device pass on the release APK; keep Hermes; add keep rules. [seen/reported] |
| Pipeline green on fork, build server fails | Fork has internet, server doesn't | Real log at `monitor.f-droid.org/builds/log/<appid>/<code>`. [seen] |

## Local environment

- `apksigner` complains about the keystore type: use the key alias as listed by
  `keytool -list -keystore <jks>`.
- `glab api` returns 404 for a project: URL-encode the slash (`group%2Frepo`).
- A job's artifacts are a ZIP; the APKs are inside `tmp/` (path inside the build VM). [seen]
- Disk full corrupts Gradle state mid-build: `./gradlew --stop`, delete the project's
  `android/.gradle` and `build` dirs, retry. [seen]
