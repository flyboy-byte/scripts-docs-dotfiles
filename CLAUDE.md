# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Last updated 2026-10-23 (pcb-design: extending an existing board, Freerouting 2.5.0, analog-stage simulation). Public repo `flyboy-byte/scripts-docs-dotfiles`, branch `master`.

## Layout

- `skills/<name>/`: Claude Code skills, each a complete installable folder. Read `skills/README.md` before adding or
  changing one.
- `tools/<name>/`: anything more than one file, each with its own `README.md` (`wallpaper-kde` and `whitepaper-formatter` still lack one).
- `scripts/`: single-file scripts.
- `dotfiles/<machine>/`: desktop setups.
- `README.md`: the index. Every skill, tool and script has a row there; keep it in step when adding, moving or removing.

## Commands

There is no build, lint or test suite at the repo root. Each skill and tool is run on its own:

- Skill scripts live in `skills/<name>/scripts/` and are run by path (see that skill's `SKILL.md` and `README.md` for
  arguments). The `pcb-design` scripts are the exception: the skill copies them into each board project's `checks/`,
  and `run_all.py` there runs them together.
- `skills/pkgfilter/scripts/publish.sh` pushes the installed copy of a skill back into `skills/<name>/`; it refuses
  if a personal string is in the files.
- Before committing a skill, check for personal strings: `grep -rnI "$(id -un)\|$HOME" skills/<name>`.

## Conventions

- MIT (root `LICENSE`) unless a folder has its own `LICENSE`. `tools/vfs0090-rhel/` is LGPL-2.1-or-later; keep it so.
- The repo is public: no secrets, personal paths, hostnames or saved preferences in `skills/`. Dotfiles may contain the
  owner's paths; they are one machine's setup.
- The live copy of a skill is in `~/.claude/skills/<name>/`. Edit there and publish back (see `skills/README.md`), or
  keep both in step; don't let this repo drift ahead of the installed copy without saying so.
- Commit messages start with the folder name (`pkgfilter: ...`, `field-mode: ...`).
- Absolute dates in docs.
