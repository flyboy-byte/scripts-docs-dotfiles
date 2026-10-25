# APK size, ABIs and R8

Reviewers look at the APK size in the Code Quality report. Two real MRs were asked the same
questions: split by ABI, and turn R8 on. Marks as in `process.md`.

## Where the size comes from (React Native / Expo)

React Native ships prebuilt native libraries (Hermes, RN core, per-module `.so`) **once per ABI**.
A universal APK with all four ABIs carries about 4× the native payload. One app measured
~100 MB universal and ~24–33 MB per ABI after splitting; another heavy app was told "69 MB, apply
ABI split or enable minify". [seen]

## Choices

| Option | Result | Trade-offs |
| --- | --- | --- |
| One universal APK, all four ABIs | one block, one versionCode | huge; reviewers ask for splits |
| One APK, **arm64-v8a + armeabi-v7a only** | one block, ~half the size | drops x86/x86_64 (emulators and a nearly extinct slice of Intel phones); simplest MR |
| **Per-ABI splits** (4 or 2 blocks) | smallest per-user APK | more blocks, more reference APKs, `VercodeOperation`, the two-run process per ABI |
| Single ABI (arm64 only) | smallest, simplest | excludes 32-bit-only phones; say so in the description |

A reviewer called splits "highly encouraged" for RN apps. [seen] An app that had pre-selected the two
real phone ABIs and then dropped x86/x86_64 ended with two blocks and a two-line `VercodeOperation`
(`10 * %c + 1`, `+ 2`), which kept its MR simple. [seen] Decide with the user; record it.

## Doing it right

- Restrict ABIs where F-Droid's build will see it. A `-PreactNativeArchitectures=...` flag on your
  own command line is invisible to F-Droid, whose recipe just runs prebuild + Gradle. Put the
  restriction in the recipe's splits sed or in committed build config. [seen]
- Use **`android.splits.abi`**, injected by sed onto the `android {` line. `ndk { abiFilters }` and
  `packagingOptions.exclude` look fine and build, but on AGP 8 + RN they leave all four ABIs in
  the APK. One app's newer toolchain (Expo SDK 57 / RN 0.86) did honour `abiFilters`; don't rely
  on it, verify. Never use both (the RN plugin errors). [seen]
- **Always verify** on the Run 1 output: `scripts/apk-inspect.sh unsigned.apk` must list exactly the
  one ABI you intended. [seen]
- Version codes and the order of `VercodeOperation` are fixed once published (`metadata.md`).
- 16 KB page-size devices (Android 15+): any app with NDK libraries must be rebuilt/aligned for
  them. Check Play/F-Droid guidance when you bump NDK. [docs]

## R8 (minify) and resource shrinking

Reviewers ask for R8 to cut size ("enable R8", "try to enable Minify"). [seen]

**Caveat from the reproducibility page [docs]:** some R8 optimizations are non-deterministic (for
example ServiceLoader lists, whose order can vary or be incomplete). Test the build several times;
disable offending optimizations with `-keep` rules in `proguard-rules.pro`; if the DEX depends on
CPU count, use R8 ≥ 8.6.33 / 8.7.20 / 8.8. The same page says to avoid the **resource shrinker**
unless it saves a lot, because on some platforms it keeps the unshrunk original (nondeterministic
choice).

**Expo/RN: where to turn it on.** `expo prebuild --clean` regenerates `android/gradle.properties`
with both flags off, so a hand edit in `android/` never reaches F-Droid. Use a small config plugin
and list it in `app.json` `plugins`: [seen]

```js
// plugins/withR8Release.js
const { withGradleProperties } = require('expo/config-plugins');
const FLAGS = {
  'android.enableMinifyInReleaseBuilds': 'true',
  'android.enableShrinkResourcesInReleaseBuilds': 'true',
};
module.exports = (config) => withGradleProperties(config, (c) => {
  for (const [key, value] of Object.entries(FLAGS)) {
    c.modResults = c.modResults.filter((p) => !(p.type === 'property' && p.key === key));
    c.modResults.push({ type: 'property', key, value });
  }
  return c;
});
```

The flags are read only in the `release` build type, so debug builds are unaffected. After turning
R8 on:
1. Run the **determinism check**: retry the F-Droid build job (or build twice) and `cmp` the APKs.
2. Test the release APK on a device: R8 can strip classes that reflection or native modules need.
   Add keep rules where it does.
3. Tell the reviewer what you measured (size before/after, determinism result).
