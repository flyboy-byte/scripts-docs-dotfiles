#!/usr/bin/env bash
# Which parts of two APKs differ, grouped by class. Signature files are ignored.
# Usage: apk-diff.sh <a.apk> <b.apk>
set -eu
[ $# -eq 2 ] && [ "$1" != -h ] || { sed -n '2,3p' "$0"; exit 0; }
here=$(cd "$(dirname "$0")" && pwd); . "$here/_tools.sh"; need unzip
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
for i in 1 2; do
  f=$([ $i = 1 ] && echo "$1" || echo "$2"); mkdir "$t/$i"; unzip -qq "$f" -d "$t/$i"
  ( cd "$t/$i" && find . -type f ! -path './META-INF/*.SF' ! -path './META-INF/*.RSA' ! -path './META-INF/*.EC' ! -path './META-INF/*.DSA' ! -path './META-INF/MANIFEST.MF' -printf '%P\0' | sort -z | xargs -0 sha256sum ) > "$t/$i.sums"
done
only1=$(comm -23 <(awk '{print $2}' "$t/1.sums") <(awk '{print $2}' "$t/2.sums"))
only2=$(comm -13 <(awk '{print $2}' "$t/1.sums") <(awk '{print $2}' "$t/2.sums"))
changed=$(join -j2 <(sort -k2 "$t/1.sums") <(sort -k2 "$t/2.sums") | awk '$2!=$3{print $1}')
class() { case "$1" in classes*.dex) echo dex;; *.so) echo native-so;; assets/dexopt/*) echo baseline-profile;; resources.arsc) echo resources.arsc;; res/*) echo res;; META-INF/version-control-info.textproto) echo vcs-info;; AndroidManifest.xml) echo manifest;; assets/*) echo assets;; *) echo other;; esac; }
[ -n "$only1" ] && { echo "only in A:"; echo "$only1" | sed 's/^/  /'; }
[ -n "$only2" ] && { echo "only in B:"; echo "$only2" | sed 's/^/  /'; }
if [ -n "$changed" ]; then
  echo "content differs:"
  while read -r p; do echo "  [$(class "$p")] $p"; done <<< "$changed"
  echo; echo "classes:"; while read -r p; do class "$p"; done <<< "$changed" | sort | uniq -c | sed 's/^/  /'
elif [ -z "$only1$only2" ]; then
  echo "All entries identical. If verification still fails the difference is ZIP structure or signing:"
  echo "re-sign F-Droid's own unsigned APK with --v1-signing-enabled false --alignment-preserved true, no zipalign."
fi
