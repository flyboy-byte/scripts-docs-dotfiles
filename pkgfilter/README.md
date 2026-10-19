# pkgfilter

Find what is eating your disk. Three pieces:

| | What | Needs |
|---|---|---|
| `pkgfilter.py` | The original: interactive Arch package bloat hunter. Strip keywords and small packages, step by step, then optionally scan a folder for the biggest files. | Python 3, Arch (`pacman`) |
| `skill/pkgfilter/scripts/agentpkgfilter.py` | The same tool made scriptable: `--scan`, `--scan --children` (drill down a level), `--top-packages`, `--state-dir`, `--reset`. It never asks questions and never deletes anything. | Python 3. `--scan` works on any Linux; the package modes need `pacman` |
| `skill/pkgfilter/` | A [Claude Code](https://claude.com/claude-code) skill that runs the agent version and walks you through your home directory: it measures, explains what each big folder is and how safe it is to clear, and leaves the deleting to you. | Claude Code |

Sizes are space used on disk. The scan reads no file contents, does not follow symlinks and does
not leave the filesystem it starts on. Run everything as your own user, not root.

## Use the skill

```sh
git clone https://github.com/flyboy-byte/scripts-docs-dotfiles.git
mkdir -p ~/.claude/skills
cp -r scripts-docs-dotfiles/pkgfilter/skill/pkgfilter ~/.claude/skills/
```

Then in Claude Code, say something like "what's eating my disk?" or "help me clean up my home
folder". Optional: add a line to `~/.claude/CLAUDE.md` pointing at the skill so it is used without being asked.

## Use the script on its own

```sh
python3 pkgfilter/skill/pkgfilter/scripts/agentpkgfilter.py --scan --children          # your home, biggest first
python3 pkgfilter/skill/pkgfilter/scripts/agentpkgfilter.py --scan ~/.cache --children  # one level down
python3 pkgfilter/skill/pkgfilter/scripts/agentpkgfilter.py --top-packages --top 30     # Arch only
```

A scan of a large home directory takes a minute or two; `nice -n 10 ionice -c3` keeps the machine usable.
