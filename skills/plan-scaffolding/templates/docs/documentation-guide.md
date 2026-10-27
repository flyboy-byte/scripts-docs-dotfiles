# Documentation Guide

> **Tier:** Meta (about the docs themselves) · **Audience:** anyone new to this packet,
> including future-you after time away · **Use when:** you don't know which doc to open,
> or you're adding a new doc and need to decide where it fits.

This packet has two altitudes. Knowing which altitude you're reading (or writing) at
prevents the two failure modes that hit project-planning docs specifically: framing
material that's all vision and no way to actually build the thing, and build docs that
bury the "is this worth doing this way" question under implementation detail.

## The two tiers

### High-level — the decision layer

**Question it answers:** *Should this exist, and is this the right way to build it?*
**Written for:** the person deciding whether/how to pursue this.
**Properties:** short enough to read in one sitting, states conclusions and open
questions plainly, doesn't require deep technical literacy to follow.

| Doc | What it's for |
| --- | --- |
| [`overview.md`](./overview.md) | What it is, who/what it's for, why it exists |
| [`approach.md`](./approach.md) | Is this worth doing this way — alternatives, tradeoffs, validation plan |
| [`notes.md`](./notes.md) | Live scratchpad of open decisions |
| [`risks.md`](./risks.md) *(scope/legal sections)* | What could derail this and why |

### Low-level — the build layer

**Question it answers:** *Given we're doing this, how does it actually get built and run?*
**Written for:** whoever is implementing. Assumes the high-level case has already been
read — doesn't re-argue the framing.
**Properties:** specific enough to act on directly.

| Doc | What it's for |
| --- | --- |
| [`infrastructure.md`](./infrastructure.md) | What tools/stack/constraints to actually work within |
| [`risks.md`](./risks.md) *(technical/operational sections)* | What breaks in practice and how it's guarded against |

{{If there's a standalone source document (an existing plan doc, research file, PDF)
this packet was built from, add a row here linking to it — but only after confirming
where it actually lives relative to this directory. If it lives outside this directory
and wasn't copied in, either copy it in or state its real path in prose instead of a
relative link that will 404.}}

## How the tiers relate

{{One or two sentences on what came first — the source material, or the scoping work —
and how to read the packet depending on whether the reader already believes in the
approach (read bottom-up, build-first) or is still deciding (read top-down,
overview-first).}}

## Who this packet is actually for, concretely

{{State plainly who has actually read this so far. Note explicitly if none of it has
been pressure-tested against reality yet — that's what Phase 2 (Validation) in
`FRAMEWORK.md` and `research-handoff.md` are for.}}

## Adding a new doc

Before writing: decide which tier it belongs to (does it answer "should we" or "how do
we"), add it to the table above, and give it the same header block used in the existing
docs (`Tier / Audience / Use when`, one line each, at the top of the file). If a section
depends on facts nobody in this project actually knows yet, don't invent numbers — flag
it as a research-handoff candidate instead.
