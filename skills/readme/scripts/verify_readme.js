#!/usr/bin/env node
/*
 * Verify a rendered GitHub README in a real browser.
 *
 *   node verify_readme.js <owner>/<repo> [outdir]
 *   node verify_readme.js https://github.com/owner/repo
 *
 * Catches the failures that markdown editors cannot: alerts silently degraded to
 * blockquotes, mermaid stuck in its lazy iframe, code blocks overflowing, broken
 * images, and a hero that eats the entire first screen.
 *
 * Needs Playwright. It is usually already installed somewhere; this finds it
 * rather than adding a dependency. Override with PLAYWRIGHT_PATH=/path/to/playwright
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function loadPlaywright() {
  const tries = [];
  if (process.env.PLAYWRIGHT_PATH) tries.push(process.env.PLAYWRIGHT_PATH);
  tries.push('playwright');
  try {
    const found = execSync(
      `find "$HOME" -maxdepth 6 -type d -name playwright -path '*node_modules*' 2>/dev/null | head -5`,
      { encoding: 'utf8', shell: '/bin/sh' }
    ).trim().split('\n').filter(Boolean);
    tries.push(...found);
  } catch { /* find failed; fall through */ }

  for (const t of tries) {
    try { return require(t); } catch { /* try next */ }
  }
  console.error(
    'Could not load Playwright.\n' +
    'Point at an existing install:  PLAYWRIGHT_PATH=/path/to/node_modules/playwright node ' +
    path.basename(__filename) + ' owner/repo'
  );
  process.exit(2);
}

const arg = process.argv[2];
if (!arg) {
  console.error('usage: verify_readme.js <owner>/<repo> [outdir]');
  process.exit(2);
}
const url = arg.startsWith('http') ? arg : `https://github.com/${arg}`;
const outdir = process.argv[3] || process.cwd();
fs.mkdirSync(outdir, { recursive: true });

(async () => {
  const { chromium } = loadPlaywright();
  // Playwright's own browser may never have been downloaded; fall back to an installed Chrome/Chromium.
  let browser;
  try {
    browser = await chromium.launch();
  } catch (e) {
    const sys = ['/usr/bin/google-chrome-stable', '/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser']
      .find(p => fs.existsSync(p));
    if (!sys) throw e;
    browser = await chromium.launch({ executablePath: sys });
  }
  const page = await browser.newPage({
    viewport: { width: 1280, height: 1400 },
    deviceScaleFactor: 2,
  });

  const consoleErrors = [];
  page.on('console', m => { if (m.type() === 'error') consoleErrors.push(m.text().slice(0, 160)); });

  await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 });
  await page.waitForTimeout(3000);

  const body = page.locator('article.markdown-body').first();
  if (!(await body.count())) {
    console.error(`No rendered README found at ${url}`);
    await browser.close();
    process.exit(1);
  }

  const report = await page.evaluate(() => {
    const root = document.querySelector('article.markdown-body');
    const q = s => [...root.querySelectorAll(s)];

    const overflow = q('pre')
      .map((e, i) => ({ i, over: e.scrollWidth - e.clientWidth, text: (e.innerText || '').slice(0, 45) }))
      .filter(x => x.over > 2);

    const brokenImages = q('img')
      .filter(i => i.complete && i.naturalWidth === 0)
      .map(i => i.getAttribute('src'));

    const wideImages = q('img')
      .map(i => ({ src: (i.getAttribute('src') || '').split('/').pop(), h: Math.round(i.getBoundingClientRect().height) }))
      .filter(x => x.h > 600);

    // mermaid blocks that never escaped their loading iframe
    const pendingMermaid = [...document.querySelectorAll(
      '.js-render-needs-enrichment, .render-needs-enrichment'
    )].filter(e => /mermaid|flowchart|graph |sequenceDiagram/i.test(e.textContent || '')).length;

    return {
      alerts: q('.markdown-alert').length,
      alertTypes: q('.markdown-alert-title').map(e => e.innerText.trim()),
      alertsInsideDetails: q('details .markdown-alert').length,
      details: q('details').length,
      detailSummaries: q('details > summary').map(e => e.innerText.trim().slice(0, 55)),
      tables: q('table').length,
      headings: { h1: q('h1').length, h2: q('h2').length, h3: q('h3').length },
      // GitHub proxies images through camo.githubusercontent.com and rewrites src,
      // but preserves the original in data-canonical-src.
      badges: q('img').filter(i => {
        const s = i.getAttribute('data-canonical-src') || i.getAttribute('src') || '';
        return /shields\.io|badge|badgen|forthebadge/i.test(s);
      }).length,
      codeBlocks: q('pre').length,
      overflow,
      brokenImages,
      wideImages,
      pendingMermaid,
      words: (root.innerText || '').split(/\s+/).filter(Boolean).length,
    };
  });

  const full = path.join(outdir, 'readme_full.png');
  await page.screenshot({ path: full, fullPage: true });
  await body.scrollIntoViewIfNeeded();
  await page.waitForTimeout(400);
  const fold = path.join(outdir, 'readme_fold.png');
  await page.screenshot({ path: fold });

  const problems = [];
  if (report.headings.h1 !== 1) problems.push(`${report.headings.h1} H1 headings (want exactly 1)`);
  if (report.alertsInsideDetails > 0)
    problems.push(`${report.alertsInsideDetails} alert(s) nested in <details> — these render as plain blockquotes, hoist them out`);
  if (report.pendingMermaid > 0)
    problems.push(`${report.pendingMermaid} mermaid block(s) still loading — leaves a tall blank box; consider ASCII`);
  for (const o of report.overflow)
    problems.push(`code block #${o.i} overflows by ${o.over}px ("${o.text.replace(/\n/g, ' ')}…") — shorten lines`);
  for (const b of report.brokenImages) problems.push(`broken image: ${b}`);
  for (const w of report.wideImages)
    problems.push(`image ${w.src} renders ${w.h}px tall — may push content below the fold`);
  if (report.alerts === 0) problems.push('no GitHub alerts — consider callouts for gotchas');
  if (report.tables === 0) problems.push('no tables — repeated bullet lists usually scan better as tables');

  const line = '─'.repeat(64);
  console.log(`\n${line}\n  ${url}\n${line}`);
  console.log(`  alerts        ${report.alerts}  ${report.alertTypes.join(', ')}`);
  console.log(`  collapsibles  ${report.details}`);
  report.detailSummaries.forEach(s => console.log(`                  · ${s}`));
  console.log(`  tables        ${report.tables}`);
  console.log(`  code blocks   ${report.codeBlocks}`);
  console.log(`  badges        ${report.badges}`);
  console.log(`  headings      h1:${report.headings.h1} h2:${report.headings.h2} h3:${report.headings.h3}`);
  console.log(`  word count    ${report.words}`);
  if (consoleErrors.length) console.log(`  page errors   ${consoleErrors.length}`);

  console.log(`\n  screenshots\n    ${full}\n    ${fold}`);

  if (problems.length) {
    console.log(`\n  ${problems.length} issue(s):`);
    problems.forEach(p => console.log(`    ✗ ${p}`));
  } else {
    console.log('\n  ✓ no structural issues found');
  }
  console.log(`\n  Now LOOK at the screenshots — counts miss layout and ordering problems.`);
  console.log(`  Crop tall pages:  magick readme_full.png -crop 1900x1500+80+<Y> +repage part.png\n`);

  await browser.close();
  process.exit(problems.length ? 1 : 0);
})();
