// Color tracing (PNG/JPG/WebP → layered SVG) with vtracer in a Web Worker, as in the desktop app.
// The 650 KB WASM is fetched (SRI-checked) and compiled only the first time someone traces an image.
import traceWorkerUrl from '../workers/trace.worker.js?worker&url';
import { fetchAsset, VTRACER_PATH } from './assets.js';
import { createModuleWorker } from './engine.js';
import { validateTraceRequest } from '../shared/image-trace.js';

const TRACE_TIMEOUT_MS = 60 * 1000;
let modulePromise = null;

function loadVtracer() {
  if (!modulePromise) {
    modulePromise = (async () => {
      const response = await fetchAsset(VTRACER_PATH);
      if (!response.ok) throw new Error(`Could not load the image tracer (HTTP ${response.status}).`);
      return WebAssembly.compileStreaming(response);
    })();
    modulePromise.catch(() => { modulePromise = null; });
  }
  return modulePromise;
}

export async function traceImage(rgba, width, height, options) {
  const request = validateTraceRequest(rgba, width, height, options);
  const wasmModule = await loadVtracer();
  return new Promise((resolve, reject) => {
    const worker = createModuleWorker(traceWorkerUrl);
    const finish = (error, result) => {
      clearTimeout(timer);
      worker.terminate();
      if (error) reject(error);
      else resolve(result);
    };
    const timer = setTimeout(() => finish(new Error('Tracing took longer than 60 seconds. Use fewer colors or a smaller image.')), TRACE_TIMEOUT_MS);
    worker.onmessage = ({ data }) => (data.error ? finish(new Error(data.error)) : finish(null, { svg: data.svg, colors: data.colors, areas: data.areas }));
    worker.onerror = event => finish(new Error('Image tracing failed: ' + (event.message || 'worker error')));
    // The pixels are copied, so the caller's buffer stays usable for another trace.
    const pixels = request.rgba.slice().buffer;
    worker.postMessage({ wasmModule, request: { ...request, rgba: pixels } }, [pixels]);
  });
}
