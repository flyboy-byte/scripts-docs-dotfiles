# Risks

> **Tier:** Mixed — scope/dependency/legal sections are high-level (decision-maker,
> plus a lawyer where relevant); technical/operational sections are low-level
> (implementer) · **Audience:** decision-maker for the whole doc, whoever
> builds/operates for the technical section · **Use when:** before committing to the
> approach (scope/legal section), before scaling or shipping (operational section), and
> as an ongoing check during build (technical section). Legal-research candidates are
> flagged in [`research-handoff.md`](./research-handoff.md).

## Scope / dependency risk

{{What could make this project's scope balloon, or what it depends on that's outside
this project's control (a third-party API, a vendored library, a platform's policies).}}

## Legal / licensing risk

{{Any real legal exposure — licensing terms on dependencies, distribution-channel
policies, data handling. Be explicit that reasoning here is not legal advice and needs
actual review before anything real is shipped, if that's relevant.}}

## Technical risk

{{What's likely to break, where complexity could run away, and what mitigates it.}}

## Operational risk

{{What ongoing commitments does this project imply once it's running (maintenance,
support, keeping a toolchain current), and what's realistic to sustain.}}
