# Contribution workflows for any open-source project

The main `SKILL.md` is written for large, fast-moving GitHub repos, and its discipline (reproduce,
prove the tests, mirror CI, honest PR, head rule) applies everywhere. This file covers the rest:
what to do for the different kinds of contribution, and for projects that aren't like that. Use
the part that fits and skip the rest.

## Choosing a project and a first task
- Use it first. The best contributions come from something that broke for you or a gap you hit.
- Check it is alive: recent commits, recent merged PRs from outsiders, issues getting answered.
  A project that hasn't merged an outside PR in a year may not want one.
- Read the licence. You contribute under the project's licence; a CLA or DCO may apply (below).
- Start small: a doc fix, a clear bug, a missing test. Land one before proposing anything big.
- Look at `good first issue` / `help wanted`, but a bug you can reproduce beats a label.

## Kinds of contribution

**Docs, typos, comments.** Cheapest to merge and still worth doing right: confirm the text is
actually wrong (run the command, check the code), match the doc's voice, fix every occurrence in
that file, and leave other docs alone. Don't open a PR per typo; batch the ones in one area.

**A good bug report** (often worth more than a fix):
- Search existing issues first, closed ones too, and add to a thread instead of opening a duplicate.
- Title says what is wrong, not what you were doing.
- Version or commit, OS, how you installed it.
- The smallest steps that reproduce it, and what you expected vs what happened, with the exact error text.
- Say what you already tried and what you did not test. Don't guess at causes as if they were facts.
- Offer a fix only after saying so, and wait if the maintainer says it is not wanted.

**A bug fix.** The main SKILL.md flow. Claim or ask first where the project wants that, reproduce,
smallest change, a test that fails without it.

**A feature.** Open an issue or discussion first and get a yes on the shape before writing code.
Features add maintenance for someone else forever; small, optional, well-tested ones land, big
unrequested ones stall. If they say no, take it gracefully.

**Tests only.** Welcome when they pin real behaviour. A test must fail for a mutated version of
the code; coverage for its own sake isn't a contribution.

**Triage and reproduction.** Reproducing someone else's bug and posting the narrowed steps, or
confirming a fix works, helps maintainers and needs no code. Follow the commenting rules in SKILL.md.

**Translations and packaging.** Follow the project's file layout and glossary exactly; ask who
reviews the language. For packages (distro, F-Droid, Homebrew), the packaging repo's rules win.

**Dependency or toolchain bumps.** Only if asked or you hit the bug; read the changelog and run
the full suite, not a subset.

## Different project shapes
- **Small or solo-maintainer repo.** No policy docs or CI may exist. Ask before a big PR, keep it
  small, make it easy to review, expect slow replies, and follow the existing style closely. If
  the maintainer uses AI themselves, say yours was too.
- **Big foundation project.** Slower, more process: mailing lists or RFCs, CLAs, release branches,
  a named reviewer or maintainers file. Follow the process even when it feels heavy.
- **Not on GitHub.** GitLab merge requests, Codeberg/Gitea PRs, or patches by email
  (`git format-patch` and `git send-email`, one topic per series, a cover letter, plain-text
  mail, reply inline). The principles carry over; the commands don't. Read the project's own page.
- **Monorepo.** Run only the affected packages' checks locally, but run what CI runs for them.
- **Any language.** Find the test and lint commands in CI, not in your habits, and match the
  project's formatter exactly. A formatter diff that rewrites unrelated lines gets a PR closed.

## Legal and sign-off
- **DCO** (`Signed-off-by:` line): add with `git commit -s` using the identity in your settings.
  Only sign off when you can truthfully certify the contribution is yours to give.
- **CLA**: a bot usually asks you to sign once. Read it; if it assigns rights you don't want to,
  ask the user before signing. Never sign for someone else.
- Never paste code from a project with an incompatible licence, or from anything you cannot name
  the licence of. Say where an idea came from in the PR if it matters.

## Fork and branch hygiene
- Fork, clone your fork, add `upstream`. Branch per topic from a fresh upstream default branch.
- Sync with the project's rule (merge or rebase); only force-push your own PR branch, and only
  where rebasing is the rule.
- Delete the branch after merge, once it is confirmed in upstream.
- Keep the PR scope clean: if a second issue shows up, a second branch and PR.

## Working with maintainers
- Be brief, specific and polite; the first message is the one they judge you by.
- One question at a time, with what you already checked.
- Silence for a week is normal: one gentle nudge, then wait or move on. Never ping repeatedly.
- "No" is an answer. Don't argue the project's direction; ask what would make it acceptable, or
  keep the change in your fork.
- Thank people who review. Say when you were wrong, and fix it without defending the first draft.

## When a PR stalls or is closed
- Re-read the thread for the real objection. Small ask: fix and say so once.
- Stale: rebase if the project wants it, reply with what changed, and ask once if it is still wanted.
- Closed as unwanted or duplicate: say thanks, link what replaced it if useful, and move on.
- Don't reopen or repost the same change somewhere else to get around a no.

## Giving back after the first PR
Answer an issue you can, confirm a fix for someone, improve the doc that confused you. Continued
small, reliable help is how a contributor becomes trusted.
