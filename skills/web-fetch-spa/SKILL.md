---
name: web-fetch-spa
description: Render JS/SPA or seemingly-blocked web pages with Playwright when WebFetch/curl returns only a page shell (nav/footer, empty app div, "Loading…") or the page looks login-gated. Use BEFORE concluding a page is unreadable, protected, or 401 — most "blocked" doc/portal pages are just client-side-rendered and read fine in a headless browser. Also for JS-gated content, infinite scroll, cookie walls, or anything needing a real browser (DOM eval, screenshots, wait-for-selector).
---

# web-fetch-spa — read SPA / "unreadable" pages with Playwright

## When to reach for this
A normal fetch (`WebFetch`, `curl`, `wget`) returns **only a shell** — nav bar, footer,
`Loading…`, an empty `<div id="app">`, or clearly-not-the-real content. That's almost always a
**client-side-rendered SPA** (React/Vue/Next) that builds its DOM with JavaScript *after* load, so a
static fetch never sees the body.

> **Do NOT conclude "login-gated" / "401" / "access denied" from a missing body.** A blank body
> usually just means the JS hasn't run. Render with Playwright first, *then* judge whether it's truly
> protected. (Confirmed real-world: SHEIN's `open.sheincorp.com/documents/*` pages return only a shell
> to WebFetch but read completely in a headless browser.)

Also use for: JS-gated content, lazy/infinite-scroll lists, cookie/consent walls, content behind a
click/tab, screenshots, or any "a real browser could read it" case.

## Setup (once per machine — no browser download)
Use **`playwright-core`** driving the **already-installed Chrome** (`channel: 'chrome'`), which skips
the large `playwright install` download. Work in a scratchpad dir, not the repo.

```bash
cd <scratchpad>
npm init -y
PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm i playwright-core
```

## Run
`fetch.mjs` (bundled next to this file) dumps rendered text; pass one or more URLs:

```bash
node fetch.mjs "https://site/spa/page1" "https://site/spa/page2"
```

Copy it into the scratchpad (or run from the skill dir). It launches one browser and loops all URLs
(much faster than relaunching per page). Two companion patterns:

- **Grab text of a page** → `fetch.mjs` prints `document.body.innerText`.
- **Discover the sitemap / find the right doc IDs** → a variant that dumps every `<a href>` matching a
  pattern (see `links.mjs` snippet in Tips) — invaluable when a doc portal's real page IDs aren't
  guessable and the left-nav holds the map.

## Tips
- **Pass multiple URLs at once** — one launch, loops through them.
- `waitUntil: 'networkidle'` + a **3 s** pad handles most SPAs. For stubborn pages wait for a real
  selector: `await page.waitForSelector('table')`.
- **Big pages get truncated by `head`.** Slice with `sed -n '1443,1640p'`, or `grep -n` for a section
  header first (e.g. `"Return Parameter"`, `"Response Body"`) to find the line range, then `sed` it.
- Use `page.content()` (outerHTML) when you need attributes/links; `page.evaluate(...)` to pull just
  `<a href>`s and build a link map; `page.screenshot({ path })` for a visual.
- Headless is fine for reading. If a site blocks headless, try `headless: false` or set a real UA.
- These are **throwaway scripts** — keep them in the scratchpad, never commit to a repo.
- If `channel: 'chrome'` fails (no system Chrome), fall back to `npx playwright install chromium`
  once, then `chromium.launch({ headless: true })` with the `playwright` package.

## Link-map variant (find the right page IDs)
```js
const links = await page.evaluate(() =>
  [...new Set([...document.querySelectorAll('a[href]')]
    .map(a => (a.textContent||'').trim() + '  ::  ' + a.getAttribute('href'))
    .filter(s => s.includes('/documents/')))));   // adjust the filter to the site
console.log(links.join('\n'));
```
