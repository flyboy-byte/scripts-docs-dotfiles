# tangency-labs/solidcore

Rust port of NVIDIA SMLib (the geometry kernel SolidCraft will use). Agent-driven: contributions
by AI agents are expected. Remotes: `origin` = tangency-labs (read-only), `fork` = your fork.

## Claim
Empty `claim: #N` commit + draft PR from your fork, title ends `(#N)`; lowest PR number wins.
Most porting units already have claims; bugs and findings are a better way in.

## Correct means "as upstream"
Behaviour must match the C++ reference, bugs included. An upstream bug is logged, not fixed:
`plan/upstream-issues.md` numbered entries (`UB-n` undefined behaviour, `HANG-n`, `WR-n` wrong
result), plus `plan/findings.md`. Take the next free number **after a real `git fetch origin`**
and re-check before every push: other PRs take numbers concurrently and clashes happen.
`plan/PROGRESS.md` is generated.

## CI to mirror
- `cargo fmt --all --check`, plus `rustfmt --edition 2021 --check` by hand on `include!`d files
  (e.g. `crates/difftest/src/units/curve_curve_p9.rs`), which `cargo fmt` skips.
- `cargo clippy --workspace --all-targets -- -D warnings` **and** again with
  `--features difftest/cpp`.
- `cargo test --workspace`; wasm32 check.
- difftest: `cargo run --profile difftest -p difftest --features cpp -- --green` (25-40 min on a
  laptop) must stay at 0 failed; for one unit `--unit <name> --seeds 30000`.
- The C++ reference needs `upstream/` (usd-brep) and `harness/cpp/build.sh --jobs 4`.
- CI pins a Rust version (`rust-toolchain.toml`, 1.98 as of 2026-10); newer local toolchains add
  lints in untouched files (1.99: `clippy::assert_is_empty`, `clippy::explicit_iter_loop`) that stop clippy before it reaches
  `difftest`. Without rustup, allow those lints (`-A clippy::...`) so the run covers every crate.
- No sccache: `RUSTC_WRAPPER` unset; cap `CARGO_BUILD_JOBS` on a small machine.
- `reports/difftest/*.json` are tracked and rewritten by runs: `git checkout -- reports/`.

## Sync
Merge `origin/main` into the branch; never rebase a pushed branch.

## Review
The `tangency-monitor` bot reviews as PR comments ("Reviewed and good to merge once CI is
green"). Maintainers land PRs in batch PRs that merge each PR's reviewed head sha, so the head
rule is strict: a push after review (even a renumber the maintainer offered to do) leaves the PR
out of the batch. Fork PR CI needs maintainer approval (`action_required`).

## Cleanup
`bin/` grows to 4-6 GB after the C++ and Rust difftest builds; delete it once your PRs merge.
