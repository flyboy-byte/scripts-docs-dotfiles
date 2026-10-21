# storytold/cadcraft

Pure-Rust AutoCAD-class CAD app (layers L0-L5, egui UI, WASM). Agent-driven: contributions by AI agents are expected. Remotes: `origin` = storytold (read-only), `fork` = your fork. Profile: `cadcraft.env`.
Read the repo's `CLAUDE.md` each time.

## Pick and claim
- Work list: `docs/gaps.md` (pick from its top rows); `plan/` is gitignored and absent in a clone.
- No claim commits or draft PRs. Search open+merged PRs for the gap id (e.g. `F5`, `U10`) and the
  command name before starting, and again before pushing. A duplicate PR that is better wins:
  close ours and say so.

## Non-negotiables (from the repo's CLAUDE.md)
Clean-room (never read GPL CAD sources, never copy Autodesk assets); no `unwrap/expect/panic`
in non-test code; input-derived numbers are hostile (cap sizes, checked arithmetic); every
user-visible change is a command in `crates/engine/src/cmd/*` with tests; never break wasm.

## CI to mirror
- `CARGO_PROFILE_DEV_DEBUG=0 cargo xtask ci` (fmt, clippy -D warnings, test, assets, layers,
  wasm). Run it in the background; it takes a while. Debug info off keeps `target/` manageable.
- Workflow edits: `actionlint` (Packaging lint runs actionlint + shellcheck on every PR).
- Upstream workflows wait for maintainer approval. To see all five (CI, Packaging lint, Nix,
  FreeBSD, Windows ARM64) early, open a throwaway PR inside the fork (base `<you>:main`),
  read every run, then close it.
- In-app checks: rebuild the binary first, drive it with `--control PORT` JSON lines
  (`cmdline.input`, `engine.execute`, `ui.screenshot`), kill it by exact PID.

## Sync
Rebase on `origin/main`, push `--force-with-lease` to `fork`. Exception: don't rebase a PR whose
approvals are tied to its head unless it conflicts. `docs/gaps.md` (status line + revision table)
is edited by nearly every PR and is the conflict hotspot: keep upstream's rows, put ours on top,
bump the date. When one of our PRs merges, the others usually need this rebase.

## PR body
Match merged #799: prose explaining the gap and what changed, then **Checked:**, **Tests:**,
**Not covered:** paragraphs; no headings. Mention the `docs/gaps.md` row updated.

## Review
- CodeRabbit reviews every PR with **inline** comments: read `gh api
  repos/storytold/cadcraft/pulls/N/comments`, verify each finding, fix the valid ones, reply in
  the thread; it resolves its own threads after a fix.
- FredApps reviews and approves but has no write access, so `reviewDecision` stays empty even
  when approved. Treat their approval as an approval for the head rule.

