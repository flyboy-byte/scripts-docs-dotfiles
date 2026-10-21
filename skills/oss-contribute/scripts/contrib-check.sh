#!/usr/bin/env bash
# Pre-push checks for a contribution to someone else's repo. Run it inside your clone.
# Usage: contrib-check.sh [--repo NAME] [--no-ci] [keyword ...]
#   --repo NAME : use repos/NAME.env (default: the upstream repo's name, if a profile exists)
#   --no-ci     : only fetch, disk, identity and duplicate checks (fast, no compiling)
#   keywords    : searched in open and merged upstream PRs to catch duplicates
# Reads ~/.config/oss-contribute/config.env (NAME, EMAIL, SESSION_LINKS).
# Never deletes anything; apart from `git fetch` and the CI command it only reads.
set -u
here=$(cd "$(dirname "$0")" && pwd)
git rev-parse --git-dir >/dev/null 2>&1 || { echo "run this inside a git clone"; exit 1; }

run_ci=1
repo=""
keywords=()
while [ $# -gt 0 ]; do
  case "$1" in
    --no-ci) run_ci=0 ;;
    --repo) shift; repo=${1:-} ;;
    *) keywords+=("$1") ;;
  esac
  shift
done

config="${OSS_CONTRIBUTE_CONFIG:-$HOME/.config/oss-contribute/config.env}"
NAME="" EMAIL="" SESSION_LINKS=no
# shellcheck source=/dev/null
[ -f "$config" ] && . "$config" || echo "note: no $config yet (see First run in SKILL.md)"

# Upstream: the `upstream` remote if there is one, else `origin`.
remote=origin
git remote | grep -qx upstream && remote=upstream
url=$(git remote get-url "$remote")
detected=$(printf '%s\n' "$url" | sed -E 's#(\.git)?/?$##; s#^.*github\.com[:/]##')
[ -n "$repo" ] || repo=${detected#*/}

UPSTREAM="" MIN_FREE_GB=10 SYNC="" CI_CMD="" PRE_CI="" RESTORE=""
profile="$here/../repos/$repo.env"
if [ -f "$profile" ]; then
  # shellcheck source=/dev/null
  . "$profile"
  echo "profile: repos/$repo.env (read repos/$repo.md for the rules)"
else
  echo "profile: none for '$repo' (build one: reference/new-repo.md)"
fi
[ -n "$UPSTREAM" ] || UPSTREAM=$detected
echo "upstream: $UPSTREAM (remote '$remote')"

free_gb() { df -BG --output=avail . | tail -1 | tr -dc '0-9'; }

echo "== disk"
free=$(free_gb)
echo "free: ${free} GB (minimum ${MIN_FREE_GB}); load: $(cut -d' ' -f1 /proc/loadavg 2>/dev/null)"
if [ "$free" -lt "$MIN_FREE_GB" ]; then
  echo "STOP: below ${MIN_FREE_GB} GB free. Free space first."
  exit 2
fi

echo "== branch"
git fetch -q "$remote" || { echo "fetch failed"; exit 1; }
base="$remote/$(git symbolic-ref -q --short "refs/remotes/$remote/HEAD" 2>/dev/null | sed "s#^$remote/##" || true)"
[ "$base" = "$remote/" ] && base="$remote/main"
branch=$(git branch --show-current)
behind=$(git rev-list --count "HEAD..$base")
echo "on: ${branch}; behind $base by ${behind}, ahead by $(git rev-list --count "$base..HEAD")"
git status --short
if [ "$behind" -gt 0 ]; then
  echo "BEHIND $base by ${behind}. Sync rule: ${SYNC:-see CONTRIBUTING}"
  echo "  new work:        start the branch from a fresh $base"
  case "$SYNC" in
    rebase) echo "  existing branch: git rebase $base, push --force-with-lease (not if approvals are tied to the head)" ;;
    merge)  echo "  existing branch: git merge $base (never rebase a pushed branch)" ;;
  esac
  echo "  open PR under review: don't push only to catch up (head rule)"
fi

echo "== identity and attribution (commits not in $base)"
echo "repo-local: $(git config user.name) <$(git config user.email)>"
if [ -n "$EMAIL" ]; then
  bad=$(git log "$base..HEAD" --format='%h %an <%ae>' | grep -vF "<${EMAIL}>")
  if [ -n "$bad" ]; then echo "WRONG AUTHOR (want $EMAIL) on:"; echo "$bad"; else echo "authors ok"; fi
else
  echo "no EMAIL in config: can't check authors"
fi
if [ "$SESSION_LINKS" != "yes" ]; then
  links=$(git log "$base..HEAD" --format='%h' | while read -r h; do
    git show -s --format=%B "$h" | grep -qi 'claude.ai/code/session' && git show -s --format='%h %s' "$h"
  done)
  [ -n "$links" ] && { echo "SESSION LINK in commit messages (SESSION_LINKS=no):"; echo "$links"; }
fi

echo "== possible duplicates (open and merged PRs)"
if [ "${#keywords[@]}" -eq 0 ]; then
  echo "no keywords given; pass the issue number and a few words"
else
  for k in "${keywords[@]}"; do
    echo "-- ${k}"
    gh pr list -R "$UPSTREAM" --state all --search "$k" --limit 8 \
      --json number,title,state --jq '.[] | "#\(.number) [\(.state)] \(.title)"'
  done
fi

if [ "$run_ci" -eq 0 ]; then echo "(--no-ci: stopping here)"; exit 0; fi
[ -n "$CI_CMD" ] || { echo "no CI_CMD: run the commands from .github/workflows by hand, or add them to a profile"; exit 0; }
[ "$behind" -gt 0 ] && [ "$SYNC" = "rebase" ] && { echo "Refusing to run CI on a stale base."; exit 3; }

if [ -n "$PRE_CI" ]; then echo "== pre-CI"; bash -c "$PRE_CI" || { echo "pre-CI FAILED"; exit 4; }; fi

echo "== CI: ${CI_CMD}"
log="${TMPDIR:-/tmp}/contrib-ci-${repo}.log"
nice -n 10 bash -c "$CI_CMD" >"$log" 2>&1
code=$?
tail -n 15 "$log"
echo "CI exit code: ${code} (full log: ${log})"
# shellcheck disable=SC2086
[ -n "$RESTORE" ] && git checkout -- $RESTORE && echo "restored: ${RESTORE}"
echo "free after: $(free_gb) GB"
exit "$code"
