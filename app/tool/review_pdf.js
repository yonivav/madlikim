// Turns docs/review/*.html into PDFs (needs Node + Playwright with Chromium).
//   node app/tool/review_pdf.js
const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const dir = path.resolve(__dirname, '..', '..', 'docs', 'review');
  const browser = await chromium.launch();
  const page = await browser.newPage();
  for (const name of ['rabbi', 'musician']) {
    await page.goto('file://' + path.join(dir, name + '.html'));
    await page.waitForTimeout(400);
    await page.pdf({ path: path.join(dir, name + '.pdf'), format: 'A4', printBackground: true, preferCSSPageSize: true });
    console.log('wrote', name + '.pdf');
  }
  await browser.close();
})();
