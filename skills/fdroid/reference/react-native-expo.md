# Expo / React Native recipes

Everything in this file has been through real review, merge, release builds and auto-updates
on F-Droid (Expo SDK 54, React Native 0.81, npm, JDK 21, NDK 27.1.12297006, ABI splits,
reproducible), except where marked. Re-check the template upstream
(`templates/build-react-native.yml`) before starting: it moves.

## The shape that's accepted

```yaml
  - versionName: 1.2.3
    versionCode: 1231
    commit: <full SHA>
    subdir: android/app
    sudo:
      - apt-get update
      - apt-get install npm
    init:
      - cd ../..
      - npm install --ignore-scripts
    gradle:
      - yes
    binary: 
      https://github.com/<you>/<app>/releases/download/v%v/<app>-v%v-armeabi-v7a.apk
    prebuild:
      - cd ../..
      - sed -i -e '1a "expo":{"autolinking":{"android":{"buildFromSource":[".*"]}}},'
        package.json
      - sed -i '/jvmToolchain\|JavaVersion/s/17/21/' node_modules/@react-native/gradle-plugin/*/build.gradle.kts
        node_modules/@react-native/gradle-plugin/react-native-gradle-plugin/src/main/kotlin/com/facebook/react/utils/JdkConfiguratorUtils.kt
      - sed -i 's/\.filter { it is Inet4Address && !it.isLoopbackAddress }/.filter
        { false }/' 
        node_modules/@react-native/gradle-plugin/react-native-gradle-plugin/src/main/kotlin/com/facebook/react/utils/AgpConfiguratorUtils.kt
      - sed -i -e '/foojay/d' node_modules/@react-native/gradle-plugin/settings.gradle.kts
      - npx expo prebuild -p android --clean
      - sed -i 
        's/android.enablePngCrunchInReleaseBuilds=true/android.enablePngCrunchInReleaseBuilds=false/'
        android/gradle.properties
      - sed -i 's/org.gradle.jvmargs=.*/org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=512m/'
        android/gradle.properties
      - sed -i -e '/signingConfig /d' android/app/build.gradle
      - sed -i 's/versionCode .*/versionCode $$VERCODE$$/' android/app/build.gradle
      - sed -i 's/^android {$/android {\n    splits { abi { enable true; reset();
        include "armeabi-v7a"; universalApk false } }/' android/app/build.gradle
    scanignore:
      - node_modules/react-native/sdks/hermesc/linux64-bin/hermesc
      - node_modules/expo-modules-core/android/ExpoModulesCorePlugin.gradle
      - node_modules/expo-modules-autolinking/scripts/android/autolinking_implementation.gradle
      - node_modules/<each package whose android/build.gradle the scanner flags>/android/build.gradle
    scandelete:
      - node_modules
    ndk: 27.1.12297006
```

Copy the four blocks (one per ABI, changing only `versionCode`, the ABI in the splits sed and
the ABI in `binary:`), then `VercodeOperation: [10 * %c + 1 .. + 4]`.

## Why each line is there

- **`buildFromSource: [".*"]`**: Expo modules otherwise use prebuilt AARs, which the scanner
  rejects. Builds every Expo module from source. [seen]
- **JDK 17 → 21 sed**: the build server has JDK 21; the RN plugin pins 17. Patch it like the
  template does. Don't install another JDK or add a JDK to `sudo:`; reviewers reject that. [seen]
  Some libraries pin 17 in their own Gradle files (reanimated, worklets); add a sed for each. [seen]
- **LAN-IP sed**: the RN Gradle plugin writes the build host's IP into a resource for the dev
  server. It makes `resources.arsc` differ between machines. Filtering every address out removes
  it. [seen]
- **foojay sed**: the RN plugin's `settings.gradle.kts` applies the foojay toolchain resolver,
  which tries to download a JDK. Fork CI has internet so it passes; the offline build server
  fails. A maintainer added this line to a merged recipe in October 2026; the upstream template
  may not have it yet. [seen]
- **`npx expo prebuild -p android --clean`**: regenerates `android/` from `app.json` and config
  plugins. Reviewers require it even if `android/` is committed. Consequence: **anything edited
  by hand in `android/` is discarded on F-Droid.** [seen]
- **PNG crunch off, jvmargs**: determinism and memory on the server. [seen]
- **Remove `signingConfig`**: F-Droid builds unsigned. [seen]
- **ABI splits with `android.splits.abi`**, not `ndk { abiFilters }`: with AGP 8 and RN, the
  prebuilt `.so` files from npm packages come in through AAR extraction and bypass `abiFilters`
  and `packagingOptions.exclude`. You get four universal APKs and a reviewer asking why. The
  splits sed above produces one APK per block (`app-<abi>-release.apk`), which fdroidserver
  finds. Don't use both: the RN plugin errors on the combination. [seen]
- **`scanignore`**: single files only. The scanner flags some `build.gradle` files that declare
  local Maven repos; add exactly the file paths it names in the `check source code`/build
  scan output. Never `node_modules/**`. [seen]
- **`scandelete: node_modules`** + install in `init`: the template's lifecycle. Patches to
  `node_modules` are in `prebuild`, before the scan. [seen]

## Package managers

npm is the simple path. pnpm works with `node-linker=hoisted` so paths are plain
`node_modules/...` (a reviewer asked for that; `.pnpm/...` paths in `scanignore` were rejected).
Monorepos: set `subdir` to the app's `android/app` and prefix paths in `scanignore`/`scandelete`
with the app folder. [seen]

## Things that must live in app config, not `android/`

Because prebuild regenerates `android/`:
- **Permissions**: drop unused ones with `android.blockedPermissions` in `app.json` (Expo writes
  `tools:node="remove"` entries). Common unwanted ones: `INTERNET` for offline apps,
  `RECORD_AUDIO`, `SYSTEM_ALERT_WINDOW` (debug overlay leaking into release), storage
  permissions, `ACCESS_NETWORK_STATE` (pulled in by media players). [seen]
- **`allowBackup`, manifest attributes, Gradle tweaks**: a config plugin, or a `prebuild:` sed. [seen]
- Check what really ships: run `npx expo prebuild -p android --clean` and read the merged
  manifest, or `apk-inspect.sh` on the CI's unsigned APK. A CI check that fails on any
  permission outside an allowlist catches regressions. [seen]

## Monorepos and package managers in practice

- A repo whose app lives in a subfolder (`app/`) uses `subdir: app/android/app`, `cd ../..` becomes
  `cd ../../..` or `cd ../../app`, and every path in `scanignore` / `scandelete` carries the prefix
  (`app/node_modules/...`). A second Expo app moved from the first app's recipe to this layout with
  only those path edits. [seen]
- npm: `npm install --ignore-scripts` in `init`. pnpm: hoisted linker so scanner paths are plain
  `node_modules/...`; reviewers rejected `.pnpm/...` paths. Yarn: the template shows both. [seen]
- Hermes's compiler is flagged by the scanner (`hermesc`): `scanignore` that **one** file as the
  template does; Hermes is explicitly allowed as a prebuilt. Don't swap engines to avoid the scan:
  one MR packaged JavaScriptCore instead, and a tester reported a launch crash on RN 0.81 where the
  `isHermesEnabled` override is deprecated. [reported]
- SDK versions: Expo SDK 54 / RN 0.81 and SDK 57 / RN 0.86 both worked with this recipe shape. Pin
  `ndk:` to what the project's Gradle expects; the build server installs it. [seen]

## Config that must survive `expo prebuild --clean`

Hand edits in `android/` are discarded on F-Droid. Observed to revert: manifest permission removals
and `allowBackup`, the release `versionCode`, signing config, minify/shrink flags, JVM args. [seen]

| Need | Mechanism |
| --- | --- |
| Remove a merged permission | `android.blockedPermissions` in `app.json` (writes `tools:node="remove"`, which also cancels a permission another library re-adds) |
| `allowBackup="false"`, other manifest attributes | a local config plugin using `withAndroidManifest` |
| Minify / resource shrinking | a config plugin using `withGradleProperties` (`size-abis-r8.md`) |
| `versionCode` for each ABI block | recipe sed with `$$VERCODE$$` |
| JVM args, PNG crunch, caching | recipe seds on `android/gradle.properties` (template) |
| Release signing | recipe removes `signingConfig`; F-Droid builds unsigned |

Verify what really ships by running `npx expo prebuild -p android --clean` and reading the merged
manifest, or `scripts/apk-inspect.sh` on the CI's unsigned APK. A CI job that fails on any permission
outside an allowlist catches regressions. [seen]

## Native code of your own

A local Expo module in `modules/` (Kotlin only) autolinks through prebuild with no recipe change
and adds no `.so` files. [seen] A module with C/C++ adds native build steps; expect `.so`
determinism work.

## Dependencies to look at hard

- **Glide** (from `expo-image` and others): non-deterministic generated class names in dex. Drop it
  if unused, or add a deterministic-rename Gradle init script. [seen]
- **Reanimated / worklets / gesture-handler**: heavy native builds per ABI (time) and their own
  JDK pins. Fine if used; remove if not. [seen]
- **Firebase / Play Services / install referrer** (notifications, device-info, application): non-free.
  The template shows the seds and the `firebase-stub` srclib. [docs]
- **expo-av** (ExoPlayer) adds `ACCESS_NETWORK_STATE`. [seen]

## Local builds of the same thing

For test APKs that behave like the F-Droid one: fresh clone, `npm ci`, `npx expo prebuild -p
android --clean`, the same seds, `./gradlew assembleRelease` with JDK 21. Don't build from a
committed `android/` folder, which can be stale relative to `app.json`. [seen]
