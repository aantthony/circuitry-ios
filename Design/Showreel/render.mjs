// Renders reel.html frame by frame in headless Chromium and encodes circuitry-reel.mp4.
//
//   node render.mjs                 full render (needs Playwright + an ffmpeg with libx264)
//   node render.mjs --stills 4.2,9  render single frames at the given seconds to stills/
//
// Environment: FFMPEG (path to ffmpeg), PLAYWRIGHT (path to the playwright package),
// WORKERS (parallel pages, default 4).
import { createServer } from 'node:http';
import { createRequire } from 'node:module';
import { readFile, mkdir, writeFile, rm, access } from 'node:fs/promises';
import { spawn, execFileSync } from 'node:child_process';
import { extname, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT || 'playwright');
const FFMPEG = process.env.FFMPEG || 'ffmpeg';
const WORKERS = Number(process.env.WORKERS || 4);
const FPS = 60, FRAMES = 15 * FPS;

// Space Grotesk and JetBrains Mono (SIL OFL) are fetched from Google Fonts rather than vendored.
const FONTS = { SpaceGrotesk: 'Space Grotesk', JetBrainsMono: 'JetBrains Mono' };
async function ensureFonts() {
  await mkdir(join(ROOT, 'fonts'), { recursive: true });
  for (const [file, family] of Object.entries(FONTS)) {
    const out = join(ROOT, 'fonts', `${file}.woff2`);
    try { await access(out); continue; } catch {}
    const css = await (await fetch(`https://fonts.googleapis.com/css2?family=${family.replace(/ /g, '+')}:wght@400;700`, { headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120' } })).text();
    const latin = css.split('/* latin */')[1];
    const url = latin.match(/url\((.*?)\)/)[1];
    await writeFile(out, Buffer.from(await (await fetch(url)).arrayBuffer()));
  }
}

const TYPES = { '.html': 'text/html', '.woff2': 'font/woff2', '.js': 'text/javascript' };
function serve() {
  const server = createServer(async (req, res) => {
    try {
      const path = join(ROOT, decodeURIComponent(new URL(req.url, 'http://x').pathname));
      res.writeHead(200, { 'Content-Type': TYPES[extname(path)] || 'application/octet-stream' });
      res.end(await readFile(path));
    } catch { res.writeHead(404); res.end(); }
  });
  return new Promise(r => server.listen(0, () => r(server)));
}

async function openPage(browser, port) {
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  page.on('pageerror', e => { console.error('page error:', e); process.exit(1); });
  await page.goto(`http://localhost:${port}/reel.html?render`);
  await page.evaluate(() => window.ready);
  return page;
}
const grab = async (page, f) => Buffer.from((await page.evaluate(f => window.renderFrameJPEG(f), f)).split(',')[1], 'base64');

await ensureFonts();
const server = await serve();
const port = server.address().port;
const browser = await chromium.launch({ executablePath: process.env.CHROMIUM || undefined });
const stillsArg = process.argv.indexOf('--stills');

if (stillsArg > 0) {
  await mkdir(join(ROOT, 'stills'), { recursive: true });
  const page = await openPage(browser, port);
  for (const s of process.argv[stillsArg + 1].split(',')) {
    const f = Math.round(Number(s) * FPS);
    await writeFile(join(ROOT, 'stills', `t${String(s).padStart(5, '0')}.jpg`), await grab(page, f));
  }
} else {
  const dir = join(ROOT, 'frames');
  await rm(dir, { recursive: true, force: true }); await mkdir(dir);
  let done = 0; const t0 = Date.now();
  await Promise.all(Array.from({ length: WORKERS }, async (_, w) => {
    const page = await openPage(browser, port);
    for (let f = w; f < FRAMES; f += WORKERS) {
      await writeFile(join(dir, `f${String(f).padStart(4, '0')}.jpg`), await grab(page, f));
      if (++done % 60 === 0) console.log(`${done}/${FRAMES} frames  ${((Date.now() - t0) / 1000).toFixed(0)}s`);
    }
  }));
  execFileSync('node', [join(ROOT, 'audio.mjs')], { stdio: 'inherit' });
  await new Promise((resolve, reject) => {
    const ff = spawn(FFMPEG, ['-y', '-loglevel', 'error', '-framerate', String(FPS), '-i', join(dir, 'f%04d.jpg'), '-i', join(ROOT, 'audio.wav'),
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '21', '-pix_fmt', 'yuv420p', '-profile:v', 'high', '-tune', 'film',
      '-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart', '-shortest', join(ROOT, 'circuitry-reel.mp4')], { stdio: 'inherit' });
    ff.on('exit', c => c === 0 ? resolve() : reject(new Error(`ffmpeg exited ${c}`)));
  });
  console.log('wrote circuitry-reel.mp4');
}
await browser.close();
server.close();
