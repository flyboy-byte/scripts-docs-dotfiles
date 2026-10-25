# Metadata: the recipe and the store text

Full field reference: https://f-droid.org/docs/Build_Metadata_Reference/ . This file covers what
comes up in practice and was checked against that page on 2026-10-25. Marks as in `process.md`.
Check a recipe with `scripts/check-recipe.py metadata/<appid>.yml`.

## Top-level fields

```yaml
Categories:
  - <from config/categories.yml upstream>
License: <SPDX id, e.g. MIT, GPL-3.0-only>
AuthorName: <any name>              # required for new apps
WebSite: https://...
SourceCode: https://...
IssueTracker: https://...           # reviewers need a contact

AutoName: <App name>                # only if the name isn't in the app's fastlane title.txt

RepoType: git
Repo: https://github.com/<you>/<app>
# Binaries: <url with %v/%c>        # one URL for apps with a single APK; or binary: per build block

Builds:
  - ...

AllowedAPKSigningKeys: <sha256 of your signing cert, lowercase hex, no colons>
AntiFeatures:                       # only if true; see policy.md
MaintainerNotes: |-                 # notes for whoever maintains the recipe; read by humans later

AutoUpdateMode: Version
UpdateCheckMode: Tags               # or: Tags ^v[\d.]+$   (regex to skip other tags)
VercodeOperation:                   # only for ABI splits / code transforms
  - 10 * %c + 1
CurrentVersion: 1.2.3
CurrentVersionCode: 123
```

- Don't put summary, description, screenshots or changelogs in the YAML; they come from the
  app repo's fastlane folder (the only way to supply images). Text in the YAML would override it. [docs]
- `Binaries` (top level) or `binary:` (per block) is the URL of your signed APK; `%v` = versionName,
  `%c` = versionCode. The URL must be versioned and computable from those two. Use per-block
  `binary:` for ABI splits (one URL per ABI). [docs][seen]
- `AllowedAPKSigningKeys` alone does **not** enable reproducible builds; a reviewer will say so.
  You need both. Get the fingerprint: `apksigner verify --print-certs your.apk | grep SHA-256`,
  lowercase, drop colons. Only single-signer APKs are supported. [docs][seen]
- `AutoUpdateMode: Version` with `UpdateCheckMode: Tags` takes no pattern; the checked tag is used
  directly as the build's commit. [docs]
- `UpdateCheckMode`: `Tags` (reads the version from files at each tag; `Tags <regex>` limits which
  tags), `RepoManifest` (latest commit of the default branch), `HTTP` (URL + `UpdateCheckData`),
  `Static` (no checking). `UpdateCheckData` for Tags: `path|versionCode-regex|path-or-dot|versionName-regex`.
  `UpdateCheckIgnore` (skip versions matching a regex, e.g. `beta`) is HTTP only. [docs]
- `ArchivePolicy`: how many versions stay in the main repo before older ones go to the archive.
  Default 3, or 3 × the number of `VercodeOperation` lines (so 12 for four ABIs). [docs]
- `Disabled:` hides the app from the index with a reason; a build's `disable:` marks one
  unbuildable version (and deletes an already-built APK on the next update). [docs]
- `NoSourceSince` marks the first version without published source. [docs]

## A build block

```yaml
  - versionName: 1.2.3
    versionCode: 1231
    commit: <full 40-char SHA>        # never a tag or branch
    subdir: android/app               # where scripted steps and gradle run
    sudo:                             # root, in the build VM; apt installs only
      - apt-get update
      - apt-get install npm
    init:                             # before any other processing
      - cd ../..
      - npm install --ignore-scripts
    gradle:
      - yes
    binary: 
      https://github.com/<you>/<app>/releases/download/v%v/<app>-v%v-arm64-v8a.apk
    prebuild:                         # prepare the source (before the scanner)
      - cd ../..
      - sed -i ...
    scanignore:
      - node_modules/react-native/sdks/hermesc/linux64-bin/hermesc
    scandelete:
      - node_modules
    build:                            # real building only, after the scan
      - ...
    ndk: 27.1.12297006
```

Fields, as documented [docs]:

| Field | What it does / when to use it |
| --- | --- |
| `commit` | Full hash. Tags and branches are rejected. |
| `subdir` | Where scripted steps run. For Gradle: the path where the `build/` directory is generated (for RN, `android/app`). For Flutter: where `pubspec.yaml` is. A reviewer will ask for this instead of `output:`. |
| `sudo` | Runs as root in the VM, reset after each build. Only things that need root. |
| `init` | Like `prebuild` but runs before anything else. |
| `prebuild` | Prepare the source: patches, generated files. Runs before the scanner. |
| `build` | Actual compilation that isn't Gradle (wheels, cargo, make). Runs after the scan; anything built earlier is cleaned away. A reviewer told an author to move a wheel build here from `prebuild`. [seen] |
| `postbuild` | Post-process outputs; `$$OUT$$` is the APK path. |
| `gradle` | `yes` (no flavour) or flavour names, case sensitive; with flavours you must name at least one (`yes` would build all). Per-flavour fastlane lives in `src/<flavour>/fastlane/...`. |
| `gradleprops` | `-P` properties for Gradle (`foo`, `key=value`). |
| `preassemble` | Extra Gradle tasks before assemble. |
| `output` | Glob to the unsigned APK for manual builds or non-standard layouts. With `gradle:` reviewers usually ask you to delete it and fix `subdir` instead. |
| `rm` | Delete paths before the build (e.g. unused `ios/`). |
| `scanignore` | Paths (prefix match) the scanner skips. "Only where there is a very good reason", ideally with the reason written in the MR. Single files, not packages. |
| `scandelete` | Like `scanignore` but deletes what the scanner flags. `node_modules` is the standard RN entry. |
| `submodules` | `true` runs `git submodule update --init --recursive`. Preferred over `srclibs` (updates need no fdroiddata MR; the scanner covers them). |
| `srclibs` | `name@rev` source libraries under `$$name$$`. Last resort; they can't be auto-updated. |
| `ndk` | Exact NDK version, e.g. `27.1.12297006` or `r27b`. |
| `timeout` | Seconds before the build VM is killed; default 7200 (2 h), `0` = no limit. Matters for Rust/native-heavy apps. |
| `forcevercode`, `forceversion`, `novcheck` | Rewrite or skip the version check; rarely needed. |
| `antifeatures` | Anti-features for this version only. |
| `disable` | Reason string; marks this version unbuildable. |
| `binary` | Per-block reference APK URL. |

Substitutions inside commands: `$$SDK$$`, `$$NDK$$`, `$$VERSION$$`, `$$VERCODE$$`, `$$COMMIT$$`,
`$$OUT$$` (postbuild), `$$<srclib>$$`. Write the double dollars as shown. [docs][seen for VERCODE]

Order on the build server, simplified: checkout → `sudo` → `init` → `prebuild` → scanner
(`scanignore` / `scandelete`) → `build` → Gradle → `postbuild`. Something installed into a folder
that `scandelete` removes is gone unless reinstalled after the scan. [docs][seen]

## Version codes and ABI splits

- With ABI splits each ABI is its own build block and its own versionCode, derived from the app's
  base code by `VercodeOperation` (one line per block, in order). A common scheme:
  `10 * %c + 1..4` for armeabi-v7a, arm64-v8a, x86, x86_64. Never reorder it afterwards. [seen]
- Patch the build to emit the block's code with `sed -i 's/versionCode .*/versionCode $$VERCODE$$/'`
  on the gradle file, so blocks never need hand-edited codes. [seen]
- Play gets `10 * %c + 0` so F-Droid's builds of the same release sort above it and upgrades across
  stores work. [seen]
- Changelogs are looked up by the *final* code (`1231.txt` ... `1234.txt`), not the base code. [seen]
- See `size-abis-r8.md` for choosing which ABIs to ship.

## Formatting CI enforces

The `fdroid rewritemeta` job fails unless the YAML is in canonical form and prints the diff it
wants. Apply that diff exactly. Known quirks of the canonical form: [seen]

- `binary:` followed by its URL on the next line is written `binary: ` with a trailing space.
- Long `sed` lines are folded; a fold point after `sed -i` or after a closing quote keeps a
  trailing space (`sed -i `, `{ false }/' `).
- LF line endings, no comments left from templates.

The official guide runs `fdroid rewritemeta` inside the up-to-date buildserver container. The
mismatch we hit was from a stale local fdroidserver clone. Either way, CI is the judge.

## Fastlane store text (in the app repo)

Check with `scripts/check-fastlane.py <repo> <final version codes>`. Source:
https://f-droid.org/docs/All_About_Descriptions_Graphics_and_Screenshots/

```
fastlane/metadata/android/en-US/          (or metadata/en-US/)
  title.txt                  max 50 chars
  short_description.txt      max 80 chars, mandatory
  full_description.txt       max 4000 chars, mandatory; small HTML subset, not Markdown
  video.txt                  optional URL
  changelogs/<versionCode>.txt   literal final version code, max 500 chars
  images/icon.png  images/featureGraphic.png
  images/phoneScreenshots/1.png 2.png ...   (also sevenInch/tenInch/tv/wear)
```

- `en-US` is the fallback language and is required; other locale folders are optional and preferred
  by the client when they exist.
- Descriptions allow: `b big blockquote br cite em i li ol small strike strong sub sup tt u ul`
  (`a href` works but may be removed). `img`, `iframe`, `script`, `style`, `svg`, `video`, `form`
  and a few more are prohibited. Line breaks become `<br>`. No JavaScript.
- Triple-T layout (`src/main/play/`) is also accepted.
- The text is read from the tagged commit at build time, so fix typos before tagging. [reported]
