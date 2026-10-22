# fdroid

A [Claude Code](https://claude.com/claude-code) skill for getting an Android app into
[F-Droid](https://f-droid.org) and keeping it updated, with Claude doing the legwork.

F-Droid builds your app itself from source, on an offline server, using a recipe in the
`fdroiddata` repo. Getting that right (and getting F-Droid to publish *your* signed APK, so
users can switch between stores without reinstalling) is mostly knowing what the reviewers
want and which failures are normal. This skill carries that knowledge:

- **The lifecycle**: policy check, fastlane store text, the recipe on a fork branch, the merge
  request, review, and the no-MR update path through tags and the checkupdates bot.
- **Reproducible builds with your own key**: the two-run process (build once without `binary:`,
  sign F-Droid's own unsigned APK with the flags that byte-compare, publish, build again), a
  triage table for byte-comparison failures, and scripts to inspect, diff and sign APKs.
- **Expo / React Native in depth**: the recipe that passed review, every line explained, ABI
  splits that actually split, permissions that survive `expo prebuild`, dependency traps.
  Plain Gradle and Flutter are covered from the official templates.
- **Offline build server vs your fork's CI**: why a pipeline can be green and the real build
  still fail, and how to read the real build log.
- **"Did it go out?"** A script that reports the f-droid.org listing, the queued metadata, recent
  recipe commits (bot and maintainer edits) and the build-server result separately.

Evidence is marked in the reference files (`[seen]`, `[docs]`, `[reported]`) so Claude doesn't
pass off a one-off as a rule. The Expo / React Native material comes from taking a real app
through review, merge, ABI-split reproducible builds and several auto-updates; other stacks are
a map to the official templates, not tested recipes.

## Install

```sh
git clone https://github.com/flyboy-byte/scripts-docs-dotfiles.git
mkdir -p ~/.claude/skills
cp -r scripts-docs-dotfiles/skills/fdroid ~/.claude/skills/
```

Then, inside your app repo: "get this on F-Droid", "release 1.4.0 to F-Droid", "why did the
F-Droid pipeline fail", "did my update go live".

You need: `git`, `curl`, `python3`; `glab` (authenticated to GitLab) for fork pipelines; `gh`
for GitHub releases; Android build-tools (`apksigner`, `aapt2`) found via `ANDROID_HOME`.

## The scripts on their own

```sh
S=~/.claude/skills/fdroid/scripts
$S/fdroid-status.sh com.example.app                       # every layer, read-only
$S/fetch-ci-apks.sh you/fdroiddata 123456789 ./run1        # unsigned APKs from the build job
$S/apk-inspect.sh run1/unsigned/tmp/*.apk                  # version, ABIs, permissions, cert
KS=~/my.jks KEY_ALIAS=key KS_PASS=... EXPECTED_SHA256=<AllowedAPKSigningKeys> \
  $S/sign-reference.sh ./signed unsigned.apk:app-v1.0-arm64-v8a.apk
$S/apk-diff.sh mine.apk theirs.apk                         # which class of file differs
```

Passwords come from the environment and are never written to disk or echoed. `sign-reference.sh`
deletes its output and exits non-zero if the signing cert isn't the one you expect.
Nothing here deletes your files or pushes anywhere.

## What's not here

- Anything personal: no keystore paths, aliases, hostnames or saved preferences. Keep an F-Droid
  doc in your app repo for those (SKILL.md says what goes in it).
- Guarantees about timing. How long the index takes to publish after a verified build varies.
