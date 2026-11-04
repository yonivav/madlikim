const { chromium } = require('playwright'); const path = require('path');
(async () => { const [dir, out] = process.argv.slice(2);
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1200, height: 1200 } });
  await p.goto('file://' + path.join(dir, 'icon.html')); await p.waitForTimeout(400);
  for (const id of ['full','fg','splash','splash12','mono']) {
    await (await p.$('#' + id)).screenshot({ path: path.join(out, id + '.png'), omitBackground: id !== 'full' }); }
  await b.close(); })();
