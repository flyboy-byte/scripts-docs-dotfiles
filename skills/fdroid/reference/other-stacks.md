# Other stacks

Only the Expo / React Native path has been taken all the way through review and releases here.
For everything else this file points at the official templates and lists what to check. Treat it
as a map, not as tested recipes. Marks as in `process.md`: **[docs]** from the templates and
F-Droid docs, **[reported]** pattern seen once or second-hand.

Always read the live template first: `templates/build-<stack>.yml` in fdroiddata
(`ant, buildozer, flutter, godot, gradle, maven, native-script, react-native`; `general.yml` for
everything else). Find recently merged apps on the same stack:
`grep -l '<keyword>' metadata/*.yml` in an upstream checkout, then read the newest two or three.

## Plain Gradle (Kotlin/Java)

The easy case. [docs]

```yaml
  - versionName: 1.0
    versionCode: 1
    commit: <full SHA>
    subdir: app
    gradle:
      - yes
```

- Often nothing else. `gradle: yes` builds the default flavour; name a flavour to pick one
  (`gradle: [fdroid]`).
- Add `AutoUpdateMode: Version` and `UpdateCheckMode: Tags`.
- Reproducibility is usually near-automatic. If it isn't, use `reproducible.md`.
- Common blockers: proprietary libraries (Firebase, Play Services, Crashlytics, ads, analytics)
  and Maven repos the scanner doesn't accept. Fix by removing them, or by an F-Droid-only flavour
  without them.
- Check the app's `build.gradle` for `signingConfig` using secrets and for dependencies fetched
  from `jitpack` or other non-central repos (allowed, but the scanner reads them).

## Flutter

From `templates/build-flutter.yml`. [docs]

- Flutter has to come from somewhere: a git submodule in the source repo (preferred; the scanner
  covers submodules) or the `flutter@stable` srclib checked out to the version the project
  declares.
- Needs `output:` (e.g. `build/app/outputs/flutter-apk/app-release.apk`); the template says the
  path can be read from the build log.
- Deletes platform folders you don't ship via `rm:` (`ios`, `linux`, `macos`, `web`, `windows`).
- For reproducibility the template moves the project to the same absolute path as upstream's
  build (`mkdir`/`chown` in `sudo:`, `mv` in `prebuild:`), because Dart snapshots embed paths.
- Dart packages are fetched in `prebuild` with `flutter pub get --enforce-lockfile` and a
  `PUB_CACHE` inside the tree so the scanner sees them.
- Check dependencies for Google Play Services plugins; they won't pass.

## Other templates

- **Godot, Buildozer (Kivy), NativeScript, Ant, Maven**: each has a template with the
  stack-specific setup. Read it, then look at merged examples. [docs]
- **Native C/C++ (NDK)**: set `ndk:` to the exact version the project needs; expect to deal with
  absolute paths in binaries if you want reproducibility. [docs]
- **Something else**: start from `general.yml` and write `build:` commands. Keep commands
  short; call a script from the repo rather than embedding a long recipe. [reported]

## Questions that decide feasibility before you write anything

1. Is every dependency source-available under a free licence? (`policy.md`)
2. Does the build need network access beyond Maven/npm/pub fetches the scanner understands?
3. Does it build from a clean checkout with a single command?
4. Does the app talk to a proprietary service (anti-feature `NonFreeNet`)?
5. Is the signing key one you can keep forever? (Needed for reproducible builds.)
