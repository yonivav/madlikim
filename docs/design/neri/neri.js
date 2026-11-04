// Neri (נרי), the candle buddy. Glossy, chubby, big shiny eyes.
// Design box 200 x 280. The Flutter painter mirrors these numbers.
const NERI_COLORS = {
  // [highlight, base, shade]
  neri:   ['#FFFFFF', '#E9F0FF', '#9DB4EC'],  // white wax, blue stripes
  blue:   ['#CFE2FF', '#7FB0FF', '#3F74E6'],
  yellow: ['#FFF3C2', '#FFD95C', '#E8A92A'],
  pink:   ['#FFE0EA', '#FFA8C2', '#E8668F'],
  mint:   ['#DDFBEF', '#86E3C2', '#2FB58A'],
  orange: ['#FFE3CC', '#FFB17A', '#EE7B3A'],
  purple: ['#ECE3FF', '#BBA2FF', '#7C5BE6'],
  red:    ['#FFDADA', '#FF9090', '#E05252'],
  teal:   ['#D6F7FA', '#7FDCE6', '#2AA9BA'],
};
const NIGHT_COLORS = ['blue', 'yellow', 'pink', 'mint', 'orange', 'purple', 'red', 'teal'];
let _uid = 0;

/**
 * mood: 'calm' | 'happy' | 'excited' | 'sleep' | 'wink' | 'proud'
 * arms: 'down' | 'wave' | 'up' | 'point'
 */
function neri({ color = 'neri', mood = 'happy', lit = false, arms = 'down', glow = 1, sleepyZ = false } = {}) {
  const id = 'n' + (_uid++);
  const [hi, base, shade] = NERI_COLORS[color];
  const stripe = color === 'neri' ? '#4A7DF0' : '#FFFFFF';
  const stripeOpacity = color === 'neri' ? .9 : .35;
  const ink = '#1E2340';
  const P = [];
  P.push(`<defs>
    <radialGradient id="${id}b" cx=".35" cy=".3" r=".9"><stop offset="0" stop-color="${hi}"/><stop offset=".55" stop-color="${base}"/><stop offset="1" stop-color="${shade}"/></radialGradient>
    <radialGradient id="${id}l" cx=".35" cy=".3" r=".9"><stop offset="0" stop-color="${hi}"/><stop offset="1" stop-color="${shade}"/></radialGradient>
    <linearGradient id="${id}f" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#FFF7D1"/><stop offset=".42" stop-color="#FFC63A"/><stop offset="1" stop-color="#FF6A1F"/></linearGradient>
    <radialGradient id="${id}g"><stop offset="0" stop-color="#FFC63A" stop-opacity=".6"/><stop offset=".5" stop-color="#FFC63A" stop-opacity=".16"/><stop offset="1" stop-color="#FFC63A" stop-opacity="0"/></radialGradient>
    <radialGradient id="${id}e" cx=".5" cy=".75" r=".7"><stop offset="0" stop-color="#4C8DFF"/><stop offset=".55" stop-color="#22306E"/><stop offset="1" stop-color="${ink}"/></radialGradient>
    <clipPath id="${id}c"><path d="M52 112 Q 52 82 100 82 Q 148 82 148 112 L 148 214 Q 148 236 126 236 L 74 236 Q 52 236 52 214 Z"/></clipPath>
  </defs>`);
  if (lit) P.push(`<circle cx="100" cy="48" r="${78 * glow}" fill="url(#${id}g)"/>`);
  // legs + feet
  P.push(`<rect x="72" y="228" width="16" height="26" rx="8" fill="url(#${id}l)"/><rect x="112" y="228" width="16" height="26" rx="8" fill="url(#${id}l)"/>
          <ellipse cx="78" cy="257" rx="17" ry="10" fill="url(#${id}l)" stroke="${shade}" stroke-width="2.5"/><ellipse cx="122" cy="257" rx="17" ry="10" fill="url(#${id}l)" stroke="${shade}" stroke-width="2.5"/>
          <ellipse cx="73" cy="253" rx="6" ry="3" fill="#fff" opacity=".6"/><ellipse cx="117" cy="253" rx="6" ry="3" fill="#fff" opacity=".6"/>`);
  // arms
  const arm = (s) => {
    const x0 = 100 + s * 46, y0 = 170;
    let end;
    if (arms === 'up') end = [x0 + s * 22, y0 - 52];
    else if (arms === 'wave' && s > 0) end = [x0 + s * 26, y0 - 44];
    else if (arms === 'point' && s < 0) end = [x0 + s * 34, y0 - 14];
    else end = [x0 + s * 14, y0 + 30];
    const c = [x0 + s * 20, (y0 + end[1]) / 2 + (end[1] < y0 ? 6 : -4)];
    return `<path d="M${x0} ${y0} Q ${c[0]} ${c[1]} ${end[0]} ${end[1]}" stroke="${shade}" stroke-width="16" stroke-linecap="round" fill="none"/>
            <path d="M${x0} ${y0} Q ${c[0]} ${c[1]} ${end[0]} ${end[1]}" stroke="${base}" stroke-width="10" stroke-linecap="round" fill="none"/>
            <circle cx="${end[0]}" cy="${end[1]}" r="10" fill="url(#${id}l)" stroke="${shade}" stroke-width="2.5"/><circle cx="${end[0] - 3}" cy="${end[1] - 3}" r="3" fill="#fff" opacity=".7"/>`;
  };
  P.push(arm(-1), arm(1));
  // body
  const body = 'M52 112 Q 52 82 100 82 Q 148 82 148 112 L 148 214 Q 148 236 126 236 L 74 236 Q 52 236 52 214 Z';
  P.push(`<path d="${body}" fill="url(#${id}b)" stroke="${shade}" stroke-width="3"/>`);
  // spiral stripes (classic Hanukkah candle)
  P.push(`<g clip-path="url(#${id}c)" opacity="${stripeOpacity}">${[0, 1, 2].map(i =>
    `<path d="M30 ${206 + i * 22} Q 100 ${186 + i * 22} 170 ${178 + i * 22} L170 ${187 + i * 22} Q 100 ${195 + i * 22} 30 ${215 + i * 22} Z" fill="${stripe}"/>`).join('')}</g>`);
  // melted top rim
  P.push(`<path d="M56 108 Q 60 84 100 84 Q 140 84 144 108 Q 138 116 132 108 Q 126 122 118 108 Q 110 116 104 106 Q 96 122 88 108 Q 80 116 74 107 Q 64 120 56 108 Z" fill="#fff" opacity=".85"/>`);
  // gloss: big soft highlight + rim
  P.push(`<path d="M62 120 Q 62 100 80 96 Q 70 112 70 140 L 70 200 Q 64 196 62 186 Z" fill="#fff" opacity=".55"/>
          <ellipse cx="72" cy="104" rx="6" ry="4" fill="#fff" opacity=".9"/>
          <path d="M142 130 L 142 210 Q 142 226 128 230" stroke="#fff" stroke-width="3" opacity=".35" fill="none" stroke-linecap="round"/>`);
  // wick + flame
  P.push(`<path d="M100 84 Q 97 74 101 64" stroke="${ink}" stroke-width="4.5" stroke-linecap="round" fill="none"/>`);
  if (lit) P.push(`<path d="M101 70 C 70 52, 78 22, 101 -8 C 124 22, 132 52, 101 70 Z" fill="url(#${id}f)"/>
                   <path d="M101 66 C 90 58, 92 44, 101 32 C 110 44, 112 58, 101 66 Z" fill="#FFF7D1" opacity=".9"/>
                   <ellipse cx="92" cy="20" rx="4" ry="8" fill="#fff" opacity=".5" transform="rotate(-20 92 20)"/>`);
  // face
  const ey = 148, lx = 80, rx = 120;
  const eye = (x, big) => {
    const w = big ? 13 : 11, h = big ? 16 : 14;
    return `<ellipse cx="${x}" cy="${ey}" rx="${w}" ry="${h}" fill="url(#${id}e)"/>
            <circle cx="${x + 4}" cy="${ey - 6}" r="${big ? 5 : 4.2}" fill="#fff"/>
            <circle cx="${x - 4}" cy="${ey + 6}" r="2" fill="#fff" opacity=".8"/>`;
  };
  const arc = (x, up) => `<path d="M${x - 9} ${ey + (up ? 4 : -2)} Q ${x} ${ey + (up ? -8 : 8)} ${x + 9} ${ey + (up ? 4 : -2)}" stroke="${ink}" stroke-width="4.5" stroke-linecap="round" fill="none"/>`;
  if (mood === 'sleep') P.push(arc(lx, false), arc(rx, false));
  else if (mood === 'happy' || mood === 'proud') P.push(eye(lx, false), eye(rx, false));
  else if (mood === 'wink') P.push(eye(lx, false), arc(rx, true));
  else if (mood === 'excited') P.push(eye(lx, true), eye(rx, true));
  else P.push(eye(lx, false), eye(rx, false));
  // brows
  if (mood !== 'sleep') {
    const lift = mood === 'excited' ? -6 : 0;
    P.push(`<path d="M${lx - 9} ${ey - 22 + lift} Q ${lx} ${ey - 28 + lift} ${lx + 8} ${ey - 23 + lift}" stroke="${ink}" stroke-width="3.5" stroke-linecap="round" fill="none"/>
            <path d="M${rx - 8} ${ey - 23 + lift} Q ${rx} ${ey - 28 + lift} ${rx + 9} ${ey - 22 + lift}" stroke="${ink}" stroke-width="3.5" stroke-linecap="round" fill="none"/>`);
  }
  // cheeks
  P.push(`<ellipse cx="64" cy="${ey + 20}" rx="11" ry="7" fill="#FF7FA3" opacity=".5"/><ellipse cx="136" cy="${ey + 20}" rx="11" ry="7" fill="#FF7FA3" opacity=".5"/>`);
  // mouth
  const my = ey + 22;
  if (mood === 'sleep') {
    P.push(`<ellipse cx="100" cy="${my + 2}" rx="5" ry="4" fill="${ink}"/>`);
  } else if (mood === 'calm') {
    P.push(`<path d="M90 ${my} Q 100 ${my + 9} 110 ${my}" stroke="${ink}" stroke-width="4" stroke-linecap="round" fill="none"/>`);
  } else {
    const w = mood === 'excited' ? 15 : 12, d = mood === 'excited' ? 18 : 14;
    P.push(`<path d="M${100 - w} ${my - 2} Q 100 ${my + 2} ${100 + w} ${my - 2} Q ${100 + w - 2} ${my + d} 100 ${my + d} Q ${100 - w + 2} ${my + d} ${100 - w} ${my - 2} Z" fill="${ink}"/>
            <path d="M${100 - w + 5} ${my + d - 5} Q 100 ${my + d - 12} ${100 + w - 5} ${my + d - 5} Q ${100 + w - 8} ${my + d} 100 ${my + d} Q ${100 - w + 8} ${my + d} ${100 - w + 5} ${my + d - 5} Z" fill="#FF8FAE"/>`);
  }
  if (sleepyZ) P.push(`<text x="150" y="70" font-family="Fredoka" font-weight="700" font-size="26" fill="${ink}" opacity=".55">z</text>
                       <text x="166" y="46" font-family="Fredoka" font-weight="700" font-size="18" fill="${ink}" opacity=".4">z</text>`);
  return `<svg viewBox="0 -20 200 300" width="100%" height="100%" style="overflow:visible">${P.join('')}</svg>`;
}
