# tangency-labs/solidcraft

Pure-Rust parametric CAD app. Agent-driven: contributions by AI agents are expected. Remotes:
`origin` = upstream (read-only; the repo's docs still say `bherbruck/solidcraft`, which moved to
tangency-labs in 2026-10), `fork` = your fork. Read `AGENTS.md` each time: it is long and changes
often.

## Claim
`gh pr list --state open --search "#N"`; then empty `claim: #N` commit + draft PR titled
`<summary> (#N)`; lowest PR wins; the bot assigns and labels. Push at least daily: a draft idle
72 h may be taken over. Claim races are real: re-check right before starting.

## Non-negotiables (from AGENTS.md)
Clean-room; never read GPL/LGPL CAD code; no commercial-CAD icons, data or screenshots; every
asset needs an ATTRIBUTION.md row; no panics/unsafe in non-test code; everything is a command;
layering (`cargo xtask layers`); never break wasm. Design-format changes: one new file in
`crates/doc/src/format/pending/`. Never regenerate `docs/features.md` or
`THIRD-PARTY-LICENSES.txt` in a PR. Keep lists sorted (`cargo xtask lists --fix`).

## CI to mirror
`cargo xtask ci` (fmt, clippy -D warnings, tests, assets, layers, wasm), with
`CARGO_TARGET_DIR=<repo>/target`, under `nice`. On a shared machine wait while load is over 24.

## Evidence
Observable behaviour needs real screenshots or a recording, before and after if possible: run
the app (`cargo run --release -p solidcraft -- --sample --control PORT`, under `Xvfb :99` if
headless) and drive it over the control channel (`docs/control-protocol.md`). Attach to the PR;
don't commit them.

## Sync
Don't push only to catch up with `main`. When you push anyway or it conflicts: rebase onto
`origin/main` and `--force-with-lease` your own branch, or merge `main` in once. Don't re-run CI
on an unchanged commit.
