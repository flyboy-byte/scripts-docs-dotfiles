# Framework — {{Project Name}}

> **Tier:** Meta (self-aware — this doc describes and tracks the project it's part of)
> **Audience:** you · **Use when:** you don't know what to do next, or you're checking
> in on progress after time away.

## What this is

{{One or two sentences: where this came from — an idea, an existing codebase, a plan
doc already in progress — and what this file does: turns it into a staged process with
honest status, not a plan written once and followed blindly. Each phase has a concrete
exit condition satisfied by doing something (a test, a real run, a decision made), not
by writing more docs.}}

Update the checkboxes below as things actually happen. This file is the honest answer to
"where are we" at any point in the future.

## Phase model

```
Phase 0        Phase 1        Phase 2         Phase 3      Phase 4       Phase 5
Capture   ──►   Scoping  ──►   Validation ──►  Build   ──►  Verify  ──►  Formalize
```

### Phase 0 — Capture

The source material exists and has been captured somewhere durable.

- [ ] Source material captured (existing docs, code, or a written-down version of the idea)
- [ ] Read/understood well enough to extract the real open questions it implies

**Gate to Phase 1:** none — automatic once the source material exists.

### Phase 1 — Scoping

Turn the raw material into a decision-ready packet: what it is, what it's explicitly
not, what it would cost to build, what could go wrong.

- [ ] `docs/overview.md` — what it is and why
- [ ] `docs/approach.md` — is this worth doing this way, what alternatives were considered
- [ ] `docs/risks.md` — scope/dependency/legal + technical/operational risk map
- [ ] `docs/infrastructure.md` — what building it actually requires
- [ ] `docs/notes.md` — open decisions log
- [ ] `docs/documentation-guide.md` + `docs/research-handoff.md` — the packet knows how
      to be read and how to close its own gaps

**Gate to Phase 2:** none blocking — this is a documentation exercise. What's *not* done
is anything that required leaving this directory.

### Phase 2 — Validation

The bottleneck for almost every project at this stage. Everything in Phase 1 is
reasoning from source material plus priors — none of it has touched reality yet.

- [ ] Run the `docs/research-handoff.md` queue through Claude/ChatGPT deep research and
      merge findings back into the docs that consume them
- [ ] Test the riskiest assumption directly (a real device, a real user, a real
      dependency) rather than reasoning about it further
- [ ] Decide, based on the above, whether the core approach still holds

**Gate to Phase 3:** at least one real signal (a working test, a real run, a confirmed
constraint) that the approach holds — or a clear signal it doesn't, in which case
revisit `docs/overview.md`/`docs/approach.md` before building further.

### Phase 3 — Build

Stand up the smallest real version, per `docs/infrastructure.md`.

- [ ] {{Core infrastructure/tools/scaffold in place}}
- [ ] {{Smallest end-to-end version built}}
- [ ] {{Tested against realistic and adversarial inputs, if applicable}}

**Gate to Phase 4:** one working version that does the core thing end-to-end.

### Phase 4 — Verify

- [ ] {{Verified in the real environment it's meant for — device, production-like
      setting, real usage — not just unit-level correctness}}
- [ ] {{Any remaining known gaps documented plainly, not silently skipped}}

**Gate to Phase 5:** confident enough in Phase 3's build to call it done for now.

### Phase 5 — Formalize

- [ ] {{Decide what changed after contact with reality vs. the original plan}}
- [ ] {{Identify what to invest in next, if anything}}
- [ ] {{Distribution/release/handoff steps, if applicable}}

## Current status (update this line as phases advance)

**{{YYYY-MM-DD}}: {{state current phase and the single highest-leverage next action.}}**

When an item above is done, tick it and add the date it happened (`- [x] ... (YYYY-MM-DD)`).
