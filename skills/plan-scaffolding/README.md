# plan-scaffolding

A Claude Code skill that turns a spark, a half-built project or a loose plan doc into a phase-gated status packet:
a `FRAMEWORK.md` tracker that says honestly where the project is, plus a small set of docs sorted by who reads them.
It keeps to what is known: no invented revenue, customers or market sizes.

## What you get

```
FRAMEWORK.md               phase tracker, the entry point: Capture → Scoping → Validation → Build → Verify → Formalize
README.md                  index of the packet
docs/
  overview.md              what it is, why, and what it is not
  approach.md              is this worth doing this way; alternatives considered
  infrastructure.md        what building it actually takes
  risks.md                 scope, dependency and licensing risks, then technical ones
  notes.md                 open decisions, a scratchpad you edit by hand
  research-handoff.md      claims to check with a deep-research tool, with ready prompts
  documentation-guide.md   which doc to read for which question
research/                  where raw deep-research output lands
```

Each phase has a gate that is passed by doing something outside the documents (a test, a real run, a decision), not
by writing more. Applied mid-project, the tracker starts with the work that is already true ticked off, with dates.
For a small task the skill offers just `FRAMEWORK.md` and `docs/overview.md` instead.

## Install

```bash
cp -r skills/plan-scaffolding ~/.claude/skills/
```

Then ask: "plan this out", "scaffold this project", "turn this plan doc into phases".

## Used on

[disc-tracker](https://github.com/flyboy-byte/disc-tracker/tree/main/app/plan): the Android port of a Flask site,
scaffolded after the build had started.
