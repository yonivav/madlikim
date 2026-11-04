// Neri characters. Design box 200 x 300 (y from -20). The Flutter painter
// mirrors these numbers (lib/ui/widgets/neri.dart).
const NERI_COLORS = {
  // [highlight, base, shade]
  apricot: ['#FFF1E2', '#FFBE85', '#EE8746'],
  neri:    ['#FFFFFF', '#E9F0FF', '#9DB4EC'],
  blue:    ['#CFE2FF', '#7FB0FF', '#3F74E6'],
  yellow:  ['#FFF3C2', '#FFD95C', '#E8A92A'],
  pink:    ['#FFE0EA', '#FFA8C2', '#E8668F'],
  mint:    ['#DDFBEF', '#86E3C2', '#2FB58A'],
  orange:  ['#FFE3CC', '#FFB17A', '#EE7B3A'],
  purple:  ['#ECE3FF', '#BBA2FF', '#7C5BE6'],
  red:     ['#FFDADA', '#FF9090', '#E05252'],
  teal:    ['#D6F7FA', '#7FDCE6', '#2AA9BA'],
};
const NIGHT_COLORS = ['blue', 'yellow', 'pink', 'mint', 'orange', 'purple', 'red', 'teal'];

// L, R: body sides. T: shoulder line (top). ex: eye offset. es: eye scale.
// legs: leg offset from center. round: how domed the top is.
const BUILDS = {
  classic: { L: 52, R: 148, T: 82, ex: 20, es: 1, legs: 20, round: 30 },
  slim:    { L: 64, R: 136, T: 64, ex: 17, es: .92, legs: 15, round: 26 },
  chubby:  { L: 42, R: 158, T: 100, ex: 23, es: 1.06, legs: 25, round: 38 },
};

const CHARACTERS = [
  { id: 'neri',   name: 'נרי',   palette: 'apricot', build: 'classic', pattern: 'none',    line: 'הקלאסי. חם ופשוט' },
  { id: 'tchelet',name: 'תכלת',  palette: 'neri',    build: 'classic', pattern: 'stripes', line: 'כחול־לבן, כמו בחנוכייה של סבתא' },
  { id: 'pazit',  name: 'פזית',  palette: 'yellow',  build: 'chubby',  pattern: 'stars',   line: 'עגלגלה ונוצצת' },
  { id: 'shoshi', name: 'שושי',  palette: 'pink',    build: 'slim',    pattern: 'dots',    line: 'גבוהה, דקה ומנוקדת' },
  { id: 'menti',  name: 'מנטי',  palette: 'mint',    build: 'chubby',  pattern: 'stripes', line: 'רגוע וקריר' },
  { id: 'sigali', name: 'סגלי',  palette: 'purple',  build: 'slim',    pattern: 'stars',   line: 'חולמני, אוהב כוכבים' },
];
let _uid = 0;

/**
 * look: { palette, build, pattern } or a character object.
 * mood: 'calm' | 'happy' | 'excited' | 'sleep' | 'wink'; arms: 'down' | 'wave' | 'up' | 'point'
 */
function neri({ look = CHARACTERS[0], color, mood = 'happy', lit = false, arms = 'down', glow = 1, sleepyZ = false } = {}) {
  if (color) look = { palette: color, build: 'classic', pattern: color === 'neri' ? 'stripes' : 'stripes' };
  const id = 'n' + (_uid++);
  const [hi, base, shade] = NERI_COLORS[look.palette];
  const b = BUILDS[look.build];
  const { L, R, T } = b, B = 236, cx = 100, hw = (R - L) / 2;
  const ink = '#1E2340';
  const P = [];
  const body = `M${L} ${T + b.round} Q ${L} ${T} ${cx} ${T} Q ${R} ${T} ${R} ${T + b.round} L ${R} ${B - 22} Q ${R} ${B} ${R - 22} ${B} L ${L + 22} ${B} Q ${L} ${B} ${L} ${B - 22} Z`;
  P.push(`<defs>
    <radialGradient id="${id}b" cx=".35" cy=".3" r=".9"><stop offset="0" stop-color="${hi}"/><stop offset=".55" stop-color="${base}"/><stop offset="1" stop-color="${shade}"/></radialGradient>
    <radialGradient id="${id}l" cx=".35" cy=".3" r=".9"><stop offset="0" stop-color="${hi}"/><stop offset="1" stop-color="${shade}"/></radialGradient>
    <linearGradient id="${id}f" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#FFF7D1"/><stop offset=".42" stop-color="#FFC63A"/><stop offset="1" stop-color="#FF6A1F"/></linearGradient>
    <radialGradient id="${id}g"><stop offset="0" stop-color="#FFC63A" stop-opacity=".6"/><stop offset=".5" stop-color="#FFC63A" stop-opacity=".16"/><stop offset="1" stop-color="#FFC63A" stop-opacity="0"/></radialGradient>
    <radialGradient id="${id}e" cx=".5" cy=".75" r=".7"><stop offset="0" stop-color="#4C8DFF"/><stop offset=".55" stop-color="#22306E"/><stop offset="1" stop-color="${ink}"/></radialGradient>
    <clipPath id="${id}c"><path d="${body}"/></clipPath>
  </defs>`);
  if (lit) P.push(`<circle cx="${cx}" cy="${T - 34}" r="${78 * glow}" fill="url(#${id}g)"/>`);
  // legs + feet
  for (const s of [-1, 1]) {
    const x = cx + s * b.legs;
    P.push(`<rect x="${x - 8}" y="${B - 8}" width="16" height="26" rx="8" fill="url(#${id}l)"/>
      <ellipse cx="${x - 2 * -s}" cy="257" rx="17" ry="10" fill="url(#${id}l)" stroke="${shade}" stroke-width="2.5"/>
      <ellipse cx="${x - 2 * -s - 5}" cy="253" rx="6" ry="3" fill="#fff" opacity=".6"/>`);
  }
  // arms
  const arm = (s) => {
    const x0 = cx + s * (hw - 2), y0 = T + 88;
    let end;
    if (arms === 'up') end = [x0 + s * 22, y0 - 52];
    else if (arms === 'wave' && s > 0) end = [x0 + s * 26, y0 - 44];
    else if (arms === 'point' && s < 0) end = [x0 + s * 34, y0 - 14];
    else end = [x0 + s * 14, y0 + 30];
    const c = [x0 + s * 20, (y0 + end[1]) / 2 + (end[1] < y0 ? 6 : -4)];
    const d = `M${x0} ${y0} Q ${c[0]} ${c[1]} ${end[0]} ${end[1]}`;
    return `<path d="${d}" stroke="${shade}" stroke-width="16" stroke-linecap="round" fill="none"/>
            <path d="${d}" stroke="${base}" stroke-width="10" stroke-linecap="round" fill="none"/>
            <circle cx="${end[0]}" cy="${end[1]}" r="10" fill="url(#${id}l)" stroke="${shade}" stroke-width="2.5"/>
            <circle cx="${end[0] - 3}" cy="${end[1] - 3}" r="3" fill="#fff" opacity=".7"/>`;
  };
  P.push(arm(-1), arm(1));
  P.push(`<path d="${body}" fill="url(#${id}b)"/>`);
  // pattern
  const ey = T + 66;
  const light = look.palette === 'neri';
  const pale = look.palette === 'yellow';
  const patColor = light ? '#4A7DF0' : pale ? shade : '#FFFFFF';
  const patOp = light ? .9 : pale ? .75 : .42;
  let pat = '';
  if (look.pattern === 'stripes') {
    pat = [0, 1, 2].map(i => `<path d="M${L - 22} ${B - 30 + i * 22} Q ${cx} ${B - 50 + i * 22} ${R + 22} ${B - 58 + i * 22} L ${R + 22} ${B - 49 + i * 22} Q ${cx} ${B - 41 + i * 22} ${L - 22} ${B - 21 + i * 22} Z" fill="${patColor}"/>`).join('');
  } else if (look.pattern === 'dots') {
    for (let row = 0, y = ey + 44; y < B - 4; y += 17, row++)
      for (let x = L + 10 + (row % 2) * 10; x < R - 4; x += 20) pat += `<circle cx="${x}" cy="${y}" r="4.5" fill="${patColor}"/>`;
  } else if (look.pattern === 'stars') {
    const star = (x, y, r) => `<path d="M${x} ${y - r} Q ${x + r * .22} ${y - r * .22} ${x + r} ${y} Q ${x + r * .22} ${y + r * .22} ${x} ${y + r} Q ${x - r * .22} ${y + r * .22} ${x - r} ${y} Q ${x - r * .22} ${y - r * .22} ${x} ${y - r} Z" fill="${patColor}"/>`;
    pat = [[L + 16, ey + 50, 8], [cx + 6, ey + 66, 10], [R - 16, ey + 46, 7], [L + 26, B - 16, 6], [R - 22, B - 20, 9], [L + 14, T + 40, 5], [R - 12, T + 34, 6]]
      .map(([x, y, r]) => star(x, y, r)).join('');
  }
  if (pat) P.push(`<g clip-path="url(#${id}c)" opacity="${patOp}">${pat}</g>`);
  P.push(`<path d="${body}" fill="none" stroke="${shade}" stroke-width="3"/>`);
  // melted rim with drips
  let rim = `M${L + 4} ${T + 26} Q ${L + 8} ${T + 2} ${cx} ${T + 2} Q ${R - 8} ${T + 2} ${R - 4} ${T + 26}`;
  const n = 6;
  for (let i = 1; i <= n; i++) {
    const x1 = R - 4 - (R - L - 8) * i / n, xm = x1 + (R - L - 8) / n / 2;
    rim += ` Q ${xm} ${T + (i % 2 ? 40 : 34)} ${x1} ${T + 26 - (i % 2 ? 0 : 2)}`;
  }
  P.push(`<path d="${rim} Z" fill="#fff" opacity=".8"/>`);
  // gloss
  P.push(`<path d="M${L + 10} ${T + 38} Q ${L + 10} ${T + 18} ${L + 28} ${T + 14} Q ${L + 18} ${T + 30} ${L + 18} ${T + 58} L ${L + 18} ${B - 36} Q ${L + 12} ${B - 40} ${L + 10} ${B - 50} Z" fill="#fff" opacity=".5"/>
          <ellipse cx="${L + 20}" cy="${T + 22}" rx="6" ry="4" fill="#fff" opacity=".9"/>
          <path d="M${R - 6} ${T + 48} L ${R - 6} ${B - 26} Q ${R - 6} ${B - 10} ${R - 20} ${B - 6}" stroke="#fff" stroke-width="3" opacity=".35" fill="none" stroke-linecap="round"/>`);
  // wick + flame
  P.push(`<path d="M${cx} ${T + 2} Q ${cx - 3} ${T - 8} ${cx + 1} ${T - 18}" stroke="${ink}" stroke-width="4.5" stroke-linecap="round" fill="none"/>`);
  if (lit) {
    const f = T - 12;
    P.push(`<path d="M${cx + 1} ${f} C ${cx - 30} ${f - 18}, ${cx - 22} ${f - 48}, ${cx + 1} ${f - 78} C ${cx + 24} ${f - 48}, ${cx + 32} ${f - 18}, ${cx + 1} ${f} Z" fill="url(#${id}f)"/>
      <path d="M${cx + 1} ${f - 4} C ${cx - 10} ${f - 12}, ${cx - 8} ${f - 26}, ${cx + 1} ${f - 38} C ${cx + 10} ${f - 26}, ${cx + 12} ${f - 12}, ${cx + 1} ${f - 4} Z" fill="#FFF7D1" opacity=".9"/>
      <ellipse cx="${cx - 8}" cy="${f - 50}" rx="4" ry="8" fill="#fff" opacity=".5" transform="rotate(-20 ${cx - 8} ${f - 50})"/>`);
  }
  // face
  const lx = cx - b.ex, rx = cx + b.ex, k = b.es;
  const eye = (x, big) => {
    const w = (big ? 13 : 11) * k, h = (big ? 16 : 14) * k;
    return `<ellipse cx="${x}" cy="${ey}" rx="${w}" ry="${h}" fill="url(#${id}e)"/>
            <circle cx="${x + 4 * k}" cy="${ey - 6 * k}" r="${(big ? 5 : 4.2) * k}" fill="#fff"/>
            <circle cx="${x - 4 * k}" cy="${ey + 6 * k}" r="${2 * k}" fill="#fff" opacity=".8"/>`;
  };
  const arc = (x, up) => `<path d="M${x - 9} ${ey + (up ? 4 : -2)} Q ${x} ${ey + (up ? -8 : 8)} ${x + 9} ${ey + (up ? 4 : -2)}" stroke="${ink}" stroke-width="4.5" stroke-linecap="round" fill="none"/>`;
  if (mood === 'sleep') P.push(arc(lx, false), arc(rx, false));
  else if (mood === 'wink') P.push(eye(lx, false), arc(rx, true));
  else P.push(eye(lx, mood === 'excited'), eye(rx, mood === 'excited'));
  if (mood !== 'sleep') {
    const lift = mood === 'excited' ? -6 : 0;
    P.push(`<path d="M${lx - 9} ${ey - 22 * k + lift} Q ${lx} ${ey - 28 * k + lift} ${lx + 8} ${ey - 23 * k + lift}" stroke="${ink}" stroke-width="3.5" stroke-linecap="round" fill="none"/>
            <path d="M${rx - 8} ${ey - 23 * k + lift} Q ${rx} ${ey - 28 * k + lift} ${rx + 9} ${ey - 22 * k + lift}" stroke="${ink}" stroke-width="3.5" stroke-linecap="round" fill="none"/>`);
  }
  P.push(`<ellipse cx="${cx - hw + 12}" cy="${ey + 20}" rx="11" ry="7" fill="#FF6F96" opacity=".5"/><ellipse cx="${cx + hw - 12}" cy="${ey + 20}" rx="11" ry="7" fill="#FF6F96" opacity=".5"/>`);
  const my = ey + 22;
  if (mood === 'sleep') P.push(`<ellipse cx="${cx}" cy="${my + 2}" rx="5" ry="4" fill="${ink}"/>`);
  else if (mood === 'calm') P.push(`<path d="M${cx - 10} ${my} Q ${cx} ${my + 9} ${cx + 10} ${my}" stroke="${ink}" stroke-width="4" stroke-linecap="round" fill="none"/>`);
  else {
    const w = mood === 'excited' ? 15 : 12, d = mood === 'excited' ? 18 : 14;
    P.push(`<path d="M${cx - w} ${my - 2} Q ${cx} ${my + 2} ${cx + w} ${my - 2} Q ${cx + w - 2} ${my + d} ${cx} ${my + d} Q ${cx - w + 2} ${my + d} ${cx - w} ${my - 2} Z" fill="${ink}"/>
            <path d="M${cx - w + 5} ${my + d - 5} Q ${cx} ${my + d - 12} ${cx + w - 5} ${my + d - 5} Q ${cx + w - 8} ${my + d} ${cx} ${my + d} Q ${cx - w + 8} ${my + d} ${cx - w + 5} ${my + d - 5} Z" fill="#FF8FAE"/>`);
  }
  if (sleepyZ) P.push(`<text x="${R + 2}" y="${T - 12}" font-family="Fredoka" font-weight="700" font-size="26" fill="${ink}" opacity=".55">z</text>
                       <text x="${R + 18}" y="${T - 36}" font-family="Fredoka" font-weight="700" font-size="18" fill="${ink}" opacity=".4">z</text>`);
  return `<svg viewBox="0 -20 200 300" width="100%" height="100%" style="overflow:visible">${P.join('')}</svg>`;
}
