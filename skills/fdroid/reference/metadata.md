# Metadata: the recipe and the store text

Full field reference: https://f-droid.org/docs/Build_Metadata_Reference/ . This file covers what
actually comes up. Marks as in `process.md`.

## Top-level fields

```yaml
Categories:
  - <from config/categories.yml upstream>
License: <SPDX id, e.g. MIT, GPL-3.0-only>
AuthorName: <any name>              # required for new apps [docs]
WebSite: https://...
SourceCode: https://...
IssueTracker: https://...           # required in practice: reviewers need a contact [docs]

AutoName: <App name>

RepoType: git
Repo: https://github.com/<you>/<app>

Builds:
  - ...

AllowedAPKSigningKeys: <sha256 of your signing cert, lowercase hex, no colons>

AutoUpdateMode: Version
UpdateCheckMode: Tags               # or: Tags ^v[\d.]+$  to ignore beta tags
VercodeOperation:                   # only for ABI splits / code transforms
  - 10 * %c + 1
CurrentVersion: 1.2.3
CurrentVersionCode: 123
```

- Don't put summary, description, screenshots or changelogs in the YAML; they come from the app
  repo's fastlane folder. [docs]
- `Binaries:` (top level) or `binary:` (per build block) gives the URL of your signed APK; `%v`
  is replaced with versionName, `%c` with versionCode. Per-block `binary:` is what you need for
  ABI splits (one URL per ABI). [seen]
- `AllowedAPKSigningKeys` alone does **not** enable reproducible builds; a reviewer will say so.
  You need both. [seen]
- Get the fingerprint: `apksigner verify --print-certs your.apk | grep -i 'SHA-256'`, then lowercase
  and drop colons.

## A build block

```yaml
  - versionName: 1.2.3
    versionCode: 1231
    commit: <full 40-char SHA>        # never a tag or branch [docs]
    subdir: android/app               # where gradle runs; scripted steps start here too
    sudo:                             # runs as root on the build VM; apt installs only
      - apt-get update
      - apt-get install npm
    init:                             # before the scanner
      - cd ../..
      - npm install --ignore-scripts
    gradle:
      - yes                           # default flavour; or a flavour name
    binary: 
      https://github.com/<you>/<app>/releases/download/v%v/<app>-v%v-arm64-v8a.apk
    prebuild:                         # after init, still before the scanner
      - cd ../..
      - sed -i ...
    scanignore:                       # single files the scanner may skip; never whole packages
      - node_modules/react-native/sdks/hermesc/linux64-bin/hermesc
    scandelete:                       # deleted after prebuild, before the scan
      - node_modules
    ndk: 27.1.12297006                # exact NDK if native code is built
```

- `init`, `prebuild`, `build` each start in `subdir`, so recipes begin with `cd ../..`. [seen]
- Order on the server, simplified: checkout → `sudo` → `init` → `prebuild` → scanner
  (`scanignore`, `scandelete`) → `build` → gradle. Something installed into a deleted folder before
  the scan is gone unless reinstalled. [docs][seen]
- `rm:` deletes paths (e.g. unused `ios/` folders); `submodules: true` checks out submodules
  (preferred to `srclibs` for vendored code; the scanner covers submodules). [docs]
- `output:` points at the APK when it isn't where gradle normally puts it (Flutter, custom
  builds). [docs]
- `$$NAME$$` substitutions: `$$VERCODE$$`, `$$VERSION$$`, `$$<srclib>$$` (srclib path),
  `$$SDK$$`, `$$NDK$$`. In seds, write the double dollars as shown. [seen for VERCODE; docs for the rest]

## Version codes and ABI splits

- With ABI splits, each ABI is its own build block with its own versionCode, produced from the
  app's base code by `VercodeOperation`, one line per block in order. The common scheme:
  `10 * %c + 1..4` for armeabi-v7a, arm64-v8a, x86, x86_64. Keep the ordering forever; changing
  it breaks upgrades. [seen]
- Patch the build to emit the block's code with `sed -i 's/versionCode .*/versionCode $$VERCODE$$/'`
  on the gradle file, so blocks never need hand-edited codes. [seen]
- If you also ship on Play, give Play `10 * %c + 0` so F-Droid's builds of the same release
  sort above it and upgrades between stores work. [seen]
- Changelogs are looked up by the *final* code (`1231.txt` … `1234.txt`), not the base code. [seen]

## Formatting CI enforces

The `fdroid rewritemeta` job fails unless the YAML is in canonical form and prints the diff it
wants. Apply that diff exactly; don't run a local rewritemeta to "fix" it (versions differ). [seen]
Known quirks of the canonical form:

- `binary:` followed by its URL on the next line is written `binary: ` with a trailing space.
- Long `sed` lines are folded; a fold point after `sed -i` or after a closing quote keeps a
  trailing space (`sed -i `, `{ false }/' `).
- LF line endings, no comments left from templates. [docs]

## Fastlane store text (in the app repo)

```
fastlane/metadata/android/en-US/
  title.txt
  short_description.txt          # one line, keep it short (≤ 80 chars)
  full_description.txt
  changelogs/<final versionCode>.txt   # ≤ 500 chars is the safe limit
  images/icon.png
  images/featureGraphic.png
  images/phoneScreenshots/1.png ...
```

- `en-US` is required; other locales are optional folders beside it. [docs]
- Text is picked up from the tagged commit at build time, so fix typos before tagging. [reported]
- Triple-T layout (`src/main/play/`) is also accepted. [docs]
