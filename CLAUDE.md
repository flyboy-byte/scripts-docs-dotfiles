# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Last updated 2026-10-25 (renamed to toolbox; tools/ + scripts/ regrouped into linux/, study/, utils/). Public repo `flyboy-byte/toolbox`, branch `master`.

## Layout

- `skills/<name>/`: Claude Code skills, each a complete installable folder. Read `skills/README.md` before adding or
  changing one.
- Everything else is grouped by topic, not by file count: `linux/` (fixes and desktop tools), `study/` (class
  visualizers and calculators), `utils/` (one-file utilities). Each topic folder has a `README.md` holding the details
  (usage, flags); a multi-file tool inside it (`linux/vfs0090-rhel/`, `windows/windash/`) has its own.
  `archive/` holds retired repos kept for history (imported with `git subtree`, 2026-10-28). Layout changed 2026-10-25 from
  `tools/` + `scripts/`.
- `dotfiles/<machine>/`: desktop setups. `dotfiles/claude-code/` is the owner's `~/.claude/CLAUDE.md` without its private sections;
  refresh it only with `dotfiles/claude-code/publish.sh`, never `cp` (the live file holds a private VPS section).
- `README.md`: the landing page. Every skill, tool and script has a one-line row there and details only in its folder README; keep both in step when adding, moving or removing. `.github/images/` holds its pictures.

## Commands

There is no build, lint or test suite at the repo root. Each skill and tool is run on its own:

- Skill scripts live in `skills/<name>/scripts/` and are run by path (see that skill's `SKILL.md` and `README.md` for
  arguments). The `pcb-design` scripts are the exception: the skill copies them into each board project's `checks/`,
  and `run_all.py` there runs them together.
- `skills/pkgfilter/scripts/publish.sh` pushes the installed copy of a skill back into `skills/<name>/`; it refuses
  if a personal string is in the files.
- Before committing a skill, check for personal strings: `grep -rnI "$(id -un)\|$HOME" skills/<name>`.
- Check a skill against its installed copy: `diff -rq skills/<name> ~/.claude/skills/<name>` (pkgfilter's `README.md`
  exists only here; its `publish.sh` carries just `SKILL.md` and `scripts/`).
- `dotfiles/claude-code/publish.sh` strips the `private:start`/`private:end` blocks and refuses if a private-looking line
  (`ssh `, `sudo`, `vps-`, `extraction/`) survives; mark the line private in `~/.claude/CLAUDE.md`, don't edit the copy.

## Conventions

- MIT (root `LICENSE`) unless a folder has its own `LICENSE`. `linux/vfs0090-rhel/` is LGPL-2.1-or-later; keep it so.
  `skills/pcb-design/LICENSE` is MIT under the original author (sidewinderzz); keep that notice.
- The repo is public: no secrets, personal paths, hostnames or saved preferences in `skills/`. Dotfiles may contain the
  owner's paths; they are one machine's setup.
- The live copy of a skill is in `~/.claude/skills/<name>/`. Edit there and publish back (see `skills/README.md`), or
  keep both in step; don't let this repo drift ahead of the installed copy without saying so.
- Never in this repo: Claude Panel (the CrossLight usage display) or the `claude-usage` skill and its bridge API.
  They stay private.
- Commit messages start with the folder name (`pkgfilter: ...`, `field-mode: ...`).
- Absolute dates in docs.
