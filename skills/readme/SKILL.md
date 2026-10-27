---
name: readme
description: Write or overhaul a repository README that converts a skimmer in 30 seconds — structure, GitHub-flavored markdown features (alerts, collapsibles, status tables), and a browser-based verification loop that catches silent render failures. TRIGGER when the user asks to write, improve, clean up, restructure, or "make better" a README or repo landing page, says a README is "sloppy"/"dumb"/"a wall of text", asks for badges/screenshots/diagrams in a README, or asks to make a repo look presentable before sharing it. SKIP for non-README docs (ARCHITECTURE.md, PLAN.md, API reference, changelogs) — those want completeness, not conversion.
---

# README

A README has about 30 seconds to tell a skimmer what this is, whether it works, and what to do
next. Optimize for scanning, not reading. Everything below serves that.

## 1. Audit before writing

Never start typing a README cold. Three cheap lookups first:

```sh
gh repo list <owner> --limit 40 --json name,description,stargazerCount,primaryLanguage
gh api repos/<owner>/<repo>/readme --jq '.content' | base64 -d      # per sibling repo
gh repo view <owner>/<repo> --json description,repositoryTopics
```

- **Read the current README fully.** You are looking for true-but-stale claims, not just prose
  quality. "Verified working", "not yet tested", version numbers, and dates rot silently.
- **Read 3–5 sibling repos by the same author.** People have a house style — centered hero blocks,
  badge rows, ASCII diagrams, emoji status tables. Match it. A README that looks unrelated to the
  author's other work reads as generic.
- **Check the repo's own metadata.** The About blurb and topics sit above the README and are
  usually staler than it. Fix them in the same pass (`gh repo edit --description --add-topic`).

Then ask the repo, not the user: what does this actually do, and what's genuinely verified versus
merely compiling? That distinction drives the most valuable section you will write.

## 2. Skeleton

Order matters more than content. Each block earns the next scroll.

| # | Block | Job |
|---|---|---|
| 1 | Hero — banner, H1, one-line tagline, badges, nav links | Identify in 3 seconds |
| 2 | Framing note (optional) | Set expectations: fork? toy? production? |
| 3 | The short version | One paragraph, the actual mechanism |
| 4 | **Proof** — screenshot, GIF, or photo of it working | Believe it in 1 second |
| 5 | **Status table** | Trust — what works vs. what doesn't |
| 6 | Quickstart | Try it *now*, ideally without buying anything |
| 7 | How it works — a diagram | Understand the shape |
| 8 | Install / build / use, with `<details>` for depth | Actually do it |
| 9 | Downloads / releases | Get the artifact |
| 10 | Repo layout, license | Orient a contributor |

Rules that hold across all of them:

- **One H1**, H2 for majors, H3 for subs, never skip levels — screen readers and GitHub's TOC use it.
- **Tables scan; bullet lists don't.** Any time you write three bullets with the same shape, it's a table.
- **Hero image at 70–80% width**, not 100%. A full-width banner eats the entire first screen and
  pushes the status table below the fold.
- **`---` between major sections.** Cheap, and it gives the eye a rest point.
- **Deep material goes in `<details>` or `docs/`.** The README is a landing page, not the manual.

## 3. The status table

This is the highest-value block in most READMEs and almost nobody writes it. Any project older
than a weekend has features in different states, and burying that in prose caveats ("though only
the original board has actually been tested") destroys trust when someone hits it.

```markdown
| | Feature | Notes |
|---|---|---|
| ✅ | **Boots on real hardware** | RP2040, 16 MB PSRAM. Shell in under a minute. |
| ✅ | **GPIO from Linux → real pins** | Both chardev and sysfs. Verified lighting an actual LED. |
| 🚧 | **RP2350 boards** | Builds clean for all four targets. Never actually flashed. |
| 🚧 | **VGA + PS/2 console** | Real upstream code — just not wired up and tested here. |
| ❌ | **I²C / SPI / PWM** | Documented as an idea. Deliberately not built. |
```

- ✅ verified, 🚧 partial or untested, ❌ not built.
- **"Compiles" is not "works."** Say which one you mean. This is the whole point of the table.
- Put a header like *"What's actually verified, versus what merely compiles"* above it — it signals
  the honesty rather than making the reader infer it.

Honest limitations read as confidence. Vague optimism reads as a project that will waste your
afternoon.

## 4. GFM features worth using

Full syntax: https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax

**Alerts** — colored callouts, five types. Use them for things that cost the reader time:

```markdown
> [!NOTE]      background worth knowing
> [!TIP]       a shortcut
> [!IMPORTANT] needed to succeed
> [!WARNING]   will bite you
> [!CAUTION]   risk of damage or waste
```

Budget roughly 3–6 per README. More than that and they stop being signal.

**Collapsibles** — for depth that a skimmer shouldn't have to scroll past:

```markdown
<details>
<summary><b>Wiring — two chips on a shared SPI bus</b></summary>

<br>

...tables, code, prose...

</details>
```

The blank line and `<br>` after `<summary>` matter; without them markdown inside may not parse.

**Badges** — 4–6, curated. Prefer ones that state facts (`board | RP2040`, `guest | Linux 6.6`)
over decorative ones. Badge soup is worse than no badges.

## 5. Verified gotchas

These are confirmed by browser testing, not folklore. They fail *silently* — the page renders,
just wrong.

> [!WARNING]
> **Alerts do not render inside `<details>`.** A `> [!WARNING]` nested in an HTML block degrades to
> a plain blockquote with no color, no icon. If something is important enough to be an alert, it is
> too important to be collapsed — hoist it out.

> [!WARNING]
> **Mermaid renders in a lazy cross-origin iframe.** GitHub does not inline it. Until that iframe
> loads it is a blank box that can run 800px+ tall, and it never loads at all in some contexts. The
> syntax being valid does not mean it will appear. For anything under ~20 nodes, a hand-drawn ASCII
> diagram in a plain fenced block renders instantly, always, and suits systems/hardware projects
> better. Reserve mermaid for genuinely complex graphs where ASCII would be unreadable.

Also:

- **Code blocks wrap at ~90 characters** at GitHub's default content width. Longer lines force
  horizontal scrolling, which on mobile hides the end of your install command. Shorten flags, use
  short forms, split with comments.
- **Quickstarts are usually not runnable as written.** The clone step is missing, or a flag is
  redundant, or a filename changed. Run it end to end in a temp dir before shipping it.
- **Strip EXIF before committing photos.** Phone pictures carry GPS. `magick in.jpg -auto-orient
  -resize 1600x1600 -strip -quality 85 out.jpg` also drops a 2 MB photo to ~300 KB.
- **Prefer status over dates.** "Verified on hardware" ages well; "verified 2026-08-29" is stale in
  a month and makes the whole README look abandoned. Dates belong in a changelog or plan doc.

## 6. When the README has no images

Missing visuals are the most common reason a README reads as dead, and the block most often
skipped because "there's no screenshot." Usually one can be made:

- **Anything with a web UI** — run it locally or hit its deployed URL, and screenshot it with the
  same Playwright used below. A real screenshot of the actual app beats any amount of prose.
  Capture at `deviceScaleFactor: 2` and crop to the interesting region, not the whole browser.
- **CLI tools** — a terminal transcript in a fenced block. Real output, copy-pasted from a real
  run, not invented.
- **Libraries** — the smallest genuinely useful code example, above the install instructions.
- **Hardware / physical projects** — you cannot manufacture this. Ask the user for a photo; it is
  worth asking for. Strip EXIF before committing (§5).

Never fabricate a screenshot, mock a UI that doesn't look like that, or describe a demo GIF that
doesn't exist. An honestly image-less README beats a misleading one.

## 7. Verify in a real browser

Do not push and hope. Markdown that looks right in an editor fails in ways only the rendered page
shows. `scripts/verify_readme.js` in this skill does the check:

```sh
node ~/.claude/skills/readme/scripts/verify_readme.js <owner>/<repo> [outdir]
```

It reports alert count and types, collapsible count, table count, code blocks that overflow
horizontally, images that failed to load, and writes a full-page screenshot plus an above-the-fold
crop.

It needs Playwright. Find an existing install rather than adding a dependency:

```sh
find ~ -maxdepth 6 -type d -name playwright -path '*node_modules*' 2>/dev/null | head -3
ls ~/.cache/ms-playwright     # browsers
```

If Playwright's own browser was never downloaded, the script falls back to an installed
Chrome or Chromium in `/usr/bin`.

**Then actually look at the screenshot.** The counts catch silent failures; only your eyes catch a
banner eating the fold, a diagram misaligning, or a section landing in the wrong order. Crop the
tall screenshot into readable chunks and read them:

```sh
magick full.png -crop 1900x1500+80+7200 +repage section.png
```

Iterate: fix → push → re-verify. Two or three rounds is normal.

## 8. Anti-patterns

- **Writing copy instead of structure.** If asked to improve a README, the fix is almost always
  layout, hierarchy, and honesty — not wittier sentences. Don't reach for jokes.
- **Claiming verification you don't have.** Never write "tested" for something you only saw compile.
  Ask, or mark it 🚧.
- **Inventing content to fill the skeleton.** No demo GIF? Skip the block. An empty section signals
  neglect louder than an absent one.
- **Badge soup and emoji confetti.** Emoji as consistent structural markers (status columns) work;
  emoji sprayed on every heading read as noise.
- **Leaving the About blurb and topics stale** while polishing the README below them.
- **Burying the thing that makes the project interesting.** Lead with the surprising part.
