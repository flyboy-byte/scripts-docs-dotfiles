# claude-code

The owner's user-level `~/.claude/CLAUDE.md`: the file Claude Code loads in every session on this machine. It is one
person's setup (their projects, their VPS, their conventions), published as an example of how a user-level CLAUDE.md
can carry working conventions across many repos: role-separated docs, resuming without re-deriving, paste-back resume
blocks and handoff files, attempt logs, scope fences.

| File | What |
| --- | --- |
| `CLAUDE.md` | Copy of `~/.claude/CLAUDE.md` with its private sections (server and access details) cut out |
| `publish.sh` | Makes that copy: drops everything between the `private:start` / `private:end` comments, refuses if host or access details survive |

Install (replaces your own; back it up first):

```sh
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.pre-dotfiles 2>/dev/null; cp CLAUDE.md ~/.claude/CLAUDE.md
```

Keeping it current: the live file is `~/.claude/CLAUDE.md`. After changing it, run `./publish.sh` and commit. Never `cp`
the live file here: it has sections that stay private.
