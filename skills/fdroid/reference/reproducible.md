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
