# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Last updated 2026-10-22 (pcb-design skill added). Public repo `flyboy-byte/scripts-docs-dotfiles`, branch `master`.

## Layout

- `skills/<name>/`: Claude Code skills, each a complete installable folder. Read `skills/README.md` before adding or
  changing one.
- `tools/<name>/`: anything more than one file, each with its own `README.md`.
- `scripts/`: single-file scripts.
- `dotfiles/<machine>/`: desktop setups.
- `README.md`: the index. Every skill, tool and script has a row there; keep it in step when adding, moving or removing.

## Conventions

- MIT (root `LICENSE`) unless a folder has its own `LICENSE`. `tools/vfs0090-rhel/` is LGPL-2.1-or-later; keep it so.
- The repo is public: no secrets, personal paths, hostnames or saved preferences in `skills/`. Dotfiles may contain the
  owner's paths; they are one machine's setup.
- The live copy of a skill is in `~/.claude/skills/<name>/`. Edit there and publish back (see `skills/README.md`), or
  keep both in step; don't let this repo drift ahead of the installed copy without saying so.
- Commit messages start with the folder name (`pkgfilter: ...`, `field-mode: ...`).
- Absolute dates in docs.
