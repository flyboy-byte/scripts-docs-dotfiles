# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

User-level memory for Logan's machine — it loads in **every** session on this host. It describes
conventions that already exist across `~/projects/`, so a fresh session can orient without being
re-told. It is a reading guide, not a mandate: follow the project's lead, and don't manufacture this
scaffolding in a project that hasn't asked for it.

## Environment

- Arch Linux (zen kernel), zsh. Everything lives under `~/projects/`, which is a plain directory —
  not a repo. Each subdirectory is its own project, most with their own git repo and `CLAUDE.md`.
- Sessions are often driven remotely from a phone (that's what `afk-host` is for), so work should
  stay legible in files rather than only in the transcript.
- Disk space, "what's eating my storage", home-folder cleanup or package bloat: use the `pkgfilter`
  skill (`~/.claude/skills/pkgfilter`, script `scripts/agentpkgfilter.py`; source repo
  `flyboy-byte/scripts-docs-dotfiles`, folder `skills/pkgfilter/`). Don't ask where the script is, and never
  delete on Logan's behalf: suggest, he runs it.
- Circuit boards, PCBs, KiCad, schematics, Gerbers/BOM/CPL, ordering from JLCPCB, or a folder holding a board
  project: load the `pcb-design` skill (`~/.claude/skills/pcb-design`; source repo `flyboy-byte/scripts-docs-dotfiles`,
  folder `skills/pcb-design/`). In a folder with no `STATE.md` yet, run its "Scaffold the project first" steps; in a
  scaffolded one, read `STATE.md` first. KiCad 10.0.7 is installed (`kicad-cli`, 2026-10-22). Owner answers for it:
  `~/.config/pcb-design/owner.md`.

## This file is published

A copy lives in the public repo `flyboy-byte/scripts-docs-dotfiles` at `dotfiles/claude-code/CLAUDE.md`
(`~/projects/scripts-docs-dotfiles`). After editing this file, run `dotfiles/claude-code/publish.sh` there: it
copies this file without the sections marked private and refuses if server or access details survive. Then commit
with a `claude-code: ...` message; push only when Logan says so. Anything about servers, hosts, logins or credentials
goes inside the private markers (HTML comments `private:start` / `private:end`, each alone on its line), and so does
any new section of that kind. Never copy this file there with `cp`, and keep secrets and tokens out of it altogether.


## How these repos are organized

Not every project has every file. When one exists, this is the role it plays — and the roles are
kept **separate on purpose**, so each can be read alone.

| File | Role |
| --- | --- |
| `CLAUDE.md` | Orientation, commands, architecture. Deliberately a **pointer**, not a copy — where deeper docs exist it says so and stops. |
| `AGENTS.md` | Authoritative design/safety/constraint doc, model-agnostic. Where it exists (`jesse-project`, `moomoo`, `afk-host`, `portfolio/agents.md`) it outranks `CLAUDE.md`. |
| `CONTEXT.md` | Durable orientation: what this is, what it explicitly does *not* control, direction of travel. |
| `PLAN.md` | Living state document — current reality, not a task list. Sometimes local/gitignored (`afk-host`). |
| `DECISIONS.md` | Numbered `D-00N` log of *why*, separated from `PLAN.md`'s narrative. |
| `WORKFLOW.md` | Operational runbook — environment split, deploy flow, kill switches. |
| `FRAMEWORK.md` | Phase-gated status tracker for exploratory/business packets (`makecom`, `moomoo/docs/expansions`). |
| `docs/` | The deep detail `CLAUDE.md` points at — `ARCHITECTURE.md`, `PROJECT_MAP.md`, evaluation criteria, graveyards, ledgers. |

`moomoo` is the fullest expression of this; `trans` and `afk-host` are good smaller examples.

**The precedence rule, stated in `moomoo/CLAUDE.md` and worth generalizing:** if `CLAUDE.md`
conflicts with the docs it points to, *the docs win* — update the pointer, don't paste the detail
back up into `CLAUDE.md`.

## Resuming without re-deriving

These repos are written so a cold session can pick up mid-thread. What that looks like in practice:

- **A status line at the top of the state doc, with an absolute date** — `Status: Deployed and live
  (2026-07-16)`, `Last updated 2026-08-07`, `Last verified: 2026-08-06`. Absolute dates throughout,
  never "recently" or "last week".
- **Explicit do-not-re-ask sections.** `trans/PLAN.md` has "Decisions already made with the user (do
  not re-ask)". `moomoo/CLAUDE.md` has "Where the real state lives (read these, not your memory of
  past sessions)". Treat both literally.
- **Completed work is struck through, not deleted** — `~~Option 1~~ — DONE (2026-07-12)` with a note
  on what shipped. History stays visible.
- **Explicit "not yet done" carve-outs**, including the unglamorous ones (`trans/PLAN.md` records
  that the live VPS still runs the pre-pivot build and names the file to delete on deploy).
- **Nothing is lost.** `moomoo/docs/strategy_graveyard.md` keeps every tested, abandoned, and parked
  idea with its data and reasoning — stated purpose: *"keeps sessions context-efficient by recording
  the 'why' behind every decision."* Dead ends are recorded so they aren't re-explored.
- Session IDs get pinned to disk for literal resumption (`afk-host/claude-resume.sh`, `RESUME.md`).
- **A paste-back at every compaction.** When context runs out — `/compact`, a summary turn, or
  anything that looks like the end of a long session — offer a resume block Logan can paste into a
  fresh session, without being asked. Keep it to one fenced block he can copy whole, and write it
  for a session that knows nothing: which doc to read first, what to verify rather than assume
  (`git status`, the live version, the test command), any sync step that has to happen before
  reading data, what shipped this session and where it is live, open threads, and an explicit
  **do-not-re-raise** list. Lead with whatever would waste the most time if rediscovered. The
  durable version of this belongs in the state doc; the paste-back is the short path back in.
- **A handoff file alongside the paste-back, only when the session was long and dense.** Context
  comes in tiers: memory (a few lines, every session), the state doc (durable), the paste-back
  (short path in), and a handoff file (`HANDOFF.md` next to the state doc), which is the halfway tier: more
  than memory, much less than the transcript. Write one when a cold session would otherwise re-derive
  a lot: a multi-hour thread, a run of attempts with results, tool quirks learned the hard way, a
  half-finished change. Skip it for short sessions or when the state doc already says everything;
  then the paste-back alone is enough. When it exists, the paste-back points at it and the project's
  `CLAUDE.md` reads it right after the state doc. Contents, in this order: verify-first commands with
  the expected output; the one thing in progress, with an attempt table (`change → result`) and the
  **last raw output** (the numbers or printout, not only my reading of it, which can be wrong); next
  steps in order; facts a cold session would re-derive; tool quirks; a do-not-re-raise list; open
  questions with the default in use. Turn repeated procedures into scripts in the repo rather than prose.
  **Replace** it at each handoff instead of appending, and move anything durable into the state doc or `docs/`.
  `wideband-work/work/HANDOFF.md` is the first one (2026-10-23).
- **Save the day at a pause point in long autonomous work** (context running low, a natural stop, Logan stepping away),
  without being asked:
  1. Commit the best state, with its measure in the message.
  2. Replace the handoff file and update the state doc.
  3. Write lessons, and propose the general ones for the skill that guided the work. Fold them into both the installed
     copy and the repo copy once agreed.
  4. Give the paste-back.

  On "keep going", work through reversible steps without stopping to report each one, record open questions with the
  default chosen in the state doc, and stop only before money, deletion, overwriting Logan's edits, or publishing.
  The full version of this loop, written for board work but general in shape, is
  `~/.claude/skills/pcb-design/WORKFLOW.md`.

## How iteration is structured

The planning approach here has a specific shape, and it's the part worth matching:

- **Attempt logs with outcomes.** `drag-tree/PLAN.md` tables A1–A6 as `attempt → fix → result`, then
  separates out the root causes that were actually resolved. Hypotheses in `moomoo` carry verdicts
  (`TESTED 2026-07-23, NULL` / `ACTIONABLE FINDING`) including the null results.
- **Pre-registration and the knob freeze.** `moomoo/docs/evaluation_criteria.md` fixes *in advance*
  what results would change the conclusion, "so outcomes can't be rationalized after the fact."
  Changing a gate later requires writing down why, with the date. Don't quietly retune past a gate.
- **Phase gates with real exit conditions.** From `makecom/FRAMEWORK.md`: "you don't move to the next
  phase by writing more docs, you move by doing the thing the gate actually requires." Writing more
  documentation is not progress through a gate.
- **Independent, pick-any-order options.** `moomoo/docs/expand_plan.md`: each option carries "enough
  detail to go straight to implementation without re-researching," and none block the others.
- **Claims are tagged by evidence strength** in research work — `playbat/docs/ledger.md` marks every
  claim `DOCUMENTED` / `REPORTED` / `INFERRED` / `UNKNOWN`. Don't launder inference into fact.
- **Cross-model audits are a deliberate step.** `codex.md`, `CODEX.md`, `moomoo/docs/codex-grand-audit-*`
  and `docs/deep/` hold ChatGPT/Codex/Claude outputs on the same question, kept as separate artifacts
  rather than merged. Findings from another model are input to verify, not fact.

## Scope fences

Several projects state a premise that a well-meaning addition would violate. These are constraints,
not gaps — check the project's own docs before adding anything in these directions.

- Local-first / no-account / no-cloud by design: `disc-tracker`, `focusfence`, `foss-radar`, `budget`,
  `drag-tree`. `foss-radar/CLAUDE.md`: "Don't add auth, multi-user concepts, or cloud persistence
  unless explicitly asked" (its `cloud/` dir is a separate codebase, not a mode of the app).
- `trans` — **no database, ever** (`D-001`). User audio lives only in expiring session storage.
- `moomoo` — paper only, `TRD_ENV=SIMULATE`. Never add or enable a live-order path.
- `jesse-project` — "Do not turn this into a large framework, dashboard, cloud platform, or overbuilt
  IoT system unless explicitly asked."

## Workspace map

| Project | What it is | Stack |
| --- | --- | --- |
| `afk-host` | Remote desktop host for AFK (afkdev.app); this fork adds Linux/Wayland | Flutter/Dart |
| `budget` | Self-hosted cash-position & runway dashboard | Python |
| `clanman` | World of Tanks clan (limy4) activity tracking — *not a software project* | notes/data |
| `disc-tracker` | Local-first disc golf bag tracker | Node + Python |
| `drag-tree` | NHRA Pro Tree reaction timer, offline Android app | Expo / React Native |
| `farmsync` | Multi-tenant agricultural IoT SaaS backend, MQTT worker | Python |
| `fdroiddata` | Fork of upstream F-Droid metadata repo | YAML metadata |
| `fdroidreview` | Checkouts of apps under F-Droid review | mixed |
| `focusfence` | On-device-VPN website blocker; no root/account/server | Android (Gradle) |
| `foss-radar` | Local-first FOSS discovery dashboard; Node process + SQLite | Node |
| `jesse-project` | Webhook→ESP32 unlock control system — read its `AGENTS.md` first | — |
| `makecom` | Phase-gated evaluation of a Make.com automation practice | docs |
| `mini-golf` | Mini golf scorer — golf.flyboybyte.com | Node |
| `moomoo` | Strategy research & paper-only trading platform | Python |
| `parentclaude` | Empty scratch dir | — |
| `playbat` | Research notebook on Android developer verification (Google 2026) | docs |
| `portfolio` | Personal portfolio site for Logan Night (`flyboy-byte`) | Node |
| `wideband-work` | rusEFI wideband O2 controller fork + 0-5 V analog out; AI-designed example of the pcb-design workflow — github.com/flyboy-byte/wideband-work | KiCad/Python/C++ |
| `trans` | WAtranscribe — WhatsApp voice transcription PWA — transcribe.flyboybyte.com | Python/Flask |

Starting a session in `~/projects` itself gives you the workspace root, not a codebase — `cd` into a
project so its docs and git repo are in scope.
