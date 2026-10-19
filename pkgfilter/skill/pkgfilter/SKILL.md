---
name: pkgfilter
description: Find what is using disk space in the user's home directory and which installed Arch packages are bloat, then walk through it interactively and suggest what is safe to clean. Use when the user asks what is eating their disk or storage, wants to free space, clean up their home folder, find big folders or files, or review installed packages for bloat.
---

# pkgfilter: disk and package bloat hunter

A read-only helper. It measures and reports; **you** interpret the output and the **user** decides
what to delete. The script is `scripts/agentpkgfilter.py`, next to this file
(normally `~/.claude/skills/pkgfilter/scripts/agentpkgfilter.py`). Do not look for another
copy and do not ask the user where the script is.

## Start every session here: what this user keeps
Run `python3 scripts/agentpkgfilter.py --prefs-show` first. It lists the rules saved in
`~/.config/pkgfilter/prefs.json` (a personal file, never part of the skill's repo). Every scan and
package table marks matching rows `KEEP` or `CAUTION`.
- **KEEP**: never propose touching it, whatever the size, and refuse a request like "delete everything over 1 GB"
  that would reach it. Mention it only to say it is protected.
- **CAUTION**: leave it alone unless something inside is plainly regenerable bloat (build output, caches, `__pycache__`).
  Name that specific thing and ask.
- **Learn as you go.** When the user says to keep, never touch, or "I use this" about a path or package, save it
  at once: `--keep PATH --reason "..."` / `--caution PATH` / `--keep-pkg 'glob*'` / `--caution-pkg 'glob*'`.
  Use `--caution` for "mostly leave it", `--keep` for "never". When you infer a rule instead of being told, say
  `[inferred, confirm]` in `--reason`, and tell the user. `--forget` removes a rule; `--prefs-show` lists them.
- If the file is empty (a new user), say so and build it as you go; do not guess at rules.

## Rules
- Run as the user. **Never use sudo or scan `/`.** The home directory is the scope.
- **Deleting.** By default only suggest: give the exact command and let the user run it. You may delete
  yourself only when the user has approved *that exact list of paths* in this conversation, the paths are
  the user's own (no sudo), and none is KEEP. Prefer `gio trash` for anything the user made or downloaded;
  use `rm -rf` only for regenerable caches the user approved. Show the paths and sizes first and
  confirm what was freed afterwards. Anything needing root (`sudo pacman -Rns`, `sudo paccache`) is for
  the user's own terminal; give the command, do not run it.
- Do not delete a cache while its app is running (browsers, the Claude desktop app, Steam): ask the user to close it first.
- Run scans as `nice -n 10 ionice -c3 python3 <script> ...`. A scan of a large home can take a
  minute or two; say so before starting, and do not repeat a scan you already have.
- Sizes are space used on disk (blocks), so sparse files count for what they take.

## Home directory: drill down
1. Overview: `python3 scripts/agentpkgfilter.py --scan --children --top 20`
   (the immediate children of the home directory, largest first).
2. Pick the biggest or most suspicious entries and go one level down:
   `python3 scripts/agentpkgfilter.py --scan ~/.cache --children --top 20`
3. For the biggest single files anywhere in a tree: `--scan PATH --top 20` (without `--children`).
4. After each step, summarise in a short table: path, size, what it is, and how safe it is to
   clear. Then ask which area to look at next. Do not dump raw output.

How to judge what you see (say when you are unsure, and never claim certainty about a folder
you have not looked inside):
- **Regenerable caches**: `~/.cache/*`, package-manager caches (`~/.gradle/caches`, `~/.cargo/registry`,
  `~/.npm`, pip), and build output (`target/`, `node_modules/`, `build/`, `__pycache__`). Safe to
  clear, at the cost of a rebuild or re-download.
- **Toolchains and SDKs** (`~/.platformio`, `~/.arduino15`, `~/.espressif`, `~/Android`): large but
  needed by something; removing one breaks that tool until reinstalled. Ask what the user still uses.
- **App state and data** (`~/.config`, `~/.local/share`, games, VMs, containers, browser profiles,
  chat history): may hold the user's real data or sign-ins. Do not suggest clearing blindly; look
  one level deeper first.
- **Downloads, old projects, duplicated checkouts**: the user's call. List them and ask.

## Installed packages (Arch only)
- Biggest packages: `python3 scripts/agentpkgfilter.py --top-packages --top 30 --state-dir ~/.local/state/pkgfilter`
- The review queue: each run removes the packages you *recognise as fine* from the list, so what is
  left is what needs a decision. `-k WORD` strips every package whose name contains WORD, `-s 20MiB`
  drops packages smaller than that. Each run saves the next `revisionN.txt` in the state directory:
  `python3 scripts/agentpkgfilter.py -k plasma -s 20MiB --state-dir ~/.local/state/pkgfilter`
- To start over: `--reset --state-dir ~/.local/state/pkgfilter` (ask first: it forgets the queue).
- `--orphans`: packages nothing needs any more, with sizes and KEEP/CAUTION marks, and the total that is not protected.
  Orphans are not automatically junk: toolchains installed once for a project show up here, which is what
  CAUTION rules are for. Check each unfamiliar one with `pacman -Qi` before suggesting removal.
- `--cache-report`: the pacman and AUR (yay) caches and what `paccache` could reclaim (keep 2 versions, keep 1, drop
  uninstalled packages). Most of the pacman cache is current versions of installed packages, the user's way to
  downgrade, so say that before suggesting to empty it.
- Read-only extras that help: `pacman -Qdtq` (orphans), `pacman -Qi <pkg>` (what it is and why it is installed),
  `pacman -Qi` "Required By" before suggesting removal.
- If `pacman` is missing, say the package modes need Arch and use only `--scan`.

## Output you can rely on
`--scan` prints a header, tables of path and size, and a note if some entries could not be read
(permission denied); those are not counted. Mention that note when it appears.
