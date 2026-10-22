#!/usr/bin/env bash
# Download the unsigned APKs from a fork pipeline's `fdroid build` job.
# Usage: fetch-ci-apks.sh <gitlab-user/fdroiddata> <job-id> <outdir>
#   e.g. fetch-ci-apks.sh someone/fdroiddata 17262098501 ./run1
# Needs glab (authenticated) and unzip. APKs land in <outdir>/unsigned/tmp/<appid>_<code>.apk
set -eu
[ $# -eq 3 ] || { sed -n '2,5p' "$0"; exit 1; }
here=$(cd "$(dirname "$0")" && pwd); . "$here/_tools.sh"; need glab; need unzip
proj=${1//\//%2F}; job=$2; out=$3
mkdir -p "$out"
glab api "projects/$proj/jobs/$job/artifacts" > "$out/artifacts.zip"
unzip -qo "$out/artifacts.zip" -d "$out/unsigned"
ls -l "$out"/unsigned/tmp/*.apk 2>/dev/null || { echo "no APKs in the artifacts (is $job the 'fdroid build' job?)" >&2; exit 1; }
