# Sourced by the other scripts: finds Android build-tools (apksigner, aapt2).
find_bt() {
  local name=$1 p sdk d
  p=$(command -v "$name" 2>/dev/null) && { echo "$p"; return; }
  for sdk in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk" "$HOME/Library/Android/sdk"; do
    [ -n "$sdk" ] && [ -d "$sdk/build-tools" ] || continue
    d=$(ls -1 "$sdk/build-tools" | sort -V | tail -1)
    [ -x "$sdk/build-tools/$d/$name" ] && { echo "$sdk/build-tools/$d/$name"; return; }
  done
  return 1
}
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing tool: $1" >&2; exit 1; }; }
