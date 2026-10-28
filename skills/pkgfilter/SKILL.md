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
  Check with `pgrep -x <process name>`, never `pgrep -f`, which also matches your own command line and always says "running".
- Some caches contain read-only directories (unpacked downloads), so `rm -rf` leaves them behind with "Permission denied".
  For a cache the user already approved, `chmod -R u+w <that cache>` and remove it again. Never `chmod` outside the approved path.
- After deleting, report the real result: free space before and after (`df`), not the sum of the sizes you listed.
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
- **Wine prefixes and other app sandboxes** (`~/.wine`, `wineprefixes/`, Proton `compatdata`, Flatpak
  data): before deleting one, look inside for the user's own files and installed programs: `find <prefix>
  -type f` for documents and designs outside the app's own install folders, and `ls drive_c`. A prefix can
  hold local copies of cloud files and programs the user still runs. Copy anything found to a backup
  folder first, confirm it, then delete.
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
- `--orphans-detail` (`--orphans-sort size|date`): the same list with install date, repo or AUR, a rough class
  (debug/docs, python lib, library, other) and description, then what `pacman -Rns` on all the unprotected ones
  would *also* remove. Read that heads-up line before suggesting anything: if removing the batch drags extra
  packages, never suggest the whole batch; suggest only the orphans that take nothing else with them, and treat
  the dragged ones as a separate decision. KEEP and CAUTION orphans stay out of any suggested command. Sorting by
  date groups orphans installed together, usually for one project.
- `--cache-report`: the pacman and AUR (yay) caches and what `paccache` could reclaim (keep 2 versions, keep 1, drop
  uninstalled packages). Most of the pacman cache is current versions of installed packages, the user's way to
  downgrade, so say that before suggesting to empty it.
- Read-only extras that help: `pacman -Qdtq` (orphans), `pacman -Qi <pkg>` (what it is and why it is installed),
  `pacman -Qi` "Required By" before suggesting removal.
- If `pacman` is missing, say the package modes need Arch and use only `--scan`.

## Output you can rely on
`--scan` prints a header, tables of path and size, and a note if some entries could not be read
(permission denied); those are not counted. Mention that note when it appears.

## End of every run: decide whether to update the GitHub copy
This skill has a public home (the repo named by `PUBLISH` in `--prefs-show`). Before you finish, spend
one minute deciding whether this run improved the skill itself, meaning `SKILL.md` or `scripts/`, in a way
anyone using it would want:
- **Publish** when you fixed a bug, added a mode or flag, found that the guidance was wrong or missing (for example a
  folder type you had to judge that the "how to judge" list does not cover), or made the output easier to read.
- **Skip** when nothing in the skill changed, or the only change is personal: the user's rules in `prefs.json`
  (those never leave this machine), their paths, their package names, their preferences.
- To publish: `bash scripts/publish.sh "pkgfilter: <what and why, one line>"` (add `--dry-run` to preview).
  It does nothing unless this machine has a publish repo set, so on a copy someone else installed it simply says so.
  It refuses if a personal string (user name, home path) is in the files. Never edit it around that check.
  Add a `Co-Authored-By: Claude …` trailer line to the message; leave out any session link.
- Say in one line what you pushed or why you did not. Do not push mid-task, only at the end of a run.
- If this machine has no publish repo and you improved something, suggest the change to the user instead.
