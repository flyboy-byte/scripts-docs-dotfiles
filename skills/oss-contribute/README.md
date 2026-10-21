# oss-contribute

A [Claude Code](https://claude.com/claude-code) skill for contributing to **someone else's** GitHub
project with Claude doing the work, especially large, fast-moving repos where many people and
agents open PRs every day.

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
- **Tests that prove something.** Reverts the fix to confirm each new test fails without it;
  never weakens or skips tests to get green.
- **Run what CI runs**, exactly, before every push.
- **Your identity.** Commits use your GitHub noreply address; session links stay out unless you
  allow them.
- **Honest PRs** that say what wasn't tested, with screenshots for visible changes.
- **Reviews.** Reads inline and bot comments, verifies each finding before applying it, and
  doesn't push after an approval (that can knock a PR out of a merge).
- Asks before anything public: forking, pushing, opening or commenting on PRs.

## Install

```sh
git clone https://github.com/flyboy-byte/scripts-docs-dotfiles.git
mkdir -p ~/.claude/skills
cp -r scripts-docs-dotfiles/skills/oss-contribute ~/.claude/skills/
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
