#!/usr/bin/env bash
# Push this skill's SKILL.md and scripts to skills/<skill-name>/ in its GitHub repo, if (and only if) this machine's
# prefs name a repo with `agentpkgfilter.py --publish-repo OWNER/REPO`.
# usage: publish.sh [--dry-run] "commit message"
# Never pushes prefs.json or anything outside the skill folder. Commits as your GitHub noreply
# address, not your real email.
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; NAME="$(basename "$SKILL_DIR")"
DRY=0; [ "${1:-}" = "--dry-run" ] && { DRY=1; shift; }
MSG="${1:?usage: publish.sh [--dry-run] \"commit message\"}"
PREFS="${PKGFILTER_PREFS:-$HOME/.config/pkgfilter/prefs.json}"
REPO="$(python3 -I -c 'import json,sys;print(json.load(open(sys.argv[1])).get("publish",""))' "$PREFS" 2>/dev/null || true)"
[ -n "$REPO" ] || { echo "No publish repo set on this machine (--publish-repo): not publishing."; exit 0; }
command -v gh >/dev/null || { echo "gh is not installed: not publishing."; exit 1; }
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
git clone -q --depth 1 --filter=blob:none --sparse "https://github.com/$REPO.git" "$WORK/repo"
DEST="skills/$NAME"; cd "$WORK/repo"; git sparse-checkout set "$DEST" >/dev/null; mkdir -p "$DEST/scripts"
cp "$SKILL_DIR/SKILL.md" "$DEST/SKILL.md"
find "$SKILL_DIR/scripts" -maxdepth 1 -type f ! -name "*.pyc" -exec cp -t "$DEST/scripts/" {} +
# Nothing personal may go public: the user name, the home path, and the prefs themselves.
if grep -rnIE "$(id -un)|$HOME" "$DEST" | grep -v "flyboy-byte/toolbox" >/dev/null; then
  echo "Refusing to publish: a personal string (user name or home path) is in the skill files:"; grep -rnIE "$(id -un)|$HOME" "$DEST" | head -5; exit 1
fi
git add -A "$DEST"
if git diff --cached --quiet; then echo "Nothing changed: GitHub already has this version."; exit 0; fi
git diff --cached --stat | tail -4
[ "$DRY" = 1 ] && { echo "(dry run: not committed)"; exit 0; }
ID_EMAIL="$(gh api user -q '"\(.id)+\(.login)@users.noreply.github.com"')"; NAME="$(gh api user -q '.name // .login')"
git -c user.name="$NAME" -c user.email="$ID_EMAIL" commit -q -m "$MSG"
BR="$(git branch --show-current)"; git push -q origin "$BR"; echo "Pushed to $REPO ($BR): $(git log -1 --format='%h %s')"
