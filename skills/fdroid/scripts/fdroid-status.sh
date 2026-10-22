#!/usr/bin/env bash
# Where is this app in F-Droid? Reports each layer separately.
# Usage: fdroid-status.sh <appid>
# Read-only. Needs curl and python3.
set -u
case "${1:-}" in ""|-h|--help) sed -n '2,5p' "$0"; exit 0 ;; esac
app=$1
here=$(cd "$(dirname "$0")" && pwd); . "$here/_tools.sh"; need curl; need python3

echo "== f-droid.org listing (what users can install)"
curl -s "https://f-droid.org/api/v1/packages/$app" | python3 -c '
import json,sys
try: d=json.load(sys.stdin)
except Exception: print("  not listed (or API unreachable)"); sys.exit()
if "packageName" not in d: print("  not listed"); sys.exit()
print("  suggested versionCode:", d.get("suggestedVersionCode"))
for p in d.get("packages",[])[:8]: print("  ", p["versionName"], p["versionCode"])'

echo; echo "== upstream metadata (what F-Droid will build)"
y=$(curl -s "https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/$app.yml")
if printf '%s' "$y" | grep -q '^Builds:'; then
  printf '%s\n' "$y" | grep -E '^(CurrentVersion|CurrentVersionCode|AutoUpdateMode|UpdateCheckMode):'
  echo "  build blocks:"; printf '%s\n' "$y" | grep -E '^  - versionName:|^    versionCode:' | paste - - | sed 's/^/   /'
  codes=$(printf '%s\n' "$y" | sed -n 's/^    versionCode: //p' | tail -8)
else
  echo "  no metadata file upstream (not merged yet)"; codes=""
fi

echo; echo "== recent commits to the recipe (bot updates and maintainer edits)"
curl -s "https://gitlab.com/api/v4/projects/fdroid%2Ffdroiddata/repository/commits?path=metadata/$app.yml&per_page=6" |
  python3 -c '
import json,sys
try: cs=json.load(sys.stdin)
except Exception: cs=[]
for c in cs: print("  ",c["committed_date"][:16],c["author_name"],"-",c["title"])'

echo; echo "== real build server result per version code"
for c in $codes; do
  r=$(curl -sL "https://monitor.f-droid.org/builds/log/$app/$c" | sed 's/<[^>]*>/\n/g')
  if ! printf '%s' "$r" | grep -q 'INFO: Building\|Successfully built\|BUILD '; then echo "  $c: no log yet"; continue; fi
  ok=$(printf '%s' "$r" | grep -c 'successfully verified')
  built=$(printf '%s' "$r" | grep -o 'Successfully built [^ ]* from [0-9a-f]*' | head -1)
  bad=$(printf '%s' "$r" | grep -iE 'BUILD FAILED|Could not resolve|^.*ERROR: ' | head -1 | cut -c1-140)
  if [ -n "$bad" ] && [ "$ok" = 0 ]; then echo "  $c: FAILED  $bad"
  elif [ "$ok" -gt 0 ]; then echo "  $c: built and verified  ($built)"
  elif [ -n "$built" ]; then echo "  $c: built, no reference comparison  ($built)"
  else echo "  $c: log present, result unclear"; fi
done
echo; echo "Layers: listing = users; upstream = queued; build log = server. Index lag after a verified build is normal."
