---
name: plan-scaffolding
description: Turn a spark, an in-progress project, or an unstructured plan doc into a phase-gated status packet (FRAMEWORK.md tracker plus a tiered docs set). Use for app ports, internal tools, research projects, feature builds or FOSS side projects when the user wants a project planned or vetted: "plan this out", "scaffold this project", "set up a framework/tracker for this", "turn this plan doc into phases", "where is this project at".
---

# Plan Scaffolding

Turns a spark, an in-progress project, or an unstructured plan doc into a phase-gated
status packet: a self-aware phase tracker plus a small tiered doc set. It fits an app
port, an internal tool, a research project, a feature build, a FOSS side project.

## What this produces

In the current working directory (or a new directory the user names):

```
FRAMEWORK.md              # self-aware phase tracker — the actual entry point
README.md                 # doc index
docs/
  documentation-guide.md   # tier map: high-level / low-level / meta, who reads what
  overview.md              # high-level: what it is, why it exists, scope
  approach.md               # high-level: is this worth doing this way — tradeoffs, alternatives considered
  infrastructure.md         # low-level: what building it actually requires
  risks.md                  # mixed: scope/dependency/legal (high) + technical/operational (low)
  notes.md                  # high-level: open decisions, working scratchpad
  research-handoff.md       # meta: queue of claims to send to Claude/ChatGPT deep research
research/
  README.md                 # intake folder for raw deep-research output
```

Templates live in `templates/` next to this file — copy them in and fill placeholders,
don't regenerate structure from scratch each time.

## Money is not the default frame

Don't invent revenue, customers or market sizes for a project that has none; most of
what this skill is used on was never meant to be sold. If the project does have a real
commercial angle, keep it to what is actually known: put pricing or market questions in
`docs/research-handoff.md` and the decision itself in `docs/notes.md`, rather than
stretching the docs into a business plan.

## Process

1. **Establish the source material.** If the user handed you a file/PDF/note/existing
   plan doc, read it in full before writing anything. If it's a verbal spark with
   nothing written down, ask what the thing actually is, who/what it's for (a person,
   just the user, "nobody yet"), and what already exists (notes, a prototype, code).
   Don't skip this — every downstream doc is only as good as this grounding.

   If a standalone source document exists (e.g. an existing `PORT_PLAN.md`), decide
   before writing any links to it where it actually lives relative to the target
   directory — link to its real relative path, or copy it in. Don't emit a relative
   markdown link assuming a location the file doesn't have.

2. **Copy the templates** from `templates/` into the target directory, preserving the
   structure above. Use `templates/docs/*.md` verbatim as a starting skeleton — they
   already contain the tier header block (`Tier / Audience / Use when`) and section
   scaffolding; you're filling them in, not redesigning them, unless the project
   genuinely doesn't fit the shape (see "When to deviate" below).

3. **Fill in FRAMEWORK.md first.** Name the project in one line, then work through the
   phase model (Capture → Scoping → Validation → Build → Verify → Formalize) and mark
   honestly which phases are actually done. If real build work already happened before
   this packet existed (common — this skill often gets applied mid-project, not at the
   spark), reflect that: it's fine for Phase 3 (Build) to already be partially checked
   off on day one, as long as it's actually true, not aspirational.

4. **Fill `docs/overview.md` and `docs/approach.md`** from the source material plus
   reasoning:
   - State what's inferred vs. what's actually known, explicitly, inline. Don't let
     invented details read as facts.
   - Be honest about scope: what this explicitly is *not* trying to be is as useful as
     what it is.
   - Don't pad with generic advice ("iterate fast," "get feedback early") unless it's a
     specific, actionable next step tied to this project.
   - Write full sentences and short paragraphs, not compressed bullet fragments. A
     thinned-out packet defeats the purpose — the value is in the reasoning being
     spelled out, not in the file existing.

5. **Fill `docs/infrastructure.md` and `docs/risks.md`** — infrastructure is concrete
   build requirements (accounts, tools, stack, hard constraints already established
   elsewhere in the repo); risks span scope/dependency/legal (needs judgment, sometimes
   a human outside this session) and technical/operational (engineering judgment).
   Flag anywhere a real legal or licensing question exists (e.g. a vendored GPL
   dependency, a distribution channel's terms) rather than guessing.

6. **Populate `docs/research-handoff.md`'s queue** with specific unverified claims that
   came up while writing the docs above — anything externally verifiable this session
   shouldn't fabricate (platform policy specifics, a library's actual current behavior,
   licensing terms, distribution-channel requirements). Suggest Claude or ChatGPT deep
   research per question type. Keep this separate from questions needing *primary*
   research (testing on a real device, asking a real person) — those go in
   `FRAMEWORK.md`'s Validation phase as an action item instead.

7. **Write `docs/notes.md`** as a living scratchpad of what's still undecided — naming,
   sequencing calls, open technical questions. Expected to get stale and be edited
   directly by the user later; don't over-polish it.

8. **Fill `docs/documentation-guide.md`** last, once the actual doc set is known, so the
   tier table and "how the tiers relate" section describe what was actually built.

9. **Make it findable.** If the packet sits inside a repo whose `CLAUDE.md`, `AGENTS.md` or
   `README.md` a later session will read first, add one line there pointing at
   `FRAMEWORK.md`, so a cold session lands on the tracker instead of re-deriving it. A
   pointer, not a copy of the status.

10. **Tell the user directly** (don't just leave it in the files) what phase the project
   is in and what the single next unblocking action is. That's the point of the whole
   packet — don't bury the lede under a pile of new files.

## When to deviate from the template shape

If the project is small enough that a full packet is overkill (a small script, an
afternoon task), say so and offer a lighter version — just `FRAMEWORK.md` and
`docs/overview.md` — rather than generating five docs of padding around a small thing.

## Design notes (why it's shaped this way)

- **FRAMEWORK.md as phase-gated tracker, not a plan written once.** Docs alone create
  the illusion of progress. Gates require *doing* something outside the documents (a
  test, a device run, a real decision) to advance.
- **Tiering (high-level / low-level / meta)** keeps a single-page "what's this and
  where are we" view separate from build-detail, so re-reading the whole packet isn't
  required to find the one page relevant to the decision in front of you.
- **research-handoff.md exists because a coding agent shouldn't be the source of truth
  for externally verifiable claims** — those need live research with citations, not
  fabrication inline.
