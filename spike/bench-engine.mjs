// M0 spike: benchmark OpenSCAD WASM backends on the App examples.
// Mirrors the web plan: compile the WASM once, fresh instance per render in its own worker.
// Usage: node spike/bench-engine.mjs [--export] [--only name]
import { Worker } from 'node:worker_threads';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const APP = path.resolve(HERE, '..', '..');
const WASM_DIR = path.join(APP, 'vendor', 'openscad-wasm');
const EXAMPLES = path.join(APP, 'examples');
const FONTS = ['C:/Windows/Fonts/arial.ttf', 'C:/Windows/Fonts/arialbd.ttf'];
const PREVIEW = { fa: 20, fs: 2 };
const EXPORT = { fa: 2, fs: 0.2 };
const TIMEOUT_MS = Number(process.env.BENCH_TIMEOUT || 180000);

const args = process.argv.slice(2);
const withExport = args.includes('--export');
const only = args.includes('--only') ? args[args.indexOf('--only') + 1] : null;

async function listJobs() {
  const jobs = [];
  for (const entry of await fs.readdir(EXAMPLES, { withFileTypes: true })) {
    if (entry.isFile() && entry.name.endsWith('.scad')) jobs.push({ name: entry.name, dir: EXAMPLES, file: entry.name });
    if (entry.isDirectory()) {
      for (const inner of await fs.readdir(path.join(EXAMPLES, entry.name))) {
        if (inner.endsWith('.scad')) jobs.push({ name: entry.name + '/' + inner, dir: path.join(EXAMPLES, entry.name), file: inner });
      }
    }
  }
  return jobs.filter(job => !only || job.name.includes(only));
}

async function readTree(dir, base = '') {
  const files = [];
  for (const entry of await fs.readdir(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('.')) continue;
    const full = path.join(dir, entry.name);
    const rel = base ? base + '/' + entry.name : entry.name;
    // Only the job's own folder level matters for top-level examples; skip sibling project folders.
    if (entry.isDirectory()) { if (base || dir !== EXAMPLES) files.push(...await readTree(full, rel)); }
    else if (entry.isFile()) files.push({ path: rel, data: await fs.readFile(full) });
  }
  return files;
}

function runOnce(wasmModule, glueUrl, job, files, fonts, backend, quality) {
  return new Promise(resolve => {
    const started = performance.now();
    const worker = new Worker(new URL('./bench-worker.mjs', import.meta.url), {
      workerData: { wasmModule, glueUrl, entry: job.file, files, fonts, backend, quality }
    });
    const timer = setTimeout(() => { worker.terminate(); resolve({ ok: false, error: 'timeout', total: TIMEOUT_MS }); }, TIMEOUT_MS);
    worker.once('message', result => { clearTimeout(timer); worker.terminate(); resolve({ ...result, total: performance.now() - started }); });
    worker.once('error', error => { clearTimeout(timer); resolve({ ok: false, error: String(error?.message || error), total: performance.now() - started }); });
  });
}

const t0 = performance.now();
const wasmModule = await WebAssembly.compile(await fs.readFile(path.join(WASM_DIR, 'openscad.wasm')));
const compileMs = performance.now() - t0;
const glueUrl = new URL('file:///' + path.join(WASM_DIR, 'openscad.js').replace(/\\/g, '/')).href;
const fonts = [];
for (const font of FONTS) { try { fonts.push({ name: path.basename(font), data: await fs.readFile(font) }); } catch {} }

console.log(`WASM compile (once): ${compileMs.toFixed(0)} ms`);
const variants = [
  { label: 'default', backend: null, quality: PREVIEW },
  { label: 'cgal', backend: 'cgal', quality: PREVIEW },
  { label: 'manifold', backend: 'manifold', quality: PREVIEW }
];
if (withExport) {
  // CGAL at export quality takes minutes per model (136 s on articulated_cube_keychain); opt in with --cgal-export.
  if (args.includes('--cgal-export')) variants.push({ label: 'cgal-export', backend: 'cgal', quality: EXPORT });
  variants.push({ label: 'manifold-export', backend: 'manifold', quality: EXPORT });
}

const results = [];
for (const job of await listJobs()) {
  const files = await readTree(job.dir);
  for (const variant of variants) {
    const r = await runOnce(wasmModule, glueUrl, job, files, fonts, variant.backend, variant.quality);
    results.push({ example: job.name, variant: variant.label, ...r });
    const cell = r.ok
      ? `inst ${r.instantiate.toFixed(0)}ms  render ${r.render.toFixed(0)}ms  tris ${r.triangles}  ${(r.bytes / 1024).toFixed(0)}KB`
      : `FAIL ${r.error}`.slice(0, 160);
    console.log(`${job.name.padEnd(36)} ${variant.label.padEnd(16)} ${cell}`);
  }
}
await fs.writeFile(path.join(HERE, withExport ? 'bench-results-export.json' : 'bench-results.json'), JSON.stringify({ compileMs, results }, null, 2));
