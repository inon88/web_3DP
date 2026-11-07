// Built-in, read-only tool library served from /library (built by scripts/build-library.mjs),
// plus the Lithophane generator (JavaScript, no .scad files) and the tools imported in this session
// (session-tools.js; kept only in this tab's memory).
import { lithophaneManifest, LITHOPHANE_GENERATOR_VERSION } from '../shared/lithophane.js';
import { isSessionTool, sessionToolFiles, sessionToolList, withCustomParameters } from './session-tools.js';

const GENERATOR_TOOLS = [{
  ...lithophaneManifest('2026-11-03T00:00:00.000Z'),
  revision: 'generator-' + LITHOPHANE_GENERATOR_VERSION,
  files: [],
  description: 'Turn a photo into a lithophane: flat, curved, round, heart, cylinder, sphere or box.',
  thumbnail: '/gallery/lithophane.webp'
}];
let indexPromise = null;
const fileCache = new Map();

function loadBuiltIn() {
  if (!indexPromise) {
    indexPromise = fetch('/library/index.json')
      .then(response => {
        if (!response.ok) throw new Error(`The tool library could not be loaded (HTTP ${response.status}).`);
        return response.json();
      })
      .then(index => (Array.isArray(index?.tools) ? index.tools : []));
    indexPromise.catch(() => { indexPromise = null; });
  }
  return indexPromise;
}

export async function loadLibrary() {
  const builtIn = await loadBuiltIn();
  return [...GENERATOR_TOOLS, ...builtIn, ...sessionToolList()].map(withCustomParameters);
}

export async function getTool(toolId) {
  if (typeof toolId !== 'string' || !/^[\w-]+$/.test(toolId)) throw new Error('Invalid tool.');
  const tool = (await loadLibrary()).find(item => item.id === toolId);
  if (!tool) throw new Error('This tool is not in the library. Tools you import are kept only until the page is closed or reloaded.');
  return tool;
}

// All files of a tool as [{ path, data: ArrayBuffer }]; cached per tool revision.
export function toolFiles(tool) {
  if (isSessionTool(tool.id)) return Promise.resolve(sessionToolFiles(tool.id));
  const key = tool.id + '@' + tool.revision;
  if (!fileCache.has(key)) {
    const promise = Promise.all(tool.files.map(async file => {
      const url = `/library/${encodeURIComponent(tool.id)}/${file.path.split('/').map(encodeURIComponent).join('/')}`;
      const response = await fetch(url);
      if (!response.ok) throw new Error(`Could not load ${file.path} for ${tool.name} (HTTP ${response.status}).`);
      return { path: file.path, data: await response.arrayBuffer() };
    }));
    promise.catch(() => fileCache.delete(key));
    fileCache.set(key, promise);
  }
  return fileCache.get(key);
}

export async function toolSource(tool) {
  const files = await toolFiles(tool);
  const entry = files.find(file => file.path === tool.entry);
  return new TextDecoder().decode(entry.data);
}
