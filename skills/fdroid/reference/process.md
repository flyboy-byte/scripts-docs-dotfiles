# The F-Droid lifecycle

Claims are marked where it matters: **[seen]** observed on real submissions and releases,
**[docs]** from F-Droid's docs, templates or MR template, **[reported]** second-hand or a pattern
seen once. Don't present a [reported] item to the user as a rule.

## The pieces

| Piece | Where | What it does |
| --- | --- | --- |
| `fdroiddata` | gitlab.com/fdroid/fdroiddata | One YAML recipe per app in `metadata/<appid>.yml`, templates in `templates/`. |
| Your fork | gitlab.com/<you>/fdroiddata | Where you push branches. Its CI runs the same checks and a real `fdroid build`. |
| RFP | gitlab.com/fdroid/rfp | "Request for packaging" issues. Optional for authors submitting their own app; reference one if it exists. [docs] |
| Fork CI | your fork's pipelines | lint, rewritemeta, schema validation, checkupdates, fdroid build, check apk, check source code, ... Has internet. [seen] |
| Build server | F-Droid infra | Builds merged recipes for release. **Offline** apart from `sudo:` apt installs. Logs at `https://monitor.f-droid.org/builds/log/<appid>/<versionCode>`. [seen] |
| Index | f-droid.org | Published periodically after builds. API: `https://f-droid.org/api/v1/packages/<appid>`. [seen] |
| checkupdates bot | upstream master | Watches your tags and commits "Update <App> to <code>" with new build blocks. [seen] |

## Setting up (once)

- A GitLab account and a **public** fork of fdroiddata, branches not protected. [docs]
- `glab` authenticated (`glab auth login`) for pipelines and artifacts; `gh` for GitHub releases.
- Remotes in the clone: `origin` = your fork, `upstream` = fdroid/fdroiddata. Fetch upstream
  before every new branch.
- Android build-tools (`apksigner`, `aapt2`, `zipalign`) locally for signing and inspection.

## New app inclusion

1. **Policy first** (`policy.md`): FOSS licence, no non-free dependencies, anti-features
   identified. If something blocks, stop and tell the user before any work.
2. **Store text in the app repo**, not the MR: fastlane layout (see `metadata.md`), `en-US`
   required, changelogs named by the *final* version codes F-Droid will build. [docs][seen]
3. **Tag releases** in the app repo (`vX.Y.Z` is conventional) so `UpdateCheckMode: Tags` works.
   Reviewers expect auto-update unless there's a reason. [docs]
4. **Write the recipe** on a fork branch from fresh `upstream/master`: copy the stack's template,
   delete every comment, fill in. Look at two or three recently merged apps on the same stack.
5. **Run 1**: push without `binary:` / `Binaries:`. Expected failures in this run when you've
   declared `AllowedAPKSigningKeys` but not yet the binaries and the tag doesn't exist yet:
   `schema validation` and `checkupdates`. Everything else must pass. [seen]
6. **Sign and publish references** (`reproducible.md`): download the unsigned APKs from the
   `fdroid build` job, check them (`apk-inspect.sh`), sign with `sign-reference.sh`, create the
   GitHub release with them attached (this also creates the tag).
7. **Run 2**: add `binary:` lines, push; the build job compares bytes and must log
   `...successfully verified` / `compared built binary to supplied reference binary successfully`.
8. **Open the MR** titled `New app: <Name>`, using the MR template (the description has
   questions about what the app does and why; answer them, attach screenshots, tick the
   checklist honestly). One app per MR. [docs]
9. Squash noisy fixup commits before asking for review if the history is long; don't rebase
   otherwise unless there's a conflict (the MR template says this). [docs]

## Review

- Reviewers are volunteers. Expect days between rounds. [seen]
- Asked to "follow the template": that means every part, including the install command, JDK
  patching and scanner fields. Explaining why your setup differs doesn't work; changing it does. [seen]
- Inline suggestions: apply them to *every* build block that needs the same change, not only
  the one they commented on, then say so. [seen]
- Typical requests: reproducible build, ABI splits for large native apps, narrower `scanignore`,
  dropping unused permissions, fixing metadata the CI report flags. [seen]
- A community tester may install and check the app (permissions vs what the app does, VirusTotal,
  UI on a real phone). Address findings in the app repo and say what changed. [seen]
- Reply in the MR with what changed, the commit, and the green pipeline link. Keep it short.

## After merge

- The build server builds the merged versions; the index picks them up on a later publish.
  Days, not hours, is normal. [seen]
- Use `scripts/fdroid-status.sh <appid>` to see every layer at once.

## Updates (after the app is in)

With `AutoUpdateMode: Version` and `UpdateCheckMode: Tags`, there's no MR per release. [docs][seen]
`checkupdates` sees the new tag, reads versionName/versionCode at that tag (from the file the
recipe points at, e.g. `android/app/build.gradle`, or after the recipe's own seds), applies
`VercodeOperation`, and appends build blocks **copied from the latest existing ones**, including
their `binary:` URL patterns. So:

1. Bump version name and code in the app repo; add changelogs for the final codes.
2. Merge to the release branch and push. **Don't tag yet.**
3. Fork branch from fresh `upstream/master`; add blocks for the new version (copy the latest
   upstream blocks, set `commit:` to the full SHA, no `binary:`), bump `CurrentVersion` /
   `CurrentVersionCode`. Push = Run 1.
4. Optional determinism check: retry the `fdroid build` job and compare the two outputs
   byte for byte (`cmp`). Identical twice is good evidence the release will verify. [seen]
5. Sign, verify cert, `gh release create vX.Y.Z --target <sha>` with all APKs.
6. Add `binary:` to the fork blocks and push = Run 2. All comparisons must pass.
7. Stop. The fork branch is a test harness; don't open an MR unless the bot stalls for a long
   time. checkupdates commits the real blocks upstream. [seen]
8. A day or two later run `fdroid-status.sh`. Then check again until the listing updates.

Pre-releases: if the recipe reads the version from a committed file, keep that file at the last
stable version on beta tags, or use an `UpdateCheckMode: Tags <regex>` that excludes beta tags
(e.g. `Tags ^v[\d.]+$`), or the bot will try to package the beta. [seen]

## How long things take (calibration) [seen]

- Inclusion MR with an engaged author: about 2 weeks of back-and-forth, then waiting for the
  maintainers' testing queue. Another MR with a heavy stack had been open 2+ months with 100+ commits.
- After a tag: the bot commits new blocks within about a day; the build server builds within about a
  day; the index published the new version about five days after the tag in one case. Report each
  layer; never promise a date.
- When maintainers say "we'll test it later" they mean the review-requested queue. Helping test other
  MRs is welcome (`reviewing-others.md`).

## While an MR is open

- If you cut a new release, **update the MR** to it. Reviewers ask for this.
- Keep a running list of reviewer requests (a comment or your doc) and re-check it before every push.
- After any rebase or sync, diff against the last reviewed commit.
- Only the latest versions' blocks belong in a new-app MR; the bot keeps older ones after merge.
- One MR, one app.

## If F-Droid is slow: a stopgap

You can run your own F-Droid repository (`fdroid update && fdroid deploy` on a static host) and let
users add it. It uses your signature and your schedule, but not the official index. One author did this
as a stopgap during review. Don't present it as a replacement. [seen] Docs:
https://f-droid.org/docs/Setup_an_F-Droid_App_Repo/

## Commands

```bash
# pipelines on a fork branch (project path URL-encoded)
glab api "projects/<you>%2Ffdroiddata/pipelines?ref=<branch>&per_page=3"
glab api "projects/<you>%2Ffdroiddata/pipelines/<pid>/jobs" | python3 -c 'import sys,json;[print(j["id"],j["name"],j["status"]) for j in json.load(sys.stdin)]'
glab api "projects/<you>%2Ffdroiddata/jobs/<job>/trace" | tail -80     # a job's log
glab api -X POST "projects/<you>%2Ffdroiddata/jobs/<job>/retry"        # rerun a job

# upstream recipe history (bot updates, maintainer edits)
curl -s "https://gitlab.com/api/v4/projects/fdroid%2Ffdroiddata/repository/commits?path=metadata/<appid>.yml&per_page=5"
```
