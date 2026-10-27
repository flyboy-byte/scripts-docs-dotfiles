# oss-contribute

A [Claude Code](https://claude.com/claude-code) skill for contributing to **someone else's**
open-source project with Claude doing the work: a docs fix, a good bug report, a tested fix, a
feature, or reviewing and verifying other people's changes. It works on small solo repos and on
large, fast-moving ones where many people and agents open PRs every day.

It's for developers who already know git and PRs from their own projects but haven't contributed
upstream much. Your own repo and a big shared one are different jobs: there, maintainer time is
the scarce resource, and PRs land when they are small, clearly right, proven by tests and written
up honestly. AI makes careless PRs cheap, and projects notice. The skill makes Claude work the
careful way:

- **Is AI welcome here?** Reads the project's contributing rules and AI policy first, and stops if
  AI contributions are banned.
- **Don't duplicate.** Searches open and merged PRs right before starting and before each push,
  and claims work the way the project wants.
- **Reproduce, then fix.** Shows the bug first; smallest change, one topic per PR.
- **Tests that prove something.** Reverts the fix to confirm each new test fails without it, and
  checks it fails on the bug the issue reports, not just on a step along the way. Breaks each part
  of a fix in turn, sweeps nearby inputs for regressions, and says when the fixed code isn't
  reachable yet. Never weakens or skips tests to get green.
- **Draft until it's proven.** Keeps a PR in draft until the evidence is in its description, and
  audits its own PR like a reviewer before asking for review. Treats other contributors (and their
  agents) as colleagues: answers their reviews and agrees scope splits instead of racing.
- **Run what CI runs**, exactly, before every push.
- **Your identity.** Commits use your GitHub noreply address; session links stay out unless you
  allow them.
- **Honest PRs** that say what wasn't tested, with screenshots for visible changes.
- **Reviews.** Reads inline and bot comments, verifies each finding before applying it, and
  doesn't push after an approval (that can knock a PR out of a merge).
- Asks before anything public: forking, pushing, opening or commenting on PRs.

## What's in it

- `SKILL.md`: the core workflow, tuned for busy GitHub repos.
- `reference/workflows.md`: the general playbook: choosing a project and a first task, what to do
  for each kind of contribution, small and solo repos, GitLab/Codeberg/email patches, DCO and CLA,
  working with maintainers, stalled or closed PRs.
- `reference/new-repo.md` and `repos/`: per-project profiles.
- `scripts/contrib-check.sh`: the pre-push checks.

## Install

```sh
git clone https://github.com/flyboy-byte/toolbox.git
mkdir -p ~/.claude/skills
cp -r toolbox/skills/oss-contribute ~/.claude/skills/
```

Then in Claude Code, inside a clone of the project: "find a good first issue in this repo and fix
it", "open a PR for this", "answer the review on my PR". On first use Claude asks a few questions
and saves your settings in `~/.config/oss-contribute/config.env` (never in the skill folder):

```sh
NAME="Your Name"
EMAIL="12345+you@users.noreply.github.com"   # gh api user --jq '"\(.id)+\(.login)@users.noreply.github.com"'
SESSION_LINKS=no
MAX_OPEN_PRS=3
```

## Repo profiles

`repos/<name>.md` holds one project's rules (claim style, CI commands, merge-or-rebase, review
bots, files every PR conflicts on); `repos/<name>.env` feeds the check script. The included ones
are agent-driven Rust CAD projects (`tangency-labs/solidcraft`, `tangency-labs/solidcore`,
`storytold/cadcraft`). For any other repo Claude builds a profile on first use, following
`reference/new-repo.md`.

## The check script on its own

Run inside your clone:

```sh
~/.claude/skills/oss-contribute/scripts/contrib-check.sh --no-ci 1234 "keyword"   # fast checks
~/.claude/skills/oss-contribute/scripts/contrib-check.sh                          # plus the profile's CI
```

It fetches, checks free disk, shows how far behind upstream you are and the project's sync rule,
flags commits with the wrong author email or a session link, and lists open and merged PRs that
match your keywords. With a profile it also runs the project's CI command. It never deletes
anything.
