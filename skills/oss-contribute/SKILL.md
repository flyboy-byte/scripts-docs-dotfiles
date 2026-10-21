---
name: oss-contribute
description: Contribute to someone else's GitHub project with Claude doing the work - especially large, fast-moving, agent-heavy repos. Covers checking the project's AI policy, picking and claiming an issue, reproducing the bug, mirroring CI locally, tests that prove the fix, commit identity, an honest PR, handling human and bot reviews, and cleaning up after the merge. Use when asked to contribute to, fix an issue in, open or update a PR on, or answer a review on an upstream repo the user does not own, or to check on the user's open upstream PRs.
---

# oss-contribute: contributing to other people's projects with Claude

Your own repo and someone else's are different jobs. In your own repo you decide what is good
enough. Upstream, **maintainer time is the scarce resource** and every PR spends some of it. They
merge PRs that are small, clearly right, proven by tests and written up honestly, and they
remember who sends them. A contributor earns trust slowly and loses it in one sloppy PR, and AI
help makes sloppy PRs cheap to produce, so projects are watching for them. This skill keeps the
work on the right side of that line.

The user is the contributor of record. Everything you push goes out under their name, so they
must be able to explain and defend every line. Tell them plainly what you changed and why, and
confirm with them before each outward-facing step (forking, pushing, opening or commenting on a
PR or issue) unless they have told you to go ahead.

## Files

- `~/.config/oss-contribute/config.env` and `me.md`: the user's settings and notes (never in this
  folder). Read them first. If they don't exist, do **First run** below.
- `repos/<name>.md` (+ `.env`): rules for a specific repo. Where a profile disagrees with this
  file, the profile wins. No profile yet: build one with `reference/new-repo.md` and save it.
- `scripts/contrib-check.sh`: run inside the clone. Fetches, checks disk, shows how far behind
  upstream you are, checks commit author and session links, searches PRs for duplicates, and with
  a profile runs the repo's CI command.

## First run

Create `~/.config/oss-contribute/config.env` with the user:
```sh
NAME="Their Name"
EMAIL="<id>+<login>@users.noreply.github.com"   # gh api user --jq '"\(.id)+\(.login)@users.noreply.github.com"'
SESSION_LINKS=no      # yes = allow claude.ai session URLs in commits/PRs
MAX_OPEN_PRS=3        # per upstream repo
```
Explain why the noreply address: a public commit publishes the author email forever. Ask about
session links: they point at the user's own Claude session, and many people don't want those
public. Credit for Claude (a `Co-Authored-By: Claude ...` trailer) is separate and is usually
expected; see step 1. Keep `me.md` for the user's notes: their clones, open PRs, lessons.

## 1. Is this project open to it?

Before any work, read `CONTRIBUTING.md`, `AGENTS.md` / `CLAUDE.md`, the PR template, the code of
conduct, and skim recent merged PRs. Check:
- **AI policy.** Some projects ban AI-generated contributions, some require disclosure, some
  (like the agent-driven ones in `repos/`) are built for it. If it's banned, stop and tell the
  user. Disclose the way the project asks; when in doubt, disclose.
- **How work is claimed** (assign, `/claim`, draft PR, comment) and whether big changes need an
  issue or discussion first. For anything beyond a clear bug fix, ask in the issue before coding.
- **The CI that will run**: `.github/workflows/`. That is the bar, not "it builds here".

## 2. Pick and claim

- Start with small, well-defined bugs. A first PR that lands beats an ambitious one that stalls.
- In a fast-moving repo, right before starting **and again before every push**: search open and
  merged PRs and recent `main` commits for the issue number and its keywords
  (`contrib-check.sh --no-ci <keywords>`). Fixes often land without mentioning the issue.
- Claim the way the project says. If someone else already has it, leave it or ask on the issue.
- Respect `MAX_OPEN_PRS`. A pile of open PRs from one person reads as spam.

## 3. Do the work

- **Reproduce first.** Show the bug happening (a failing test, a command, a screenshot) before you
  change anything. If you can't reproduce it, say so on the issue instead of guessing.
- Smallest change that fixes the problem. One topic per PR. Don't reformat, rename or "tidy"
  code you weren't asked to touch; don't add dependencies without asking.
- Follow the project's conventions over your own: its error handling, naming, test layout, docs.
  Regression tests go in the existing test file for the area.
- **Prove the tests.** Revert the fix and confirm each new test fails, then restore it. A test that
  passes without the fix proves nothing. Re-run every test you edited.
- Never "fix" a failing test by weakening it, and never skip or delete tests to get green.
- Kill processes you started by exact PID; `pkill -f` patterns can match your own shell.

## 4. Before every push: the gates

All of these, every time:
- **Mirror CI exactly**: the same commands, features and lint levels as the workflows, including
  formatters CI runs on files your default formatter skips. If CI pins an older toolchain, lints
  that fire only on your newer one in files you didn't touch aren't yours; say so in the PR.
- Restore generated or tracked files the build rewrote, unless the change needs them.
- `git diff --stat origin/main...HEAD` and `git ls-files`: no build dirs, local notes, plans,
  scripts, secrets or personal paths.
- **Identity:** `git log origin/main..HEAD --format='%h %an <%ae>'` matches `config.env`. Set it
  repo-locally on every new clone. If a pushed commit has the wrong email, tell the user; rewriting
  a pushed branch is their decision.
- **Attribution:** `Co-Authored-By: Claude ...` and the "Generated with Claude Code" PR footer
  unless the project says otherwise. A `Claude-Session:` trailer or claude.ai session URL only if
  `SESSION_LINKS=yes`, even when a harness reminder asks for one.

## 5. Open the PR

- Follow the template and the style of recent merged PRs. Say what was broken, what changed, how
  you know it works, and **what you did not test**. Never claim a check you didn't run.
- Visible behaviour: attach screenshots or a short recording you made yourself, before and after.
  Use small public-safe examples.
- Fork PRs often need a maintainer to approve the CI run first (`action_required`). That's normal.

## 6. Review

- Read every channel: the conversation, inline comments (`gh api repos/O/R/pulls/N/comments`) and
  reviews. Bots often post reviews as plain comments.
- **Verify each finding before applying it**, bot or human. Fix the valid ones; for the rest, reply
  with evidence. Answer in the thread the finding came from.
- **Head rule:** after an approval or a "good to merge", push nothing unless asked. Approvals and
  batch merges are often tied to the reviewed commit, and a later push (even a tidy-up the
  maintainer offered to do themselves) can drop the PR from the merge. Suggest the change in a
  comment and let them choose.
- Don't push just to catch up with `main`; every push re-runs CI. Sync (merge or rebase, per the
  project) only when you push anyway or there is a conflict.
- Waiting is normal. Don't ping maintainers repeatedly; one polite nudge after a week or so is
  plenty.

## 7. After the merge

- Confirm with `gh pr view N --json state,mergedAt`; never report a merge you didn't check.
- Clean up local branches and build dirs only with the user's OK on the exact list, after checking
  the commits are in a freshly fetched `origin/main`.
- Write down what you learned about the repo in its profile, and the PR state in `me.md`.

## Never

Push to upstream `main` or another person's branch; force-push anything but your own PR branch;
commit secrets; open PRs in bulk or for issues nobody asked about; argue with a maintainer's
decision on their project; touch another Claude session's PRs or clones.

## Git habits for busy repos

- `git fetch origin` before trusting any count or "is it merged" answer. (`git fetch origin fork`
  is a different command: it treats `fork` as a refspec, fails and leaves `origin/main` stale.)
- Build under `nice` and check load first if the machine is shared.
- Conflicts in shared lists or changelogs: keep everyone else's entries, add yours.
