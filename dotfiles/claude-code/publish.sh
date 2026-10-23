#!/bin/sh
# Copy ~/.claude/CLAUDE.md here without its private sections (between the private:start / private:end HTML comments),
# then refuse if anything private-looking survived. Commit afterwards; pushing is a separate, deliberate step.
set -e
here=$(dirname "$0")
sed '/^<!-- private:start -->$/,/^<!-- private:end -->$/d' "$HOME/.claude/CLAUDE.md" > "$here/CLAUDE.md"
if grep -n 'ssh \|sudo\|vps-\|extraction/' "$here/CLAUDE.md"; then
    echo "publish.sh: private-looking lines above survived; mark them private in ~/.claude/CLAUDE.md" >&2
    exit 1
fi
echo "published $(wc -l < "$here/CLAUDE.md") lines to $here/CLAUDE.md"
