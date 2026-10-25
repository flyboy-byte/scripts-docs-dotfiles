# pkgfilter

Find what is eating your disk. Three pieces:

| | What | Needs |
|---|---|---|
| [`../../scripts/pkgfilter.py`](../../scripts/pkgfilter.py) | The original: interactive Arch package bloat hunter. Strip keywords and small packages, step by step, then optionally scan a folder for the biggest files. | Python 3, Arch (`pacman`) |
| `scripts/agentpkgfilter.py` | The same tool made scriptable: `--scan`, `--scan --children` (drill down a level), `--top-packages`, `--orphans`, `--cache-report`, `--state-dir`, `--reset`, and a memory of what you want kept (below). It never asks questions and never deletes anything. | Python 3. `--scan` works on any Linux; the package modes need `pacman` |
| this folder | A [Claude Code](https://claude.com/claude-code) skill that runs the agent version and walks you through your home directory: it measures, explains what each big folder is and how safe it is to clear, and leaves the deleting to you. | Claude Code |

Sizes are space used on disk. The scan reads no file contents, does not follow symlinks and does
not leave the filesystem it starts on. Run everything as your own user, not root.

## Use the skill

```sh
git clone https://github.com/flyboy-byte/toolbox.git
mkdir -p ~/.claude/skills
cp -r toolbox/skills/pkgfilter ~/.claude/skills/
```

Then in Claude Code, say something like "what's eating my disk?" or "help me clean up my home
folder". Optional: add a line to `~/.claude/CLAUDE.md` pointing at the skill so it is used without being asked.

## It remembers what you keep

Tell it once and it never proposes touching it again. The rules live in your own
`~/.config/pkgfilter/prefs.json` (created on first use, never part of this repo):

```sh
agentpkgfilter.py --keep ~/some/folder --reason "why"      # never touch; marked KEEP in every table
agentpkgfilter.py --caution ~/projects                     # only obvious bloat inside; marked CAUTION
agentpkgfilter.py --keep-pkg 'arm-none-eabi-*'             # the same for package names
agentpkgfilter.py --prefs-show        # list the rules      --forget PATH_OR_GLOB   # drop one
```

When you use the skill, Claude reads the rules first and saves new ones when you say "never touch
that" or "I use this".

## Use the script on its own

```sh
python3 skills/pkgfilter/scripts/agentpkgfilter.py --scan --children          # your home, biggest first
python3 skills/pkgfilter/scripts/agentpkgfilter.py --scan ~/.cache --children  # one level down
python3 skills/pkgfilter/scripts/agentpkgfilter.py --top-packages --top 30     # Arch only
```

A scan of a large home directory takes a minute or two; `nice -n 10 ionice -c3` keeps the machine usable.
