# readme

A Claude Code skill for writing or overhauling a repository README so a skimmer gets it in 30 seconds: what it is,
whether it works, what to do next. It covers structure, GitHub-flavored markdown (alerts, collapsibles, status
tables, badges), the GitHub About text and topics, and a check in a real browser of the README as GitHub renders it.

## Why the browser check

GitHub drops markdown it can't render without telling you: an alert with a typo becomes a plain quote, an image with a
wrong path disappears, a code block runs off the side on a phone. `scripts/verify_readme.js` opens the live repo page
in Playwright, counts alerts, collapsibles, tables and broken images, flags code blocks that scroll sideways, and
saves a full-page screenshot plus an above-the-fold crop to look at.

```bash
node scripts/verify_readme.js owner/repo [outdir]
```

It uses a Playwright install already on the machine (`PLAYWRIGHT_PATH`, or the first one `find` turns up) and falls back
to an installed Chrome or Chromium if Playwright's own browser was never downloaded.

## Install

```bash
cp -r skills/readme ~/.claude/skills/
```

Then ask: "make this README better", "clean up the README before I share this".

## Used on

This repo's [landing page](../../README.md).
