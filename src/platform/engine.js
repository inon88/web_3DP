// OpenSCAD engine for the browser (rancangan.md §3, §6, §11):
// - the 11 MB WASM is downloaded and compiled once (streaming), with progress events;
// - every render gets a fresh worker + instance (≈10 ms), terminated on cancel or timeout;
// - a newer preview cancels the running one;
// - results are cached by tool revision + inputs (S3), so undo and presets are instant.
import { fontData } from './fonts.js';
import renderWorkerUrl from '../workers/render.worker.js?worker&url';
import { fetchAsset, WASM_PATH } from './assets.js';

const CACHE_LIMIT_BYTES = 64 * 1024 * 1024;

export class RenderCanceledError extends Error {
  constructor() { super('Render canceled.'); this.name = 'RenderCanceledError'; }
}
export class RenderTimeoutError extends Error {}

let modulePromise = null;
export const engineEvents = new EventTarget();
engineEvents.status = 'idle'; // idle | loading | ready | error (for listeners that attach late)
const emit = (type, detail) => {
  if (type === 'ready' || type === 'error') engineEvents.status = type;
  else engineEvents.status = 'loading';
  engineEvents.dispatchEvent(new CustomEvent(type, { detail }));
};

async function compile() {
  // Integrity-checked: a CDN copy that does not match the pinned hash is rejected.
  const response = await fetchAsset(WASM_PATH);
  if (!response.ok || !response.body) throw new Error(`The render engine could not be downloaded (HTTP ${response.status}).`);
  const total = Number(response.headers.get('content-length')) || 0;
  const [forCompile, forProgress] = response.body.tee();
  // Count bytes on one branch while the other compiles as it streams in.
  (async () => {
    const reader = forProgress.getReader();
    let loaded = 0;
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      loaded += value.byteLength;
      emit('progress', { loaded, total });
    }
  })().catch(() => {});
  const module = await WebAssembly.compileStreaming(new Response(forCompile, { headers: { 'Content-Type': 'application/wasm' } }));
  emit('ready', {});
  return module;
}

export function loadEngine() {
  if (!modulePromise) {
    modulePromise = compile();
    modulePromise.catch(error => {
      modulePromise = null;
      emit('error', { message: error.message });
    });
  }
  return modulePromise;
}

// Trusted Types: Worker URLs must come from a policy (rancangan.md §7). Only same-origin scripts.
const workerPolicy = globalThis.trustedTypes?.createPolicy('bonastudio-worker', {
  createScriptURL(url) {
    const parsed = new URL(url, location.href);
    if (parsed.origin !== location.origin) throw new TypeError('Blocked a cross-origin worker: ' + url);
    return parsed.href;
  }
});

// Shared by the render and trace workers, so there is one Trusted Types policy.
export function createModuleWorker(workerUrl) {
  const url = new URL(workerUrl, location.href).href;
  return new Worker(workerPolicy ? workerPolicy.createScriptURL(url) : url, { type: 'module' });
}

function createWorker() {
  return createModuleWorker(renderWorkerUrl);
}

// ---- Cache (S3) ----
const cache = new Map();
let cacheBytes = 0;

function cacheKey(job, format, quality) {
  return JSON.stringify([job.tool.id, job.tool.revision, format, quality, job.params, job.nestedParameterOverrides, job.fonts.map(font => font.name)]);
}

function cacheGet(key) {
  const hit = cache.get(key);
  if (!hit) return null;
  cache.delete(key);
  cache.set(key, hit);
  return { output: hit.output.slice(0), itemEchoes: hit.itemEchoes, renderMs: 0, cached: true };
}

function cachePut(key, result) {
  const output = result.output.slice(0);
  if (output.byteLength > CACHE_LIMIT_BYTES / 4) return;
  cache.set(key, { output, itemEchoes: result.itemEchoes });
  cacheBytes += output.byteLength;
  for (const [oldKey, entry] of cache) {
    if (cacheBytes <= CACHE_LIMIT_BYTES) break;
    cache.delete(oldKey);
    cacheBytes -= entry.output.byteLength;
  }
}

// ---- Rendering ----
const running = new Map(); // channel → { worker, reject }

export function cancel(channel) {
  const current = running.get(channel);
  if (!current) return;
  running.delete(channel);
  current.worker.terminate();
  current.reject(new RenderCanceledError());
}

/**
 * @param job      result of prepareRenderJob()
 * @param format   '3mf' | 'stl'
 * @param quality  { fa, fs } or null to keep the model's own resolution
 * @param options  { channel: 'preview' | 'export', timeoutMs }
 */
export async function render(job, format, quality, { channel = 'preview', timeoutMs = 120000 } = {}) {
  // A newer request on the channel always supersedes the running one, even when it is a cache hit.
  cancel(channel);
  const cached = cacheGet(cacheKey(job, format, quality));
  if (cached) return cached;
  const key = cacheKey(job, format, quality);
  const [wasmModule, fonts] = await Promise.all([
    loadEngine(),
    Promise.all(job.fonts.map(async font => ({ name: font.name, data: await fontData(font) })))
  ]);
  const result = await new Promise((resolve, reject) => {
    const worker = createWorker();
    const entry = { worker, reject };
    running.set(channel, entry);
    const finish = (error, value) => {
      clearTimeout(timer);
      if (running.get(channel) === entry) running.delete(channel);
      worker.terminate();
      if (error) reject(error);
      else resolve(value);
    };
    const timer = setTimeout(() => finish(new RenderTimeoutError(`Rendering exceeded the ${Math.round(timeoutMs / 1000)}-second time limit.`)), timeoutMs);
    worker.onmessage = ({ data }) => (data.error ? finish(new Error(data.error)) : finish(null, data));
    worker.onerror = event => {
      event.preventDefault?.();
      finish(new Error('The render engine stopped: ' + (event.message || 'out of memory or an internal error.')));
    };
    // Files and fonts are copied (structured clone) so cached ArrayBuffers stay usable.
    worker.postMessage({
      wasmModule,
      files: job.files,
      entry: job.entry,
      values: job.params,
      nestedParameterOverrides: job.nestedParameterOverrides,
      fonts,
      format,
      quality,
      separateObjects: job.separateObjects
    });
  });
  cachePut(key, result);
  return result;
}
