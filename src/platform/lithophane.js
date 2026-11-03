// Lithophane generator for the browser (port of prepareGeneratorJob / runGeneratorWorker in the
// desktop main.cjs). The mesh is built by JavaScript in a Web Worker: no OpenSCAD engine needed.
import lithophaneWorkerUrl from '../workers/lithophane.worker.js?worker&url';
import { createModuleWorker, RenderCanceledError, RenderTimeoutError } from './engine.js';
import { validateParameterValues } from './render-job.js';
import { referencedToolAssets } from './session-files.js';
import { LITHOPHANE_IMAGE_PARAMETER } from '../shared/lithophane.js';

export const isGeneratorTool = tool => tool?.kind === 'generator';

const running = new Map(); // channel → { worker, reject }

function cancel(channel) {
  const current = running.get(channel);
  if (!current) return;
  running.delete(channel);
  current.worker.terminate();
  current.reject(new RenderCanceledError());
}

/**
 * @returns {Promise<{ output: ArrayBuffer, itemEchoes: string[], info: object }>}
 */
export async function renderLithophane(tool, values, format, { preview = false, channel = 'preview', timeoutMs = 120000 } = {}) {
  cancel(channel);
  const { params } = validateParameterValues(tool, values);
  // The photo lives in this tab's memory (session-files.js), like every other image.
  const [image] = referencedToolAssets(tool.id, { [LITHOPHANE_IMAGE_PARAMETER]: params[LITHOPHANE_IMAGE_PARAMETER] });
  const started = performance.now();
  return new Promise((resolve, reject) => {
    const worker = createModuleWorker(lithophaneWorkerUrl);
    const entry = { worker, reject };
    running.set(channel, entry);
    const finish = (error, value) => {
      clearTimeout(timer);
      if (running.get(channel) === entry) running.delete(channel);
      worker.terminate();
      if (error) reject(error);
      else resolve({ ...value, renderMs: performance.now() - started });
    };
    const timer = setTimeout(() => finish(new RenderTimeoutError(`The lithophane took longer than ${Math.round(timeoutMs / 1000)} seconds. Use a larger Detail value.`)), timeoutMs);
    worker.onmessage = ({ data }) => (data.error ? finish(new Error(data.error)) : finish(null, data));
    worker.onerror = event => {
      event.preventDefault?.();
      finish(new Error('The lithophane generator stopped: ' + (event.message || 'out of memory or an internal error.')));
    };
    // The photo is copied, so it stays usable for the next render.
    const png = image ? image.data.slice().buffer : null;
    worker.postMessage({ png, values: params, format, preview, name: tool.name }, png ? [png] : []);
  });
}
