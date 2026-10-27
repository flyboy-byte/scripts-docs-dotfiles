# Infrastructure

> **Tier:** Low-level (build detail) · **Audience:** whoever is actually building this ·
> **Use when:** setting up tools and scaffolding before building the first real
> version. Assumes the reader has already read
> [`overview.md`](./overview.md) and doesn't need the framing re-explained.

What's actually needed to build and run the smallest real version of this project.

## Core tools / platforms

{{List the specific tools, SDKs, accounts, or services required, and why each is needed.
Note any pinned versions or toolchain constraints already established elsewhere.}}

## Data / storage

{{Anything needed for state, caching, or persistence, and where it lives.}}

## Hard constraints (do not violate)

{{Constraints already established for this project — architectural rules, things
explicitly out of scope, licensing/vendoring rules that can't be casually changed.}}

## Security-relevant infrastructure

{{Secrets management, auth, environment isolation — anything where getting it wrong is
costly.}}

## Testing infrastructure

{{How will this be tested before it's considered done, including anything that can't be
verified in this environment (e.g. a native module needing a real device) — name that
gap explicitly rather than pretending it's covered.}}

## What's notably absent (gaps to fill)

{{Anything the source material or reasoning so far hasn't addressed. Naming the gaps
explicitly is more useful than pretending the plan is complete.}}
