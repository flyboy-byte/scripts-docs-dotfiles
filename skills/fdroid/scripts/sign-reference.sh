#!/usr/bin/env bash
# Sign F-Droid's unsigned APKs as reference binaries, the way that byte-compares.
# Usage: sign-reference.sh <outdir> <unsigned.apk>:<output-name.apk> ...
#   e.g. sign-reference.sh ./signed unsigned/tmp/com.x_181.apk:app-v1.0-armeabi-v7a.apk ...
# Environment (never put passwords on the command line or in files in the repo):
#   KS            path to the keystore
#   KEY_ALIAS     key alias
#   KS_PASS       keystore password
#   KEY_PASS      key password (defaults to KS_PASS)
#   EXPECTED_SHA256   the AllowedAPKSigningKeys fingerprint; signing is refused unless the result matches
# Signs with --v1-signing-enabled false --alignment-preserved true (v4 off: no stray .idsig). Never zipaligns.
set -eu
[ $# -ge 2 ] && [ "$1" != -h ] || { sed -n '2,13p' "$0"; exit 0; }
here=$(cd "$(dirname "$0")" && pwd); . "$here/_tools.sh"
signer=$(find_bt apksigner) || { echo "apksigner not found (set ANDROID_HOME)" >&2; exit 1; }
: "${KS:?set KS}" "${KEY_ALIAS:?set KEY_ALIAS}" "${KS_PASS:?set KS_PASS}" "${EXPECTED_SHA256:?set EXPECTED_SHA256}"
export KEY_PASS=${KEY_PASS:-$KS_PASS}
want=$(printf '%s' "$EXPECTED_SHA256" | tr -d ':' | tr 'A-F' 'a-f')
out=$1; shift; mkdir -p "$out"
for pair in "$@"; do
  in=${pair%%:*}; name=${pair#*:}
  [ -f "$in" ] || { echo "no such file: $in" >&2; exit 1; }
  "$signer" sign --ks "$KS" --ks-key-alias "$KEY_ALIAS" --ks-pass env:KS_PASS --key-pass env:KEY_PASS \
    --v1-signing-enabled false --v4-signing-enabled false --alignment-preserved true --out "$out/$name" "$in"
  got=$("$signer" verify --print-certs "$out/$name" 2>&1 | sed -n 's/.*certificate SHA-256 digest: //p' | head -1 | tr 'A-F' 'a-f')
  if [ "$got" != "$want" ]; then
    echo "CERT MISMATCH for $name: got ${got:-none}, want $want. Deleting it." >&2; rm -f "$out/$name"; exit 1
  fi
  echo "ok  $name  cert $got"
done
echo "Upload these to the release matching the binary: URLs, then push Run 2."
