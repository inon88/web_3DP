// M0 browser spike: compile once on the main thread, fresh worker + instance per render.
const log = document.querySelector('#log');
const results = [];
const write = line => { log.textContent += '\n' + line; console.log('[M0] ' + line); };
log.textContent = '';

write('crossOriginIsolated = ' + self.crossOriginIsolated + ', trustedTypes = ' + ('trustedTypes' in self));

const t0 = performance.now();
const wasmModule = await WebAssembly.compileStreaming(fetch('/openscad/openscad.wasm'));
const compileMs = performance.now() - t0;
write(`compileStreaming (unduh + kompilasi, sekali): ${compileMs.toFixed(0)} ms`);

const names = await (await fetch('/list')).json();
const select = document.querySelector('#example');
for (const name of names) select.append(new Option(name, name));
select.value = names.includes('bracket.scad') ? 'bracket.scad' : names[0];

let current = null;

// Trusted Types: Worker URLs must come from a policy. Only same-origin .js URLs are allowed.
const workerPolicy = self.trustedTypes?.createPolicy('worker-url', {
  createScriptURL(url) {
    const parsed = new URL(url, location.href);
    if (parsed.origin !== location.origin || !parsed.pathname.endsWith('.js')) throw new TypeError('Worker URL ditolak: ' + url);
    return parsed.href;
  }
});
const workerUrl = workerPolicy ? workerPolicy.createScriptURL(new URL('./render.worker.js', import.meta.url).href) : new URL('./render.worker.js', import.meta.url);

async function render(name, backend) {
  const source = await (await fetch('/examples/' + encodeURIComponent(name))).text();
  const needsFont = /\btext\s*\(/.test(source);
  const fonts = needsFont ? [{ name: 'arial.ttf', data: await (await fetch('/fonts/arial.ttf')).arrayBuffer() }] : [];
  // Sibling SVG assets referenced by the example.
  const assets = [];
  for (const match of source.matchAll(/"([^"\n]+\.svg)"/g)) {
    const response = await fetch('/examples/' + encodeURIComponent(match[1]));
    if (response.ok) assets.push({ path: match[1], data: await response.arrayBuffer() });
  }
  return new Promise(resolve => {
    const started = performance.now();
    const worker = new Worker(workerUrl, { type: 'module' });
    current = { worker, resolve };
    worker.onmessage = ({ data }) => {
      worker.terminate(); current = null;
      resolve({ ...data, roundTrip: performance.now() - started });
    };
    worker.onerror = event => { worker.terminate(); current = null; resolve({ ok: false, error: event.message, roundTrip: performance.now() - started }); };
    worker.postMessage({ wasmModule, source, entry: name, assets, fonts, backend, quality: { fa: 20, fs: 2 } });
  });
}

function report(name, backend, r) {
  results.push({ name, backend, ...r, positions: undefined });
  window.__m0 = { compileMs, results };
  if (!r.ok) return write(`${name} [${backend || 'default'}] GAGAL: ${r.error}`);
  write(`${name} [${backend || 'default'}] instantiate ${r.instantiate.toFixed(0)} ms · render ${r.render.toFixed(0)} ms · parse ${r.parse.toFixed(0)} ms · total ${r.roundTrip.toFixed(0)} ms · ${r.positions.length / 9} segitiga (Float32Array ${r.positions.buffer.byteLength} B, transfer)`);
}

document.querySelector('#run').onclick = async () => {
  const name = select.value, backend = document.querySelector('#backend').value;
  report(name, backend, await render(name, backend));
};
document.querySelector('#all').onclick = async () => {
  window.__m0done = false;
  for (const name of names) report(name, 'manifold', await render(name, 'manifold'));
  write('selesai.');
  window.__m0done = true;
};
document.querySelector('#cancel').onclick = () => {
  if (!current) return;
  current.worker.terminate();
  current.resolve({ ok: false, error: 'dibatalkan (worker.terminate)' });
  current = null;
};
