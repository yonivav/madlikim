// "Passing the flame": the lighting show after "הדלקתי".
// A pure timeline: showFrame(t, n, meTipFrac) -> what to draw at time t.
// lib/ui/widgets/lighting_show.dart mirrors these numbers 1:1.
//
// Stage is 360 x 560. Actors are anchored at their feet (x, y) with a width w
// (a Neri is w wide and 1.5w tall). The hanukkiah box (360 x 200) sits at y=MT.

const SHOW = {
  W: 360, H: 560, MT: 300,
  FEET: 0.957 * 1.5,          // feet below the top of a Neri, in widths
  WICK: (0.957 - 0.28) * 1.5, // a classic buddy's wick above its feet, in widths
  BUDDY_W: 42, CIRCLE_W: 56, ME_W: 110, ME_VISIT_W: 80,
  ARRIVE: 1.0, GATHER: 1.0, IGNITE: 2.3, PASS: 2.65,
};

function slotX(i) { return 180 + (i - 4) * 36; }
function posX(p) { return p <= 3 ? slotX(8 - p) : slotX(7 - p); }
const lerp = (a, b, u) => a + (b - a) * u;
const clamp01 = (u) => Math.max(0, Math.min(1, u));
const easeInOut = (u) => u < .5 ? 2 * u * u : 1 - Math.pow(-2 * u + 2, 2) / 2;
const easeOutBack = (u) => { const c = 1.7; return 1 + (c + 1) * Math.pow(u - 1, 3) + c * Math.pow(u - 1, 2); };
const prog = (t, start, dur) => clamp01((t - start) / dur);

function showTiming(n) {
  const dt = n <= 4 ? 0.46 : 0.38;
  const passEnd = SHOW.PASS + n * dt;
  const back = passEnd + 0.35;
  const finale = back + 0.9;
  return { dt, passEnd, back, finale, end: finale + 0.9 };
}

// Home spots (feet) in stage coordinates.
function buddyHome(p) { return { x: posX(p), y: SHOW.MT + 88 + SHOW.FEET * SHOW.BUDDY_W, w: SHOW.BUDDY_W }; }
function meHome() { return { x: 180, y: SHOW.MT + 52 + SHOW.FEET * SHOW.BUDDY_W, w: SHOW.BUDDY_W }; }
function meCenter() { return { x: 180, y: 300, w: SHOW.ME_W }; }

// Buddies stand on a rainbow arc around and above me, in lighting order
// (j = 0 is lit first = the newest, leftmost candle p = n - 1).
function circleSpot(j, n) {
  const a0 = Math.PI * 0.97, a1 = Math.PI * 2.03;
  const a = n === 1 ? Math.PI * 1.25 : lerp(a0, a1, j / (n - 1));
  return { x: 180 + 150 * Math.cos(a), y: 232 + 112 * Math.sin(a), w: SHOW.CIRCLE_W };
}

// Where I stand to touch buddy j: my flame tip on its wick, leaning in.
function visitSpot(j, n, meTipFrac) {
  const c = circleSpot(j, n);
  const side = c.x < 180 ? -1 : 1;
  const rot = c.x === 180 ? 0.15 : side * 0.38;
  const tip = (0.957 - meTipFrac) * 1.5 * SHOW.ME_VISIT_W;   // flame tip above my feet
  const wick = { x: c.x, y: c.y - SHOW.WICK * c.w };
  return { x: wick.x - tip * Math.sin(rot), y: wick.y + tip * Math.cos(rot) + 4, w: SHOW.ME_VISIT_W, rot };
}

// A hop from a to b: eased position, a jump arc of height h.
function hop(a, b, u, h = 40) {
  const e = easeInOut(u);
  return { x: lerp(a.x, b.x, e), y: lerp(a.y, b.y, e) - Math.sin(Math.PI * u) * h, w: lerp(a.w, b.w, e), rot: lerp(a.rot || 0, b.rot || 0, e) };
}

function showFrame(t, n, meTipFrac = 0.04) {
  const T = showTiming(n);
  const out = { actors: [], sparks: [], menorah: 1, umbrella: null, done: t >= T.finale + 0.5, end: T.end };
  out.menorah = 1 - 0.7 * prog(t, SHOW.GATHER, 0.5) + 0.7 * prog(t, T.back, 0.6);

  // ---- buddies ----
  for (let p = 0; p < n; p++) {
    const j = n - 1 - p;                       // lighting order
    const home = buddyHome(p), spot = circleSpot(j, n);
    const litAt = SHOW.PASS + j * T.dt + 0.6 * T.dt;
    const lit = t >= litAt;
    let pos, mood = 'calm', arms = 'down', visible = true;

    if (t < SHOW.GATHER) {
      if (p === n - 1) {                       // tonight's buddy arrives
        const u = prog(t, 0, SHOW.ARRIVE * 0.9);
        if (n % 2 === 1) {                     // odd nights: floats down on an umbrella
          const e = 1 - Math.pow(1 - u, 2);
          pos = { x: home.x + Math.sin(u * 9) * 16 * (1 - u), y: lerp(-40, home.y, e), w: home.w, rot: Math.sin(u * 9) * 0.18 * (1 - u) };
          if (u < 1) out.umbrella = { x: pos.x, y: pos.y - SHOW.FEET * home.w - 6, w: home.w * 1.5, rot: pos.rot, open: 1 - prog(t, 0.8, 0.15) };
          arms = 'up';
        } else {                               // even nights: runs in from the side
          pos = { x: lerp(-30, home.x, easeInOut(u)), y: home.y - Math.abs(Math.sin(u * Math.PI * 5)) * 12 * (1 - u * .5), w: home.w, rot: 0.12 * (1 - u) };
          arms = 'wave';
        }
        mood = u < 1 ? 'excited' : 'happy';
      } else pos = home;
    } else if (t < T.back) {
      const u = prog(t, SHOW.GATHER + 0.05 * j, 0.7);
      pos = u < 1 ? hop(home, spot, u, 46) : { ...spot };
      mood = u < 1 ? 'happy' : 'happy';
      if (t >= SHOW.IGNITE - 0.35 && t < SHOW.PASS) { arms = 'up'; mood = 'excited'; }
      if (lit) {
        const v = prog(t, litAt, 0.35);       // a happy jump when lit
        pos = { ...pos, y: pos.y - Math.sin(Math.PI * v) * 16 };
        arms = v < 1 ? 'up' : 'down'; mood = 'excited';
      }
    } else {
      const u = prog(t, T.back + 0.04 * j, 0.75);
      pos = u < 1 ? hop(spot, home, u, 50) : { ...home };
      mood = 'happy';
      if (t >= T.finale) {                     // a stadium wave along the hanukkiah
        const v = prog(t, T.finale + 0.07 * (n - 1 - p), 0.32);
        pos = { ...pos, y: pos.y - Math.sin(Math.PI * v) * 10 };
        mood = 'excited'; arms = v > 0 && v < 1 ? 'up' : 'down';
      }
    }
    out.actors.push({ id: 'b' + p, kind: 'buddy', p, ...pos, rot: pos.rot || 0, lit, mood, arms, visible });
  }

  // ---- me (the shamash) ----
  {
    const home = meHome(), center = meCenter();
    let pos = home, mood = 'happy', arms = 'down', lit = t >= SHOW.IGNITE, scale = 1;
    if (t < SHOW.GATHER) { mood = 'wink'; }
    else if (t < SHOW.PASS) {
      const u = prog(t, SHOW.GATHER + 0.05, 0.75);
      pos = u < 1 ? hop(home, center, u, 70) : center;
      if (t >= SHOW.IGNITE - 0.35) { arms = 'up'; mood = 'excited'; }
      const pop = prog(t, SHOW.IGNITE, 0.4);
      if (pop > 0 && pop < 1) scale = 1 + Math.sin(Math.PI * pop) * 0.14;
    } else if (t < T.passEnd) {
      const j = Math.min(n - 1, Math.floor((t - SHOW.PASS) / T.dt));
      const from = j === 0 ? center : visitSpot(j - 1, n, meTipFrac);
      const u = prog(t, SHOW.PASS + j * T.dt, 0.5 * T.dt);
      pos = hop(from, visitSpot(j, n, meTipFrac), u, 26);
      arms = 'point'; mood = 'excited';
    } else if (t < T.back) {
      pos = hop(visitSpot(n - 1, n, meTipFrac), center, prog(t, T.passEnd, 0.3), 24);
      arms = 'up'; mood = 'excited';
    } else {
      const u = prog(t, T.back + 0.15, 0.8);
      pos = u < 1 ? hop(center, home, u, 60) : home;
      mood = t >= T.finale ? 'wink' : 'happy';
      if (t >= T.finale) {
        const v = prog(t, T.finale + 0.07 * n, 0.32);
        pos = { ...pos, y: pos.y - Math.sin(Math.PI * v) * 10 };
      }
    }
    out.actors.push({ id: 'me', kind: 'me', ...pos, rot: pos.rot || 0, w: pos.w * scale, lit, mood, arms, visible: true });
  }

  // ---- sparks: a burst when I ignite, a small one at every touch ----
  const burst = (cx, cy, start, count, dist, size) => {
    const u = prog(t, start, 0.5);
    if (u <= 0 || u >= 1) return;
    for (let i = 0; i < count; i++) {
      const a = i / count * Math.PI * 2 + start;
      const d = dist * (1 - Math.pow(1 - u, 3));
      out.sparks.push({ x: cx + Math.cos(a) * d, y: cy + Math.sin(a) * d * 0.9 - u * 12, r: size * (1 - u * .7), alpha: 1 - u, gold: i % 2 === 0 });
    }
  };
  const c = meCenter();
  burst(c.x, c.y - (0.957 - meTipFrac) * 1.5 * c.w + 20, SHOW.IGNITE, 16, 90, 5);
  for (let j = 0; j < n; j++) {
    const s = circleSpot(j, n);
    burst(s.x, s.y - SHOW.WICK * s.w - 8, SHOW.PASS + j * T.dt + 0.6 * T.dt, 8, 34, 3.5);
  }

  // draw back to front
  out.actors.sort((a, b) => (a.y - (a.kind === 'me' && t > SHOW.GATHER && t < T.back ? -1000 : 0)) - (b.y - (b.kind === 'me' && t > SHOW.GATHER && t < T.back ? -1000 : 0)));
  return out;
}

if (typeof module !== 'undefined') module.exports = { SHOW, showFrame, showTiming, posX };
