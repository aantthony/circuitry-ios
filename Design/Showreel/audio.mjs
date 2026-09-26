// Synthesizes the reel's 15 second soundtrack (120bpm) to audio.wav, with every hit placed on
// the picture's cues in reel.html. No samples: everything is oscillators, noise and filters.
import { writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const SR = 48000, DUR = 15, N = SR * DUR, TAU = Math.PI * 2;
const L = new Float32Array(N), R = new Float32Array(N);
const VL = new Float32Array(N), VR = new Float32Array(N);   // reverb send
let seed = 7; const rnd = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
const noise = () => rnd() * 2 - 1;
const mtof = m => 440 * Math.pow(2, (m - 69) / 12);
const idx = t => Math.floor(t * SR);

// add a mono voice fn(localTime) -> sample at time t0 for dur seconds
function voice(t0, dur, fn, { gain = 1, pan = 0, send = 0 } = {}) {
  const gl = gain * Math.cos((pan + 1) * Math.PI / 4), gr = gain * Math.sin((pan + 1) * Math.PI / 4);
  const s0 = Math.max(0, idx(t0)), s1 = Math.min(N, idx(t0 + dur));
  for (let i = s0; i < s1; i++) { const v = fn(i / SR - t0); L[i] += v * gl; R[i] += v * gr; if (send) { VL[i] += v * gl * send; VR[i] += v * gr * send; } }
}
const env = (t, a, d) => t < a ? t / a : Math.exp(-(t - a) * d);
function onePole(cut) { let y = 0; return (x, c = cut) => { const k = 1 - Math.exp(-TAU * c / SR); y += k * (x - y); return y; }; }

// ---------- instruments ----------
function kick(t0, g = 1) {
  let ph = 0;
  voice(t0, 0.6, t => { ph += TAU * (44 + 120 * Math.exp(-t * 30)) / SR; return Math.sin(ph) * Math.exp(-t * 6.5) * 1.1 + (t < 0.004 ? noise() * 0.5 : 0); }, { gain: 0.9 * g });
}
function clap(t0, g = 1) {
  const lp = onePole(2200), hp = onePole(700);
  voice(t0, 0.35, t => { const n = noise(), b = lp(n) - hp(n); const e = [0, 0.011, 0.022].reduce((a, o) => a + (t >= o ? Math.exp(-(t - o) * (o === 0.022 ? 16 : 90)) : 0), 0); return b * e * 2.2; }, { gain: 0.45 * g, send: 0.35 });
}
function hat(t0, g = 1, open = false) {
  const lp = onePole(7000);
  voice(t0, open ? 0.25 : 0.06, t => { const n = noise(); return (n - lp(n)) * Math.exp(-t * (open ? 14 : 70)); }, { gain: 0.3 * g, pan: 0.25 });
}
function bass(t0, dur, m, g = 1) {
  const f = mtof(m), lp = onePole(300); let ph = 0;
  voice(t0, dur + 0.05, t => { ph += f / SR; const saw = 2 * (ph % 1) - 1, sq = (ph % 1) < 0.5 ? 1 : -1; const cut = 180 + 900 * Math.exp(-t * 12); return (lp(saw * 0.6 + sq * 0.4, cut) + Math.sin(TAU * f * t) * 0.6) * Math.min(1, t / 0.004) * (t > dur ? Math.exp(-(t - dur) * 80) : 1); }, { gain: 0.34 * g });
}
function pad(t0, dur, notes, g = 1, rel = 0.6) {
  notes.forEach((m, k) => [-0.09, 0.09].forEach(dt => {
    const f = mtof(m) * Math.pow(2, dt / 12), lp = onePole(1400); let ph = rnd();
    voice(t0, dur + rel * 4, t => { ph += f / SR; const a = Math.min(1, t / 0.25) * (t > dur ? Math.exp(-(t - dur) / rel) : 1); return lp(2 * (ph % 1) - 1) * a; }, { gain: 0.045 * g, pan: dt > 0 ? 0.5 : -0.5, send: 0.5 });
  }));
}
function pluck(t0, m, g = 1, pan = 0, dec = 9) {
  const f = mtof(m), lp = onePole(4000); let ph = 0;
  voice(t0, 0.5, t => { ph += f / SR; const sq = (ph % 1) < 0.3 ? 1 : -1; return lp(sq, 600 + 5000 * Math.exp(-t * 18)) * Math.exp(-t * dec); }, { gain: 0.16 * g, pan, send: 0.4 });
}
function bell(t0, m, g = 1, pan = 0, dec = 3) {
  const f = mtof(m);
  voice(t0, 2.5, t => (Math.sin(TAU * f * t) + 0.5 * Math.sin(TAU * f * 2.01 * t) * Math.exp(-t * 6) + 0.25 * Math.sin(TAU * f * 3.99 * t) * Math.exp(-t * 9)) * Math.exp(-t * dec) * Math.min(1, t / 0.002), { gain: 0.11 * g, pan, send: 0.7 });
}
function blip(t0, f0, f1, dur, g = 1, pan = 0) {
  let ph = 0;
  voice(t0, dur, t => { ph += TAU * (f0 + (f1 - f0) * t / dur) / SR; return Math.sin(ph) * env(t, 0.002, 30 / dur * 0.25); }, { gain: 0.12 * g, pan, send: 0.2 });
}
function riser(t0, t1, g = 1) {
  const lp = onePole(200); let ph = 0; const d = t1 - t0;
  voice(t0, d, t => { const u = t / d; ph += TAU * (200 + 1400 * u * u) / SR; return (lp(noise(), 200 + 9000 * u * u * u) * 1.4 + Math.sin(ph) * 0.15) * u * u; }, { gain: 0.35 * g, send: 0.4 });
}
function whoosh(t0, d, g = 1, pan = 0) {
  const lp = onePole(500), hp = onePole(200);
  voice(t0, d, t => { const u = t / d, c = 300 + 5000 * Math.sin(u * Math.PI); const n = noise(); return (lp(n, c) - hp(n, c * 0.4)) * Math.sin(u * Math.PI) ** 2; }, { gain: 0.5 * g, pan, send: 0.3 });
}
function impact(t0, g = 1) {
  let ph = 0; const lp = onePole(3000);
  voice(t0, 2.4, t => { ph += TAU * (30 + 90 * Math.exp(-t * 8)) / SR; return Math.sin(ph) * Math.exp(-t * 2.2) * 1.2 + lp(noise(), 800 + 6000 * Math.exp(-t * 4)) * Math.exp(-t * 3.5) * 0.7; }, { gain: 0.8 * g, send: 0.6 });
}
function click(t0, g = 1, pan = 0) {
  voice(t0, 0.03, t => (noise() * 0.6 + Math.sin(TAU * 2400 * t)) * Math.exp(-t * 300), { gain: 0.3 * g, pan });
}
function zap(t0, g = 1) {
  let ph = 0;
  voice(t0, 0.12, t => { ph += TAU * (1800 * Math.exp(-t * 25) + 90) / SR; const crush = Math.round(Math.sin(ph) * 4) / 4; return (crush + (Math.floor(t * 4000) % 2 ? noise() * 0.5 : 0)) * Math.exp(-t * 25); }, { gain: 0.22 * g, send: 0.2 });
}

// ---------- arrangement (all times match reel.html) ----------
// 0-2 SIGNAL: heartbeat, burst, data chatter, riser into the drop
kick(0.02, 0.45); kick(0.26, 0.55); impact(0.5, 0.45); bell(0.5, 81, 0.8, 0, 1.5); bell(0.5, 88, 0.5, 0.3, 2);
for (let i = 0; i < 38; i++) { const t = 0.52 + rnd() * 0.9; blip(t, 1500 + rnd() * 2500, 2500 + rnd() * 3000, 0.03 + rnd() * 0.04, 0.35, rnd() * 2 - 1); }
pad(0.5, 1.5, [57, 64, 69], 0.7, 0.3);
riser(1.0, 2.0, 1.1);
// drop at 2.0
impact(2.0, 1); clap(2.0, 0.6);
const CHORDS = [[57, 60, 64, 71], [53, 57, 60, 67], [48, 55, 60, 64], [55, 59, 62, 69]];
const ROOTS = [33, 29, 36, 31];
for (let bar = 0; bar < 4; bar++) {
  const t0 = 2 + bar * 2;
  pad(t0, 2, CHORDS[bar], 1, 0.25);
  for (let e = 0; e < 8; e++) if (e % 2 || bar > 0 || e > 0) bass(t0 + e * 0.25, 0.2, ROOTS[bar] + (e === 7 ? 12 : 0), e % 2 ? 0.8 : 1);
}
for (let b = 0; b < 16; b++) {
  const t = 2 + b * 0.5;
  kick(t, b === 0 ? 1.1 : 1);
  if (b % 2 === 1) clap(t, 0.8);
  if (t >= 3.5) { hat(t + 0.25, 1, b % 4 === 3); hat(t + 0.125, 0.4); hat(t + 0.375, 0.4); }
}
// BUILD / TEST / DEBUG word hits
for (const [t, p] of [[2.0, -0.4], [2.5, 0], [3.0, 0.4]]) { whoosh(t - 0.12, 0.3, 0.6, p); bell(t, 76 + (t - 2) * 6, 0.5, p, 5); }
whoosh(3.35, 0.35, 0.7);
// LOGIC: a pluck per truth-table row; pitch follows each gate's output Q
const GATEF = [(a, b) => a & b, (a, b) => a | b, (a, b) => 1 - (a & b), (a, b) => 1 - (a | b), (a, b) => 1 - (a ^ b), (a, b) => a ^ b];
const SCALE = [69, 72, 76, 79, 81, 84];
for (let r = 0; r < 24; r++) {
  const t = 4 + r * 0.125, g = GATEF[Math.floor(r / 4)], row = r & 3, q = g(row >> 1, row & 1);
  pluck(t, q ? SCALE[(Math.floor(r / 4) + row) % 6] : 57 + (row % 2) * 7, q ? 1 : 0.6, row % 2 ? 0.35 : -0.35);
}
for (let k = 0; k < 6; k++) { blip(4 + k * 0.5 - 0.01, 300, 2400, 0.09, 0.6); click(4 + k * 0.5, 0.6); }
riser(6.4, 7.05, 0.6);
// BUILD: panel pops, wire ticks, switch clicks, display beeps, CORRECT chime
impact(7.12, 0.35);
[7.12, 7.3, 7.45, 7.55, 7.7, 7.85].forEach((t, i) => { blip(t, 500 + i * 120, 1300 + i * 200, 0.08, 0.7, -0.6 + i * 0.24); click(t, 0.5); });
for (let i = 0; i < 13; i++) click(7.95 + i * 0.035 + 0.3, 0.35, (i % 2 ? 1 : -1) * 0.5);
click(8.5, 1.3, -0.5); blip(8.5, 900, 600, 0.06, 0.8, -0.5);
click(9.0, 1.3, -0.5); blip(9.0, 900, 600, 0.06, 0.8, -0.5);
blip(8.92, 1320, 1320, 0.08, 0.6, 0.5); blip(9.42, 1480, 1480, 0.08, 0.6, 0.5);
whoosh(9.2, 0.4, 0.5);
[72, 76, 79, 84].forEach((m, i) => bell(9.72 + i * 0.06, m, 1.1, -0.3 + i * 0.2, 2.5));
// dive into the display
riser(9.95, 10.5, 1.2); whoosh(10.05, 0.45, 1);
// SCALE: glitch cuts, counters, tunnel, compile
impact(10.5, 0.8);
for (const t of [10.5, 11.0, 11.5, 12.0]) { zap(t, 1); kick(t, 1); }
for (const t of [10.75, 11.25, 11.75]) { kick(t, 0.8); clap(t, 0.7); }
for (let n = 1; n <= 21; n++) click(10.5 + 0.34 * (1 - Math.cbrt(1 - n / 21)), 0.4, 0.2);
for (let n = 1; n <= 28; n++) click(11.0 + 0.34 * (1 - Math.cbrt(1 - n / 28)), 0.4, -0.2);
for (let i = 0; i < 28; i++) blip(11.0 + i * 0.008, 2000 + i * 60, 2600 + i * 60, 0.03, 0.25, Math.cos(i / 28 * TAU));
for (let i = 0; i < 22; i++) whoosh(11.3 + i * 0.026, 0.25, 0.12, Math.cos(i * 2.4));
pad(10.5, 1.0, [57, 60, 64, 69], 0.8, 0.2); pad(11.5, 0.5, [53, 60, 65, 69], 0.9, 0.2);
for (let e = 0; e < 6; e++) bass(10.5 + e * 0.25, 0.2, 33, 0.9);
for (let e = 0; e < 2; e++) bass(11.5 + e * 0.25, 0.2, 29, 0.9);
riser(12.0, 12.5, 1.3);
// CIRCUITRY end card: resolve to C major 9, signal ping through the logo, shimmer on the sweep
impact(12.5, 1.1); kick(12.5, 1.2);
pad(12.5, 2.0, [48, 55, 62, 64, 71], 1.4, 0.9);
bass(12.5, 1.6, 36, 1.1);
bell(13.02, 84, 0.8, -0.3, 3); bell(13.16, 91, 1, 0.3, 2.5);
'Circuitry'.split('').forEach((_, i) => pluck(13.3 + i * 0.034, [72, 76, 79, 83, 84, 88, 91, 95, 96][i], 0.5, -0.5 + i * 0.12, 12));
for (let i = 0; i < 22; i++) click(13.72 + i * 0.4 / 22, 0.18, 0.4);
for (let i = 0; i < 10; i++) bell(14.05 + i * 0.05, 96 + [0, 2, 4, 7, 9, 12, 14, 16, 19, 21][i], 0.35, -0.8 + i * 0.18, 4);

// ---------- reverb (Schroeder) + master ----------
function reverb(inp, delays, fb) {
  const out = new Float32Array(N);
  for (const d of delays) { const buf = new Float32Array(d); let p = 0, lp = 0; for (let i = 0; i < N; i++) { const y = buf[p]; lp = y * 0.6 + lp * 0.4; buf[p] = inp[i] + lp * fb; p = (p + 1) % d; out[i] += y / delays.length; } }
  for (const [d, g] of [[556, 0.5], [441, 0.5]]) { const buf = new Float32Array(d); let p = 0; for (let i = 0; i < N; i++) { const b = buf[p], x = out[i]; const y = -x * g + b; buf[p] = x + b * g; p = (p + 1) % d; out[i] = y; } }
  return out;
}
const rvL = reverb(VL, [1557, 1617, 1491, 1422], 0.84), rvR = reverb(VR, [1580, 1640, 1514, 1445], 0.84);
let peak = 0;
for (let i = 0; i < N; i++) {
  const fade = Math.min(1, (N - i) / (SR * 0.35));
  L[i] = Math.tanh((L[i] + rvL[i] * 0.9) * 1.1) * fade; R[i] = Math.tanh((R[i] + rvR[i] * 0.9) * 1.1) * fade;
  peak = Math.max(peak, Math.abs(L[i]), Math.abs(R[i]));
}
const norm = 0.89 / peak;
const buf = Buffer.alloc(44 + N * 4);
buf.write('RIFF', 0); buf.writeUInt32LE(36 + N * 4, 4); buf.write('WAVE', 8); buf.write('fmt ', 12);
buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22); buf.writeUInt32LE(SR, 24); buf.writeUInt32LE(SR * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34);
buf.write('data', 36); buf.writeUInt32LE(N * 4, 40);
for (let i = 0; i < N; i++) { buf.writeInt16LE(Math.round(L[i] * norm * 32767), 44 + i * 4); buf.writeInt16LE(Math.round(R[i] * norm * 32767), 46 + i * 4); }
writeFileSync(join(dirname(fileURLToPath(import.meta.url)), 'audio.wav'), buf);
console.log('wrote audio.wav');
