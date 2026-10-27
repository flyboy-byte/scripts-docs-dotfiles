# {{Project Name}} — Plan Packet

**Start at [`FRAMEWORK.md`](./FRAMEWORK.md)** — it tracks what phase this project is
actually in and what has to happen next. This README is the doc index; `FRAMEWORK.md` is
the status tracker and the thing worth re-opening after time away.

{{One paragraph: what the project is, who/what it's for, in plain language.}}

## Contents

| Doc | Tier | Purpose |
| --- | --- | --- |
| [`FRAMEWORK.md`](./FRAMEWORK.md) | Meta | Phase-gated status tracker — where this project actually is and what's next |
| [`docs/documentation-guide.md`](./docs/documentation-guide.md) | Meta | Explains the tiers below, who each doc is for, and how they fit together |
| [`docs/overview.md`](./docs/overview.md) | High-level | What it is, who/what it's for, why it exists, what it's explicitly not |
| [`docs/approach.md`](./docs/approach.md) | High-level | Is this worth doing this way — alternatives considered, tradeoffs |
| [`docs/infrastructure.md`](./docs/infrastructure.md) | Low-level | What you actually need to stand this up — tools, stack, constraints |
| [`docs/risks.md`](./docs/risks.md) | Mixed | Scope, dependency, legal, technical, and operational risks with mitigations |
| [`docs/notes.md`](./docs/notes.md) | High-level | Open questions, sequencing calls, naming — working scratchpad |
| [`docs/research-handoff.md`](./docs/research-handoff.md) | Meta | Workflow for offloading unverified claims to Claude/ChatGPT deep research |
| [`research/`](./research/) | — | Intake folder for raw output from those research sessions |

## How to use this packet

Start with [`docs/documentation-guide.md`](./docs/documentation-guide.md) — it explains
the high-level/low-level split and which docs are for deciding vs. building. Short version:

1. Read `docs/overview.md` first for the framing.
2. Read `docs/approach.md` and `docs/risks.md` together — they're the go/no-go inputs.
3. `docs/infrastructure.md` is what it costs (in setup effort) to actually build.
4. `docs/notes.md` is the working scratchpad of decisions still open.
5. When a doc flags a claim as unverified, check `docs/research-handoff.md` — it's likely
   already queued for a Claude/ChatGPT deep-research pass, with a ready-to-use prompt.

Everything here is reasoning from the source material plus general priors — it has not
been validated against a real run, device, or user yet unless a doc says otherwise. Treat
conclusions as hypotheses to test, not facts.
