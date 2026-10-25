# Reproducible builds with your own signature

Docs: https://f-droid.org/docs/Reproducible_Builds/ . Marks as in `process.md`.

## How verification works

1. F-Droid builds the recipe → an **unsigned** APK.
2. It downloads your published APK from the `binary:` URL.
3. It copies your signature onto its unsigned APK (apksigcopier) and checks the signature is
   valid. That only passes if every signed byte matches: same entries, same contents, same
   ZIP layout and padding.
4. Match → F-Droid publishes **your** APK. Log lines: `...successfully verified` and
   `compared built binary to supplied reference binary successfully`. [seen]

So the question is never "is my build close", it's "is every byte the same as theirs".

## The two-run process (the reliable path)

You can't easily make your own build match theirs byte for byte (paths, users, hosts, tool
versions all leak in). You don't have to: **sign their unsigned output**. That's the documented
workflow and it isn't cheating. Run 2 is an independent rebuild of the same commit that has to
come out identical, which proves the recipe is deterministic.

1. **Run 1**: recipe without `binary:`. Download the unsigned APK(s) from the `fdroid build`
   job (`scripts/fetch-ci-apks.sh`). They're named `<appid>_<versionCode>.apk`. [seen]
2. **Inspect** (`scripts/apk-inspect.sh`): right versionCode, right ABI per APK, permissions you
   expect.
3. Optional but cheap: **retry the build job** and `cmp` the new APKs against the first. If they
   differ, the recipe is non-deterministic. Fix that first; Run 2 would fail anyway. [seen]
4. **Sign** (`scripts/sign-reference.sh`):
   ```
   apksigner sign --v1-signing-enabled false --alignment-preserved true ...
   ```
   - `--alignment-preserved true`: without it apksigner rewrites the null-byte alignment padding
     as `0xD935` extra fields, which changes the bytes the v2/v3 signature covers. The copied
     signature then fails on F-Droid's APK. This one flag cost days. [seen]
   - `--v1-signing-enabled false`: no JAR signature (v1) entries added to the ZIP. [seen]
   - Verify the cert SHA-256 equals `AllowedAPKSigningKeys` before uploading.
5. **Publish** all of them on the GitHub release that matches `binary:`; that creates the tag.
6. **Run 2**: add `binary:`, push, read the build log for the verified lines on every block.

## When the comparison fails

Run `scripts/apk-diff.sh <your-signed.apk> <their-unsigned.apk>` (signature files under
`META-INF/` and the signing block are ignored). It reports the differing **class**. Fix only
that class, one attempt at a time, and log it.

| Differing class | Usual causes | Fixes that worked or are standard |
| --- | --- | --- |
| Nothing differs in entries, file still differs | Signed without `--alignment-preserved`; signed a different unsigned APK than theirs; zipaligned again | Re-sign *their* unsigned APK with the flags above. Never zipalign it again. |
| `resources.arsc` | Build host data in a resource. RN Gradle plugin writes the host's LAN IP. | RN: sed `AgpConfiguratorUtils.kt` (see `react-native-expo.md`). |
| `lib/**/*.so` | Absolute paths in native code (`__FILE__`, debug info) from the build dir or `GRADLE_USER_HOME`; build-id | Only matters if you compare your *own* build: build in the same path and user as the server (`/home/vagrant/build/<appid>`, `GRADLE_USER_HOME=/home/vagrant/.gradle`). Signing their output avoids it. |
| `classes*.dex` | Annotation processors with unstable output (Glide's `GlideIndexer_<hash>`), parallel build ordering | Remove the dependency if unused; or a Gradle init script that renames the generated class deterministically; `org.gradle.parallel=false` |
| `assets/dexopt/baseline.prof(m)` | ART profile generation order | Make the build single-threaded first; disable ArtProfile tasks only if it's the only diff |
| `META-INF/version-control-info.textproto` | AGP embeds VCS info | `vcsInfo { include = false }` in the release build type |
| `res/*.png` | PNG crunching differences | `android.enablePngCrunchInReleaseBuilds=false` |
| Different entries entirely / wrong ABIs | Different source (an unapplied patch), wrong split config | Make sure the reference came from the same recipe and commit |

The first-ever mismatch on a reviewer's MR is usually the last row: the reference APK was built
some other way (a store build, an EAS/cloud build, Android Studio). The reviewer will say "your
apk is built from a different source code". [seen]

## Publishing modes

[docs] There are two ways the developer's signature gets used:
- **Exclusively developer-signed** (what this skill sets up): `Binaries`/`binary:` + `AllowedAPKSigningKeys`.
  F-Droid publishes your APK only if its own build verifies; otherwise it skips that version.
- **Both developer-signed and F-Droid-signed**: the developer's signatures are added to fdroiddata
  (`fdroid signatures <apk>`) so installs from other stores can update from F-Droid and vice versa.
  Maintainer-level; mention it if a user already has installs signed by F-Droid.
Either way the unsigned APK F-Droid builds must be byte-identical, apart from the signature, to what
the signature was made over. v1 (JAR) signatures only cover contents; v2/v3 cover every byte, which
is why ZIP padding and entry order matter.

## The official catalogue of non-determinism

From https://f-droid.org/docs/Reproducible_Builds/ (checked 2026-10-25). Use after `apk-diff.sh` names
the class. Source for each: [docs] unless marked.

- **Embedded timestamps**: "the most common source". Set `SOURCE_DATE_EPOCH` for native builds.
- **Embedded build paths** (Flutter, python-for-android, Rust, C/C++): build in the same directory as
  the server: `/home/vagrant/build/<appid>` (build server), `/builds/fdroid/fdroiddata/build/<appid>` (CI);
  strip debug info (correct NDK version, `-s`, `llvm-strip`).
- **NDK build-id / hash style / clang comment**: different paths give different build-ids that survive
  stripping; `--build-id=none` removes them. `--hash-style=gnu` where LLVM defaults differ. NDK r26+
  has a platform-specific clang version string.
- **Native library stripping**: use the exact NDK; `packagingOptions { doNotStrip '**/*.so' }` can help
  as a diagnostic.
- **Concurrency**: output can depend on CPU count (dex rarely, native/Rust more). Single-thread the
  build (`org.gradle.parallel=false`, `workers.max=1`); Rust `codegen-units = 1`.
- **`baseline.prof` / `baseline.profm`**: rerun the build, match the CPU count, or disable the tasks:
  `tasks.whenTaskAdded { if (name.contains("ArtProfile")) enabled = false }`.
- **R8**: some optimizations are non-deterministic (ServiceLoader order); add `-keep` rules, update R8
  (≥ 8.6.33 / 8.7.20 / 8.8 for the CPU-count issue); test repeatedly. See `size-abis-r8.md`.
- **Resource shrinker**: may pick the unshrunk APK nondeterministically; avoid unless it saves a lot.
- **PNG crunching**: `cruncherEnabled = false` / `android.enablePngCrunchInReleaseBuilds=false`.
- **VCS info** (AGP 8.3+): `META-INF/version-control-info.textproto` embeds the commit/path;
  build the release from a clean tree at the tagged commit, or `vcsInfo.include false` as a last resort.
- **DEX class order**: seen for APKs as well as bundles; update AGP first (fixed for bundles in 8.8).
- **coreLibraryDesugaring**: fixed in R8 ≥ 3.0.69.
- **Mismatched toolchains**: more than one JDK in play changes dex; remove unused JDKs. The JDK 17→21
  seds exist so only one is used.
- **ZIP metadata and line endings**: Windows vs Linux newlines change bytes; ZIP extensions (unix
  attributes, extra fields) differ; the signing step must not add or rewrite them
  (`--alignment-preserved true`).
- **Android Studio builds** have non-deterministic ZIP ordering. Never use one for a reference.
- **Rust** (extra care): pin the toolchain with `rustup-init.sh -y --default-toolchain <version>`; trim paths
  (`--remap-path-prefix`, unstable `trim-paths`); `CARGO_TARGET_DIR` to a fixed absolute path;
  `CARGO_HOME` identical between builds (it ends up in the binaries); link the NDK to the same path;
  vendored OpenSSL needs `SOURCE_DATE_EPOCH`.
- **Python/Chaquopy wheels**: pip writes `direct_url.json` with the build path; build in a fixed path
  and let the wheels build in the `build:` phase. [seen on another author's MR; not verified here]

## Building it yourself (only when you need to debug locally)

Use F-Droid's own image and a fresh clone of the tagged commit, never the working tree:

```bash
podman run --rm --network host -v "$PWD/build.sh:/build.sh:ro" -v "$OUT:/output" \
  registry.gitlab.com/fdroid/fdroidserver:buildserver-trixie bash /build.sh
```

In `build.sh`: clone into `/home/vagrant/build/<appid>`, check out the SHA, run the recipe's
steps in order, export `GRADLE_USER_HOME=/home/vagrant/.gradle`, copy the unsigned APK to
`/output`. Diff the result against the CI's unsigned APK; once they match locally, the CI one
is still what you sign. [seen]

Debug by stage if it doesn't match: hash the tree after checkout, after init, after prebuild,
after the scan, before gradle. The first stage that differs is where to look. [seen]

## Keep a record

Per attempt: date, pipeline/job id, what changed (one class), result, differing entries. The
attempt log is what stops the next session from retrying a dead end.
