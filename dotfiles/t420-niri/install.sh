#!/bin/sh
# Copy the user-level dotfiles into $HOME. Existing files are backed up as *.pre-dotfiles.
# Root-level files live in system/ and are NOT touched; see README for the sudo steps.
set -e
here=$(cd "$(dirname "$0")" && pwd)
copy() {  # copy SRC DEST
    mkdir -p "$(dirname "$2")"
    if [ -e "$2" ] && ! cmp -s "$1" "$2"; then cp -a "$2" "$2.pre-dotfiles"; fi
    cp "$1" "$2"
}
(cd "$here/home" && find . -type f) | while read -r f; do copy "$here/home/$f" "$HOME/$f"; done
for f in "$here"/bin/*; do copy "$f" "$HOME/.local/bin/$(basename "$f")"; chmod +x "$HOME/.local/bin/$(basename "$f")"; done
echo "Done. Next: niri validate, then log out/in. Root steps: see README (system/)."
