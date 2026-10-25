# fdroid

A guide to getting an Android app into [F-Droid](https://f-droid.org) and keeping it updated,
packaged as a [Claude Code](https://claude.com/claude-code) skill. Most of it is written for an AI
assistant to use (`SKILL.md` and `reference/`), but it is plain Markdown and plain scripts: you can
read it as a human guide without Claude. This page is the human way in.

It comes from taking real apps through F-Droid (an Expo / React Native app accepted and updated by
the bot on every release, a second one in review) and from reading a third author's public MR.
Evidence is marked in the reference files: **[seen]** happened to us, **[docs]** from F-Droid's own
documentation, **[reported]** second-hand. Where we have only tested Expo / React Native, we say so.

**Jump to:** [How F-Droid works](#how-f-droid-works-in-one-minute) ·
[**My reproducible build / byte comparison fails**](#my-reproducible-build--byte-comparison-fails) ·
[Find your problem](#find-your-problem) · [New app checklist](#new-app-checklist) ·
[Releasing an update](#releasing-an-update) · [Common mistakes](#common-mistakes) ·
[Words you'll meet](#words-youll-meet) · [Using it with Claude](#using-it-with-claude) ·
[Scripts](#the-scripts-on-their-own)

---

## How F-Droid works in one minute

1. F-Droid **builds your app itself** from your public source, on its own offline Debian server. It
   does not take your APK.
2. How it builds is a **recipe**: one YAML file, `metadata/<your.app.id>.yml`, in the
   [`fdroiddata`](https://gitlab.com/fdroid/fdroiddata) repo on GitLab. You add it through a merge
   request (MR). Volunteers review it; a pipeline of nine checks runs on your fork.
3. By default F-Droid then signs the result with **its own key**. If you instead give it your signed
   APK (`binary:`) and your key's fingerprint (`AllowedAPKSigningKeys`), it rebuilds, checks that
   its build is **byte-identical** to yours, and publishes **your** signed APK. That is a
   *reproducible build*. It lets users move between F-Droid, Play and GitHub without uninstalling.
   **If you don't do this at the start, you can't switch to it later.**
4. After the app is in, new versions come from your git **tags**. A bot (`checkupdates`) reads the
   tag, adds new build blocks to your recipe and F-Droid builds them. No MR per release.
5. There are three separate places a release can be "stuck": your fork's pipeline, the build server,
   and the public index on f-droid.org (which lags by hours to days). Check each separately:
   [`scripts/fdroid-status.sh <appid>`](scripts/fdroid-status.sh).

---

## My reproducible build / byte comparison fails

Start here if your pipeline says something like
`compared built binary to supplied reference binary but failed`, or you've decided "this can't be made
reproducible". It almost always can, and the usual cause is not the one people suspect.

### What the check actually does

F-Droid builds an **unsigned** APK. It takes the signature out of the APK you published and copies it
onto its unsigned APK, then verifies the result. Android's v2/v3 signatures cover *every byte* of the
file, so the signature only verifies if F-Droid's unsigned APK is identical to what you signed.

### The usual mistake

You built the reference APK **yourself** (on your laptop, in Android Studio, in a cloud build, or in
your own container) and signed that. F-Droid's build then differs from yours in lots of small ways:
different JDK, different paths, different timestamps, different machine. People then list those
differences, decide they can't be removed, and drop `Binaries`. They are real differences, but you
don't have to remove them.

### The reliable way: sign F-Droid's own output

You never need your own build to match theirs. You publish **their unsigned APK, signed by you**.
Their second build of the same commit must then match their first. That tests whether the *recipe* is
deterministic, which is the thing that matters. It is the documented method, and it isn't cheating.

1. **Run 1.** Push the recipe to your fork **without** `binary:` lines. Expect two failures that are
   normal at this stage: `schema validation` (it wants `binary`) and `checkupdates` (the tag doesn't
   exist yet). The `fdroid build` job must pass.
2. **Download the unsigned APKs** from the `fdroid build` job: on the job page, *Browse* the artifacts
   and open `tmp/` (they're named `<appid>_<versionCode>.apk`), or use
   [`scripts/fetch-ci-apks.sh`](scripts/fetch-ci-apks.sh).
3. **Check what's inside** (right version code, right ABIs, the permissions you expect):
   [`scripts/apk-inspect.sh`](scripts/apk-inspect.sh), or `apksigner verify --print-certs` and
   `aapt2 dump badging`.
4. **Test the recipe is deterministic.** Retry the `fdroid build` job (button on the job page), download
   the new APKs and compare: `cmp first.apk second.apk`. Identical means Run 2 will pass. If they
   differ, fix the recipe's non-determinism first ([catalogue](reference/reproducible.md#the-official-catalogue-of-non-determinism)).
5. **Sign each unsigned APK, as-is:**
   ```bash
   apksigner sign --ks my.jks --ks-key-alias KEY --ks-pass env:KS_PASS --key-pass env:KEY_PASS \
     --v1-signing-enabled false --alignment-preserved true \
     --out app-v1.2.3-arm64-v8a.apk  com.example.app_1232.apk
   apksigner verify --print-certs app-v1.2.3-arm64-v8a.apk | grep SHA-256     # must equal AllowedAPKSigningKeys
   ```
   The two flags matter. `--alignment-preserved true` stops `apksigner` rewriting the ZIP padding (which
   changes the bytes the signature covers). **Do not zipalign afterwards.**
   [`scripts/sign-reference.sh`](scripts/sign-reference.sh) does this and refuses if the certificate is wrong.
6. **Upload the signed APKs to the release your `binary:` URL points at** (for GitHub:
   `gh release create vX.Y.Z --target <commit> *.apk`, which also creates the tag).
7. **Run 2.** Add the `binary:` lines (and `AllowedAPKSigningKeys`) and push. The `fdroid build` log should
   say `compared built binary to supplied reference binary successfully` for every block.

### "But I read that X can't be made identical"

| What people say | What's really going on |
| --- | --- |
| "The dex differs between JDK versions on my machine and F-Droid's." | It only differs from *your* build. You sign *theirs*. If their two runs agree, there is nothing to fix. |
| "Native `.so` build-ids embed link-time paths." | Same: only matters against a build from another path. Their server always builds in `/home/vagrant/build/<appid>`. |
| "`resources.arsc` contains the build machine's IP." | A real React Native quirk, fixed with one recipe `sed` ([`reference/react-native-expo.md`](reference/react-native-expo.md)). |
| "`baseline.prof` differs." | Sometimes non-deterministic; rerun, match CPU count, or disable the ArtProfile tasks ([catalogue](reference/reproducible.md#the-official-catalogue-of-non-determinism)). |
| "Python wheels / pip write the build path." | Build in the `build:` phase at the fixed path; check by retrying the build job. |
| "Only an exact copy of F-Droid's image can match." | Their image is public (`registry.gitlab.com/fdroid/fdroidserver:buildserver`), and you don't need it if you sign their output. |

### If the retry shows the build really isn't deterministic

Then the recipe or the app has a source of randomness. Work through
[the catalogue](reference/reproducible.md#the-official-catalogue-of-non-determinism) one class at a time
(`scripts/apk-diff.sh first.apk second.apk` tells you which class), change **one thing per attempt**, and
write each attempt down. Heavy stacks (Rust, embedded Python, R8) need the most care, and need the retry
test every time.

### If you decide to give up reproducibility anyway

You can, but understand the cost first. Without `Binaries`, F-Droid signs with its **own** key, and
(per F-Droid's MR template) you **can't enable reproducible builds later**. Users who installed from
another store must uninstall to switch. Also ask for the `reproducible-builds` label to be removed: it
won't be true. Full table: [`reference/signing-keys.md`](reference/signing-keys.md).

---

## Find your problem

| I'm stuck on... | Read |
| --- | --- |
| What to do, in what order, for a **new app** | [New app checklist](#new-app-checklist) and [`reference/process.md`](reference/process.md) |
| Whether my app is **allowed** (licence, dependencies, tracking, permissions) | [`reference/policy.md`](reference/policy.md) |
| Writing the **recipe** (`metadata/<appid>.yml`), what each field does | [`reference/metadata.md`](reference/metadata.md) |
| A **React Native / Expo** app specifically | [`reference/react-native-expo.md`](reference/react-native-expo.md) |
| Flutter, plain Gradle, Rust or Python-heavy apps | [`reference/other-stacks.md`](reference/other-stacks.md) |
| The **store listing** text, screenshots and changelogs | [`reference/metadata.md`](reference/metadata.md#fastlane-store-text-in-the-app-repo), `scripts/check-fastlane.py` |
| **Reproducible builds**, signing the reference APK | the section above, [`reference/reproducible.md`](reference/reproducible.md) |
| **Signing keys**, Play and F-Droid together, losing a key | [`reference/signing-keys.md`](reference/signing-keys.md) |
| The APK is **too big**; reviewer says "split by ABI" or "enable R8" | [`reference/size-abis-r8.md`](reference/size-abis-r8.md) |
| A **pipeline job failed** | [`reference/troubleshooting.md`](reference/troubleshooting.md) |
| Testing a recipe **before** pushing | [`reference/local-testing.md`](reference/local-testing.md), `scripts/check-recipe.py` |
| A **reviewer comment** I don't understand | [`reference/troubleshooting.md`](reference/troubleshooting.md#review-and-process-situations), [`reference/casebook.md`](reference/casebook.md) |
| **Reviewing or testing** someone else's MR | [`reference/reviewing-others.md`](reference/reviewing-others.md) |
| My release isn't showing on f-droid.org | [How F-Droid works](#how-f-droid-works-in-one-minute) item 5, `scripts/fdroid-status.sh` |
| What a real submission looked like, mistakes included | [`reference/casebook.md`](reference/casebook.md) |

---

## New app checklist

In order. Details in [`reference/process.md`](reference/process.md).

- [ ] Licence is FLOSS; no Google Play Services, Firebase, Crashlytics, proprietary ads or analytics;
      nothing prebuilt from an unallowed source ([policy](reference/policy.md)).
- [ ] Permissions trimmed to what the app really uses (frameworks add extras silently).
- [ ] Store text in **your repo** under `fastlane/metadata/android/en-US/` (title, short and full
      description, icon, a few real screenshots, a changelog per version code).
- [ ] A signing key you will keep forever, backed up, and the same one on every store you use.
- [ ] Decide ABIs and R8 now ([size](reference/size-abis-r8.md)).
- [ ] Releases are tagged (`vX.Y.Z`); `versionCode`/`versionName` live in a file the bot can read.
- [ ] Fork `fdroiddata`, branch from fresh `master`, copy the **template** for your stack, remove every
      comment, fill it in. Lint it with `scripts/check-recipe.py`.
- [ ] Run 1 → sign F-Droid's unsigned APKs → publish → Run 2 ([walkthrough above](#the-reliable-way-sign-f-droids-own-output)).
- [ ] Open the MR as "New app: Name", answer the template honestly, one app per MR.
- [ ] Reply to every review comment in **every** build block it applies to, and keep a list.
- [ ] Be patient: weeks is normal. Helping test other MRs is welcome.

## Releasing an update

Once the app is in and on `AutoUpdateMode: Version` + `UpdateCheckMode: Tags`:

1. Bump the version in the app repo, add changelogs for the **final** version codes, merge, push. **Don't tag yet.**
2. On a fork branch from fresh upstream `master`, add the new version's blocks (`commit:` = full SHA, no
   `binary:`) and bump `CurrentVersion*`. Push = Run 1.
3. Retry the build job and `cmp` the APKs (determinism check). Sign F-Droid's unsigned APKs.
4. `gh release create vX.Y.Z --target <sha>` with the signed APKs. This creates the tag **with** the
   reference APKs already present.
5. Add `binary:` to the fork blocks, push = Run 2. All comparisons must pass.
6. Stop. The bot does the rest. A day or two later run `scripts/fdroid-status.sh <appid>` and read the
   real build log (`https://monitor.f-droid.org/builds/log/<appid>/<code>`): the build server is
   offline and can fail on things your fork's CI never showed.

## Common mistakes

1. Building the reference APK yourself instead of signing F-Droid's unsigned one.
2. Signing without `--alignment-preserved true`, or zipaligning afterwards.
3. Giving up `Binaries` (permanent loss of your signature) instead of diagnosing the mismatch.
4. `abiFilters` for ABI splits: builds fine, ships four ABIs. Use `android.splits.abi`.
5. Editing `android/` by hand in an Expo project; `expo prebuild --clean` throws it away on F-Droid.
6. Putting a tag or branch in `commit:`; it must be the full hash.
7. Writing `$VERCODE$` in the YAML; it is `$$VERCODE$$`.
8. Running your own `rewritemeta` and pushing the result; let CI's job print the diff and apply that.
9. Starting a new branch from an old one, or rebasing, and quietly undoing fixes a maintainer already made.
10. Trusting a green fork pipeline. The real build server is offline; check its log.
11. Wide `scanignore` entries; single files only, with the reason in the MR.
12. Putting summary/description in the YAML; it belongs in your repo's fastlane folder.
13. Running the release APK on a real phone for the first time only after the MR is open.

## Words you'll meet

- **MR**: merge request on GitLab. **RFP**: "request for packaging", an optional issue for apps others suggest.
- **fdroiddata**: the repo of recipes. **fdroidserver**: the tool that builds and publishes.
- **Recipe / metadata**: `metadata/<appid>.yml`. **Build block**: one `Builds:` entry (one per ABI if you split).
- **Unsigned APK**: what F-Droid's build produces. **Reference APK** / **`binary:`**: your signed copy of it.
- **`AllowedAPKSigningKeys`**: the SHA-256 fingerprint (lowercase hex, no colons) of your signing certificate.
- **checkupdates**: the bot that follows your tags. **Scanner**: the check for non-free binaries; `scanignore` and `scandelete` tell it what to skip or remove.
- **Anti-feature**: a disclosed warning label (ads, tracking, non-free network service...).
- **Fastlane metadata**: the folder of store text and images in your repo that F-Droid reads.
- **`VercodeOperation`**: how base version codes become per-ABI codes (e.g. `10 * %c + 1`).

## Using it with Claude

```sh
git clone https://github.com/flyboy-byte/scripts-docs-dotfiles.git
mkdir -p ~/.claude/skills
cp -r scripts-docs-dotfiles/skills/fdroid ~/.claude/skills/
```

Then, in your app repo: "get this on F-Droid", "release 1.4.0 to F-Droid", "why did the F-Droid pipeline
fail", "my reproducible build doesn't match", "did my update go live", "review this F-Droid MR".
Claude confirms with you before anything public (forking, pushing, commenting, creating releases), and
never prints your keystore password.

You need `git`, `curl`, `python3` (with PyYAML for `check-recipe.py`); `glab` (logged in to GitLab) for
fork pipelines and MRs; `gh` for GitHub releases; Android build-tools (`apksigner`, `aapt2`) found via
`ANDROID_HOME`.

## The scripts on their own

```sh
S=~/.claude/skills/fdroid/scripts
$S/fdroid-status.sh com.example.app             # every layer: listing, queued, recipe history, build log
$S/check-recipe.py metadata/com.example.app.yml # lint a recipe
$S/check-fastlane.py ./my-app 101 102 103 104   # store text limits, changelog per final code
$S/fetch-ci-apks.sh you/fdroiddata 123456789 ./run1
$S/apk-inspect.sh run1/unsigned/tmp/*.apk
KS=~/my.jks KEY_ALIAS=key KS_PASS=... EXPECTED_SHA256=<AllowedAPKSigningKeys> \
  $S/sign-reference.sh ./signed run1/unsigned/tmp/com.example.app_102.apk:app-v1.0-arm64-v8a.apk
$S/apk-diff.sh first.apk second.apk
$S/mr-summary.py 12345                          # any fdroiddata MR
```

Passwords come from the environment and are never written to disk or echoed. Nothing here deletes your
files or pushes anywhere (the signer writes only the signed APKs).

## What this is not

- Anything personal: no keystore paths, aliases, hostnames or saved preferences. Keep an F-Droid doc in
  your app repo for those.
- A guarantee about timing. How long the index takes after a verified build varies.
- Official. F-Droid's own docs win when they disagree with this; the links are in the files. Where our
  experience differs from the docs (for example `apksigner` versions) both are written down.
- Equally tested everywhere. Expo / React Native has been through review and releases; the other
  stacks are a map to the official templates.

Questions about F-Droid itself: the [F-Droid forum](https://forum.f-droid.org) and the
[contributor tips](https://gitlab.com/fdroid/wiki/-/wikis/Tips-for-fdroiddata-contributors).
