// Render JS/SPA pages with the installed Chrome and dump their text.
// Setup:  npm init -y && PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm i playwright-core
// Usage:  node fetch.mjs "https://site/page1" "https://site/page2" ...
import { chromium } from 'playwright-core';

const urls = process.argv.slice(2);
if (urls.length === 0) {
  console.error('usage: node fetch.mjs <url> [url...]');
  process.exit(1);
}

const browser = await chromium.launch({ channel: 'chrome', headless: true });
const page = await browser.newContext().then(c => c.newPage());

for (const url of urls) {
  console.log('\n===================================================================');
  console.log('URL:', url);
  console.log('===================================================================');
  try {
    await page.goto(url, { waitUntil: 'networkidle', timeout: 45000 });
  } catch (e) {
    console.log('[goto warn]', e.message);
  }
  await page.waitForTimeout(3000);               // let the SPA render
  const text = await page.evaluate(() => document.body ? document.body.innerText : '(no body)');
  console.log(text);
}

await browser.close();
