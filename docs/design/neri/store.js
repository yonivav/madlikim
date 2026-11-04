const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
(async () => {
  const [dir, out] = process.argv.slice(2);
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1800, height: 1000 }, deviceScaleFactor: 3 });
  await p.goto('file://' + path.join(dir, 'screens.html'));
  await p.waitForTimeout(600);
  const phones = await p.$$('.phone');
  const shots = [];
  for (const i of [0, 1, 2, 3, 4]) {
    await phones[i].evaluate(e => { e.style.borderRadius = '0'; });
    shots.push((await phones[i].screenshot()).toString('base64'));
  }
  const neriJs = fs.readFileSync(path.join(dir, 'neri.js'), 'utf8');
  const fonts = 'file://' + path.resolve(dir, '..', 'fonts') + '/';
  const frames = [
    ['תזכורת עדינה', 'להדליק נרות', {mood:'wink', lit:true, arms:'wave'}],
    ['בדיוק מה עושים', 'בכל ערב', {mood:'happy', arms:'point'}],
    ['הדלקתם?', 'נרי חוגג!', {mood:'excited', lit:true, arms:'up'}],
    ['כל לילה', 'חבר חדש מתעורר', {mood:'happy', lit:true, arms:'up', color:'pink'}],
    ['ובשבת?', 'נרי נח', {mood:'sleep'}],
  ];
  const q = await b.newPage({ viewport: { width: 1290, height: 2796 } });
  for (let i = 0; i < frames.length; i++) {
    const [l1, l2, pose] = frames[i];
    await q.setContent(`<html dir="ltr"><head><meta charset="utf-8"><style>
      @font-face { font-family: Fredoka; src: url(${fonts}Fredoka.ttf); font-weight: 300 700; }
      html { overflow:hidden; } body { margin:0; width:1290px; height:2796px; overflow:hidden; position:relative; direction: rtl;
        background: radial-gradient(70% 45% at 50% 55%, #4A63E0 0%, #2638A8 45%, #141C66 100%); }
      .ring { position:absolute; left:50%; top:56%; border-radius:50%; border:5px solid rgba(255,255,255,.10); transform:translate(-50%,-50%); }
      h1 { font-family: Fredoka; font-weight: 700; text-align:center; margin:0; line-height:1.05; direction: rtl; }
      .l1 { font-size: 150px; color:#FFF6E6; margin-top: 210px; }
      .l2 { font-size: 168px; color:#FF8A3C; text-shadow: 0 9px 0 #8A2E0A; }
      .ph { position:absolute; left: 120px; top: 760px; width: 860px; height: 1862px; border-radius: 110px;
        border: 26px solid #11142E; overflow:hidden; transform: rotate(-5deg); box-shadow: 0 60px 140px rgba(0,0,0,.5); }
      .ph img { width:100%; height:100%; object-fit:cover; object-position: top; display:block; }
      .neri { position:absolute; left: 700px; bottom: 120px; width: 620px; height: 930px; }
      .mini { position:absolute; width:150px; height:225px; opacity:.9 }
    </style><script>${neriJs}</script></head><body>
      ${[600,900,1200,1500,1800,2100].map(r => `<div class="ring" style="width:${r}px;height:${r}px"></div>`).join('')}
      <h1 class="l1">${l1}</h1><h1 class="l2">${l2}</h1>
      <div class="ph"><img src="data:image/png;base64,${shots[i]}"></div>
      <div class="mini" style="left:1080px;top:820px;transform:rotate(14deg)" id="m1"></div>
      <div class="mini" style="left:40px;top:2520px;transform:rotate(-12deg)" id="m2"></div>
      <div class="neri" id="big"></div>
      <script>
        document.getElementById('big').innerHTML = neri(${JSON.stringify(pose)});
        document.getElementById('m1').innerHTML = neri({color:'yellow', mood:'happy', lit:true});
        document.getElementById('m2').innerHTML = neri({color:'mint', mood:'wink', lit:true});
      </script>
    </body></html>`);
    await q.waitForTimeout(400);
    await q.screenshot({ path: path.join(out, `ios-6.9-${i + 1}.png`) });
  }
  await b.close();
})();
