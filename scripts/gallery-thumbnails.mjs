// Gallery pictures: renders every built-in tool with its default values in the production build and saves
// the viewport as public/gallery/<id>.webp (the Lithophane generator → lithophane.webp), then rebuilds the
// library index so the cards point at them. Run after a change to the examples:
//   npm run build && npm run thumbnails
// Needs Chrome or Edge on this computer (CHROME=path overrides the search). Developer tool only:
// the pictures are committed, so deploys do not run this.
import { spawn } from 'node:child_process';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const WEB = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const OUTPUT = path.join(WEB, 'public', 'gallery');
const PORT = 4187;
const DEBUG_PORT = 9347;
const SIZE = { width: 480, height: 360 }; // 2× the card picture
const CHROMES = [
  process.env.CHROME,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium'
].filter(Boolean);

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

async function findChrome() {
  for (const candidate of CHROMES) if (await fs.access(candidate).then(() => true, () => false)) return candidate;
  throw new Error('Chrome or Edge was not found. Set CHROME to its path.');
}

async function waitFor(check, what, timeoutMs = 60000) {
  const started = Date.now();
  for (;;) {
    const value = await check().catch(() => null);
    if (value) return value;
    if (Date.now() - started > timeoutMs) throw new Error('Timed out waiting for ' + what);
    await sleep(250);
  }
}

function connect(url) {
  const socket = new WebSocket(url);
  let id = 0;
  const pending = new Map();
  socket.addEventListener('message', event => {
    const message = JSON.parse(event.data);
    if (!message.id || !pending.has(message.id)) return;
    const { resolve, reject } = pending.get(message.id);
    pending.delete(message.id);
    if (message.error) reject(new Error(message.error.message));
    else resolve(message.result);
  });
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const messageId = ++id;
    pending.set(messageId, { resolve, reject });
    socket.send(JSON.stringify({ id: messageId, method, params }));
  });
  return new Promise((resolve, reject) => {
    socket.addEventListener('open', () => resolve({ send, close: () => socket.close() }));
    socket.addEventListener('error', reject);
  });
}

const children = [];
const stopAll = () => children.forEach(child => { try { child.kill(); } catch { /* already gone */ } });
process.on('exit', stopAll);

try {
  await fs.access(path.join(WEB, 'dist', 'index.html')).catch(() => { throw new Error('Build first: npm run build'); });
  const preview = spawn(process.execPath, [path.join(WEB, 'node_modules', 'vite', 'bin', 'vite.js'), 'preview', '--port', String(PORT), '--strictPort'], { cwd: WEB, stdio: 'ignore' });
  children.push(preview);
  const base = `http://localhost:${PORT}`;
  await waitFor(() => fetch(base + '/').then(response => response.ok), 'vite preview');

  const profile = await fs.mkdtemp(path.join(os.tmpdir(), 'bonastudio-thumbs-'));
  const chrome = spawn(await findChrome(), [
    '--headless=new', `--remote-debugging-port=${DEBUG_PORT}`, `--user-data-dir=${profile}`,
    '--window-size=1280,900', '--hide-scrollbars', '--no-first-run', '--no-default-browser-check', 'about:blank'
  ], { stdio: 'ignore' });
  children.push(chrome);
  const target = await waitFor(async () => {
    const list = await (await fetch(`http://127.0.0.1:${DEBUG_PORT}/json/list`)).json();
    return list.find(item => item.type === 'page');
  }, 'Chrome');
  const cdp = await connect(target.webSocketDebuggerUrl);
  const evaluate = async expression => {
    const { result, exceptionDetails } = await cdp.send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
    if (exceptionDetails) throw new Error(exceptionDetails.exception?.description || exceptionDetails.text);
    return result.value;
  };
  await cdp.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 900, deviceScaleFactor: 1, mobile: false });
  await cdp.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: 'light' }] });
  await cdp.send('Page.navigate', { url: base + '/' });
  await waitFor(() => evaluate("document.querySelector('.modal-gallery') ? true : false"), 'the gallery');
  // Close the start-up gallery and hide what is not part of the model picture.
  await evaluate(`(() => {
    document.querySelector('#modalLayer [data-close]').click();
    const style = document.createElement('style');
    style.textContent = '#viewHelp,#activeObjectChip,#transformHud,#viewportNotice,.toast-region{display:none!important}';
    document.head.append(style);
  })()`);
  await waitFor(() => evaluate("document.querySelector('#engineStatus').classList.contains('is-ready')"), 'the render engine', 120000);

  const { tools } = await (await fetch(base + '/library/index.json')).json();
  const jobs = [{ id: 'lithophane', select: "document.querySelector('#modeLithophane').click()" },
    ...tools.map(tool => ({ id: tool.id, select: `(() => {
      if (document.querySelector('#modeLithophane').getAttribute('aria-checked') === 'true') document.querySelector('#modeTools').click();
      const select = document.querySelector('#toolSelect');
      select.value = ${JSON.stringify(tool.id)};
      select.dispatchEvent(new Event('change'));
    })()` }))];
  await fs.mkdir(OUTPUT, { recursive: true });
  for (const job of jobs) {
    try {
      await capture(job);
    } catch (error) {
      console.warn('skipped  ', job.id, '·', error.message); // the card shows a placeholder instead
    }
  }
  async function capture(job) {
    await evaluate(job.select);
    await sleep(300);
    // Rendered: no pending/rendering state, the model on screen, then a moment for the camera to settle.
    await waitFor(() => evaluate(`(() => {
      const dot = document.querySelector('#renderDot');
      return !dot.classList.contains('is-pending') && !dot.classList.contains('is-rendering')
        && document.querySelector('#emptyState').hidden && !document.querySelector('.viewport').classList.contains('is-busy');
    })()`), 'the render of ' + job.id, 180000);
    await sleep(900);
    const box = await evaluate(`(() => { const r = document.querySelector('#previewCanvas').getBoundingClientRect(); return { x: r.x, y: r.y, width: r.width, height: r.height }; })()`);
    // The middle 4:3 part of the canvas, where the framed model sits.
    const width = Math.min(box.width, box.height * 4 / 3);
    const height = width * 3 / 4;
    const clip = { x: box.x + (box.width - width) / 2, y: box.y + (box.height - height) / 2, width, height, scale: SIZE.width / width };
    const { data } = await cdp.send('Page.captureScreenshot', { format: 'webp', quality: 82, clip, captureBeyondViewport: false });
    await fs.writeFile(path.join(OUTPUT, job.id + '.webp'), Buffer.from(data, 'base64'));
    console.log('picture  ', job.id);
  }
  cdp.close();
  stopAll();
  // The index lists each tool's picture (scripts/build-library.mjs).
  await new Promise((resolve, reject) => spawn(process.execPath, [path.join(WEB, 'scripts', 'build-library.mjs')], { cwd: WEB, stdio: 'inherit' })
    .on('exit', code => (code === 0 ? resolve() : reject(new Error('build-library failed')))));
  await fs.rm(profile, { recursive: true, force: true }).catch(() => {});
} catch (error) {
  stopAll();
  console.error(error.message);
  process.exitCode = 1;
}
