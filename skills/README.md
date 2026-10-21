# Skills

[Claude Code](https://claude.com/claude-code) skills. Each folder here is a complete skill: copy it into
`~/.claude/skills/` and Claude picks it up.

```bash
cp -r skills/<name> ~/.claude/skills/
```

## Layout of a skill folder

```
skills/<name>/
  SKILL.md       what Claude reads: frontmatter (name, description) and the instructions
  README.md      for people: what it does, how to install it, how to use the scripts without Claude
  scripts/       anything SKILL.md runs, referred to by paths relative to the skill folder
```

- The folder name, the `name:` in `SKILL.md` and the folder under `~/.claude/skills/` are the same.
- The `description:` decides when Claude uses the skill: say what it does and the phrases a user would say.
- Scripts are read-only or ask before changing anything, unless the skill says otherwise.

## Rules

- **Nothing personal.** No user names, home paths, hostnames, keys or saved preferences. A skill that remembers
  things keeps them on the user's machine (pkgfilter uses `~/.config/pkgfilter/prefs.json`), never in this folder.
- **One source of truth.** The copy in `~/.claude/skills/<name>/` is the one in use. Change it there, then bring
  this folder up to date (by hand, or with the skill's own publish script if it has one).
- Add a row to the **Skills** table in the root `README.md`.

## Publishing from the installed copy (optional)

`pkgfilter/scripts/publish.sh` pushes the installed skill's `SKILL.md` and `scripts/` back to `skills/<name>/` here,
using the folder name, so a new skill can copy it as is. It only runs on a machine that has named a publish repo,
refuses if a personal string is in the files, and commits as the GitHub noreply address. It reads the publish repo
from pkgfilter's prefs file (`PKGFILTER_PREFS`); a new skill should point that at its own prefs file.

## Adding one

1. Make it in `~/.claude/skills/<name>/` and use it until it works.
2. Copy it here: `cp -r ~/.claude/skills/<name> skills/`, then add a `README.md`.
3. Check for personal strings: `grep -rnI "$(id -un)\|$HOME" skills/<name>`.
4. Add the row to the root `README.md` and commit as `<name>: <what>`.
