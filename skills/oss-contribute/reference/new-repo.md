# Learning a new repo and writing its profile

Do this once per repo, before the first contribution, and save the result as
`repos/<repo-name>.md` (+ `repos/<repo-name>.env` for the script). Copy `repos/_template.md`.

## Read
1. `CONTRIBUTING.md`, `AGENTS.md`, `CLAUDE.md`, `.github/PULL_REQUEST_TEMPLATE*`, `CODE_OF_CONDUCT.md`.
2. `.github/workflows/*.yml`: the exact commands CI runs, toolchain pins, feature flags, OS matrix.
3. The last 10-20 merged PRs (`gh pr list -R O/R --state merged --limit 20`): size, body style,
   how they reference issues, who reviews, which bots comment, how long merges take.
4. Open PRs and issues labelled for newcomers (`good first issue`, `help wanted`, `bug`).
5. Search issues and discussions for "AI", "LLM", "Copilot", "Claude", "generated" for the policy.

## Write down
- **AI policy** and how to disclose.
- **Claim** convention, and whether big changes need an issue first.
- **Non-negotiables** (licensing, no panics, style rules, layering, assets).
- **CI to mirror**: commands, in order, with any env vars; slow steps; files a formatter skips.
- **Sync**: merge `main` in, or rebase and force-push your branch? Any exceptions?
- **Review**: humans and bots, where they post, what "approved" looks like, batch merges.
- **Hotspots**: files nearly every PR edits (changelogs, lists, numbered logs) and how to merge them.
- **Gotchas** you hit, with dates.

## The .env
```sh
UPSTREAM=owner/repo     # optional; detected from the `upstream` or `origin` remote otherwise
MIN_FREE_GB=20
SYNC=merge              # or rebase
PRE_CI='...'            # optional: extra checks before CI (e.g. a formatter on skipped files)
CI_CMD='...'            # what CI runs
RESTORE='reports/'      # optional: tracked paths the build rewrites, restored afterwards
```
