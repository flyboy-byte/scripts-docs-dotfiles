#!/usr/bin/env bash
# Summarise APKs: package, version, ABIs shipped, permissions, signer cert, sha256.
# Usage: apk-inspect.sh <apk>...
set -u
[ $# -ge 1 ] && [ "$1" != -h ] || { sed -n '2,3p' "$0"; exit 0; }
here=$(cd "$(dirname "$0")" && pwd); . "$here/_tools.sh"; need unzip
aapt2=$(find_bt aapt2) || aapt2=""; signer=$(find_bt apksigner) || signer=""
for f in "$@"; do
  echo "== $f"
  sha256sum "$f" | awk '{print "  sha256  ", $1}'
  if [ -n "$aapt2" ]; then
    "$aapt2" dump badging "$f" 2>/dev/null | head -1 | sed -E "s/.*name='([^']*)' versionCode='([^']*)' versionName='([^']*)'.*/  package  \1  versionCode \2  versionName \3/"
    "$aapt2" dump permissions "$f" 2>/dev/null | sed -n 's/^uses-permission: name=//p' | tr -d "'" | sed 's/^/  perm     /'
  fi
  echo "  abis    " $(unzip -l "$f" | grep -o 'lib/[^/]*/' | sort -u | tr '\n' ' ')
  echo "  .so files:" $(unzip -l "$f" | grep -c '\.so$')
  if [ -n "$signer" ]; then
    "$signer" verify --print-certs "$f" 2>&1 | grep -iE 'SHA-256|Verified|DOES NOT|ERROR' | sed 's/^/  /'
  else echo "  (apksigner not found: set ANDROID_HOME)"; fi
done
