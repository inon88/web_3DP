// One trace per worker (like the desktop image-trace-worker.cjs): vtracer runs off the main thread,
// and a slow trace is stopped by terminating the worker.
import { initVtracer } from '../vendor/vtracer/vtracer.js';
import { traceImage } from '../shared/image-trace.js';

self.onmessage = ({ data }) => {
  try {
    initVtracer(data.wasmModule);
    const { svg, colors, areas } = traceImage({ ...data.request, rgba: new Uint8Array(data.request.rgba) });
    self.postMessage({ svg, colors, areas });
  } catch (error) {
    self.postMessage({ error: error instanceof Error ? error.message : String(error) });
  }
};
