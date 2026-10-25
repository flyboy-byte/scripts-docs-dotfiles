# Testing a recipe without waiting for CI

Three levels. Use the cheapest that answers the question. Marks as in `process.md`.

## 1. Static checks (seconds)

```bash
scripts/check-recipe.py metadata/<appid>.yml     # structure, template parity, block consistency
scripts/check-fastlane.py <app-repo> 181 182     # store text limits, changelogs for final codes
```

## 2. fdroidserver in the official container (minutes, needs podman or docker)

This is the documented way to run the same commands CI does. [docs: Submitting to F-Droid Quick
Start Guide]

```bash
git clone --depth=1 https://gitlab.com/fdroid/fdroidserver ~/fdroidserver
podman run --rm -it --entrypoint /bin/bash \
  -v ~/fdroiddata:/build:z -v ~/fdroidserver:/home/vagrant/fdroidserver:Z \
  registry.gitlab.com/fdroid/fdroidserver:buildserver
# inside the container:
. /etc/profile
export PATH="$fdroidserver:$PATH" PYTHONPATH="$fdroidserver"
export JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 >/dev/null | grep 'java.home' | awk -F= '{print $2}' | tr -d ' ')
cd /build
fdroid readmeta
fdroid lint <appid>
fdroid checkupdates --allow-dirty <appid>
fdroid build <appid>            # slow; needs network inside the container (--network host)
```

Notes:
- Count on ~5 GB of disk and 1–2 GB of downloads for the first run.
- `fdroid rewritemeta <appid>` is in the official guide. Our experience: output from a **stale**
  fdroidserver differed from CI, so CI's `fdroid rewritemeta` job stays the authority. Using the
  container with a fresh fdroidserver master is the careful way if you do run it. [seen]
- A local `fdroid build` has internet, like fork CI. It won't expose "needs network" failures that
  the real build server (offline) would. Check the real build log after merge. [seen]

## 3. A full fork pipeline (the real check short of the build server)

Push the branch to your fork; the nine jobs run (`process.md` lists the expected Run 1 failures).
Read failures from the job trace (`glab api projects/<you>%2Ffdroiddata/jobs/<id>/trace`). To
iterate without new commits, retry a job: `glab api -X POST projects/<you>%2Ffdroiddata/jobs/<id>/retry`.

## Debugging reproducibility locally

- Diff: `scripts/apk-diff.sh a.apk b.apk` for a quick class summary; **diffoscope** for the full
  picture (it can compare unsigned APKs and show the differing smali/ELF sections). The wiki page
  "HOWTO: diff & fix APKs for Reproducible Builds" ranks which differences to fix first.
- Check that a signed reference would verify on F-Droid's unsigned APK (from the pipeline
  artifacts, `scripts/fetch-ci-apks.sh`), the same way the build server does:
  `apksigcopier compare --unsigned ref.apk unsigned.apk` (first the signed APK, then the unsigned
  one), or `apksigcopier copy ref.apk unsigned.apk out.apk && apksigner verify out.apk`. Use
  `apksigner` from build-tools 34 if a newer one misbehaves (`signing-keys.md`). Syntax checked
  against apksigcopier 1.1.1.
- Determinism proxy: retry the `fdroid build` job and `cmp` the two APK sets. Identical twice is
  strong evidence Run 2 will verify.

## Test builds for the phone (React Native / Expo)

For a test APK that behaves like the F-Droid one: fresh clone at the SHA, `npm ci`, `npx expo
prebuild -p android --clean`, the recipe's seds, `./gradlew assembleRelease` under JDK 21 with
`--max-workers=2 -Dorg.gradle.parallel=false` on a 14 GB machine, strip foreign ABIs, zipalign,
sign with your key. About 7 minutes. Do not build from the committed `android/` folder, which can
be stale relative to `app.json`. [seen]
