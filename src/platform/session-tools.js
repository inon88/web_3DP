// Tools people import in the web version (SCAD file, project folder, link) and custom parameters they add.
// Like the images in session-files.js, everything lives only in this tab's memory: nothing is written to the
// browser or sent to a server, and reloading the page forgets it. Ported from the desktop main.cjs handlers
// tools:import-file, tools:import-project, tools:import-url, tools:delete and tools:add-parameter.
import { parseParameters, PARAMETER_PARSER_VERSION } from '../shared/parameters.js';
import { referencedAssetPaths } from '../shared/scad-assets.js';
import { scadDescription } from './describe.js';

export const IMPORT_LIMITS = Object.freeze({
  scadBytes: 10 * 1024 * 1024,
  projectBytes: 150 * 1024 * 1024,
  projectFiles: 5000,
  // All imported tools together; the tab keeps them in memory.
  sessionBytes: 300 * 1024 * 1024,
  urlTimeoutMs: 15000
});

const tools = new Map(); // id → { manifest, files: [{ path, data: ArrayBuffer }] }
const customParameters = new Map(); // toolId → manual parameters added in this session
let sessionBytes = 0;

export function sanitizeName(name) {
  return String(name || 'model').replace(/[<>:"/\\|?*\x00-\x1f]/g, '-').trim().slice(0, 80) || 'model';
}

const stem = fileName => String(fileName || '').replace(/^.*[\\/]/, '').replace(/\.scad$/i, '');
const decode = data => new TextDecoder().decode(data);

export function isSessionTool(toolId) {
  return tools.has(toolId);
}

export function sessionToolList() {
  return [...tools.values()].map(tool => tool.manifest);
}

export function sessionToolFiles(toolId) {
  const tool = tools.get(toolId);
  if (!tool) throw new Error('This tool is no longer available: tools you import are kept only until the page is closed or reloaded.');
  return tool.files;
}

// A built-in or imported tool with the custom parameters added to it in this session.
export function withCustomParameters(tool) {
  const extra = customParameters.get(tool.id);
  return extra?.length ? { ...tool, parameters: [...(tool.parameters || []), ...extra] } : tool;
}

function addTool({ name, category, entry, files, sourceUrl = '' }) {
  const entryFile = files.find(file => file.path === entry);
  if (!entryFile) throw new Error('The main SCAD file is missing.');
  if (entryFile.data.byteLength > IMPORT_LIMITS.scadBytes) throw new Error('The main SCAD file exceeds the 10 MB size limit.');
  const source = decode(entryFile.data);
  if (!source.trim()) throw new Error('The SCAD file is empty.');
  const bytes = files.reduce((sum, file) => sum + file.data.byteLength, 0);
  if (sessionBytes + bytes > IMPORT_LIMITS.sessionBytes) {
    throw new Error('Too many tools were imported in this session. Delete some imported tools or reload the page to start fresh.');
  }
  const id = crypto.randomUUID();
  const manifest = {
    id,
    name: sanitizeName(name),
    category,
    entry,
    sourceUrl,
    description: scadDescription(source),
    session: true,
    // Imported files never change, so one revision per import keeps the render cache correct.
    revision: 'session-' + id,
    parameters: parseParameters(source),
    parameterParserVersion: PARAMETER_PARSER_VERSION,
    createdAt: new Date().toISOString(),
    files: files.map(file => ({ path: file.path, bytes: file.data.byteLength }))
  };
  tools.set(id, { manifest, files });
  sessionBytes += bytes;
  return manifest;
}

// file: a File (or anything with name, size and arrayBuffer()).
export async function importScadFile(file) {
  if (!file || !/\.scad$/i.test(file.name || '')) throw new Error('Choose an OpenSCAD file (.scad).');
  if (file.size > IMPORT_LIMITS.scadBytes) throw new Error('The SCAD file exceeds the 10 MB size limit.');
  const data = await file.arrayBuffer();
  return addTool({ name: stem(file.name), category: 'Imported', entry: 'model.scad', files: [{ path: 'model.scad', data }] });
}

// ---- Project folders ----

// entries: [{ path: 'Folder/sub/file.scad', file }] — from <input webkitdirectory> (webkitRelativePath) or a
// dropped folder. Skips dotfiles, .git and node_modules like the desktop copy, and enforces its limits.
// Returns { name, files: [{ path (relative to the folder), data }], scadFiles: [{ path, parameters }] }.
export async function readProjectFolder(entries) {
  const list = [...entries].map(entry => ({ file: entry.file, segments: String(entry.path || entry.file?.name || '').split('/').filter(Boolean) }));
  const roots = new Set(list.map(entry => entry.segments[0]));
  const name = roots.size === 1 && list.every(entry => entry.segments.length > 1) ? [...roots][0] : 'Project';
  const files = [];
  let bytes = 0;
  for (const { file, segments } of list) {
    const inner = name === 'Project' ? segments : segments.slice(1);
    if (!inner.length || inner.some(segment => segment.startsWith('.') || segment === 'node_modules' || segment === '..')) continue;
    bytes += file.size;
    if (bytes > IMPORT_LIMITS.projectBytes || files.length + 1 > IMPORT_LIMITS.projectFiles) {
      throw new Error('The project folder is too large (maximum 150 MB and 5,000 files).');
    }
    files.push({ path: inner.join('/'), file });
  }
  const read = await Promise.all(files.map(async ({ path, file }) => ({ path, data: await file.arrayBuffer() })));
  read.sort((left, right) => left.path.localeCompare(right.path));
  const scadFiles = read.filter(file => /\.scad$/i.test(file.path)).map(file => ({
    path: file.path,
    parameters: file.data.byteLength <= IMPORT_LIMITS.scadBytes ? parseParameters(decode(file.data)).length : 0
  }));
  if (!scadFiles.length) throw new Error('The folder has no .scad file.');
  return { name, files: read, scadFiles };
}

// The likely main file: the one with the most parameters (as scripts/build-library.mjs picks it),
// preferring files at the top of the folder.
export function suggestEntry(project) {
  const depth = path => path.split('/').length;
  return [...project.scadFiles].sort((a, b) => b.parameters - a.parameters || depth(a.path) - depth(b.path) || a.path.localeCompare(b.path))[0].path;
}

export function importProject(project, entry) {
  if (!project.scadFiles.some(file => file.path === entry)) throw new Error('The main SCAD file must be inside the selected project folder.');
  // The same layout as the desktop library: tools/<id>/project/<relative path>.
  return addTool({
    name: project.name,
    category: 'Project',
    entry: 'project/' + entry,
    files: project.files.map(file => ({ path: 'project/' + file.path, data: file.data }))
  });
}

// ---- Links ----

function isPrivateIpv4(host) {
  const parts = host.split('.');
  if (parts.length !== 4 || parts.some(part => !/^\d{1,3}$/.test(part) || Number(part) > 255)) return false;
  const [a, b, c] = parts.map(Number);
  return a === 0 || a === 10 || a === 127 || a >= 224
    || (a === 100 && b >= 64 && b <= 127)
    || (a === 169 && b === 254)
    || (a === 172 && b >= 16 && b <= 31)
    || (a === 192 && (b === 168 || (b === 0 && c === 0) || (b === 88 && c === 99)))
    || (a === 198 && (b === 18 || b === 19 || b === 51))
    || (a === 203 && b === 0 && c === 113);
}

// Checks a link like the desktop does (HTTPS, no credentials, no local hosts, a .scad file) and turns a
// GitHub/GitLab/Codeberg file page into its raw-file address, which allows cross-site downloads.
export function normalizeImportUrl(text) {
  let url;
  try {
    url = new URL(String(text || '').trim());
  } catch {
    throw new Error('Invalid URL.');
  }
  if (url.username || url.password) throw new Error('The URL must not include a username or password.');
  if (url.protocol !== 'https:') throw new Error('URL imports support HTTPS only.');
  const host = url.hostname.toLowerCase().replace(/^\[|\]$/g, '');
  if (host === 'localhost' || host.endsWith('.localhost') || host.endsWith('.local') || isPrivateIpv4(host)
    || host.includes(':')) {
    throw new Error('Local addresses cannot be used as import sources.');
  }
  const github = host === 'github.com' && url.pathname.match(/^\/([^/]+)\/([^/]+)\/(?:blob|raw)\/(.+)$/);
  if (github) url = new URL(`https://raw.githubusercontent.com/${github[1]}/${github[2]}/${github[3]}`);
  const gitlab = (host === 'gitlab.com' || host === 'codeberg.org') && url.pathname.match(/^(\/.+?)\/(?:-\/)?(?:blob|src\/branch|src\/commit)\/(.+)$/);
  if (gitlab) url = new URL(host === 'gitlab.com' ? `https://gitlab.com${gitlab[1]}/-/raw/${gitlab[2]}` : `https://codeberg.org${gitlab[1]}/raw/branch/${gitlab[2]}`);
  url.hash = '';
  if (!url.pathname.toLowerCase().endsWith('.scad')) throw new Error('The URL must point directly to a .scad file.');
  return url;
}

export async function importUrl(text, fetchImpl = globalThis.fetch) {
  const url = normalizeImportUrl(text);
  let response;
  try {
    response = await fetchImpl(url.href, {
      credentials: 'omit',
      referrerPolicy: 'no-referrer',
      redirect: 'follow',
      signal: AbortSignal.timeout(IMPORT_LIMITS.urlTimeoutMs)
    });
  } catch (error) {
    if (error?.name === 'TimeoutError' || error?.name === 'AbortError') throw new Error('The download took longer than 15 seconds.');
    // Browsers report a blocked cross-site download (no CORS headers) as a plain network error.
    throw new Error('The file could not be downloaded. The site may not allow downloads from other websites; download the .scad file and add it with "SCAD file" instead.');
  }
  if (!response.ok) throw new Error(`Download failed: HTTP ${response.status}.`);
  if (response.url && !response.url.startsWith('https:')) throw new Error('The link redirected to a non-HTTPS address.');
  const declared = Number(response.headers.get('content-length'));
  if (declared > IMPORT_LIMITS.scadBytes) throw new Error('The file exceeds the 10 MB size limit.');
  const chunks = [];
  let total = 0;
  if (response.body?.getReader) {
    const reader = response.body.getReader();
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      total += value.byteLength;
      if (total > IMPORT_LIMITS.scadBytes) {
        reader.cancel().catch(() => {});
        throw new Error('The file exceeds the 10 MB size limit.');
      }
      chunks.push(value);
    }
  } else {
    const whole = new Uint8Array(await response.arrayBuffer());
    total = whole.byteLength;
    if (total > IMPORT_LIMITS.scadBytes) throw new Error('The file exceeds the 10 MB size limit.');
    chunks.push(whole);
  }
  const data = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) { data.set(chunk, offset); offset += chunk.byteLength; }
  if (/^\s*<(?:!doctype|html)/i.test(decode(data.subarray(0, 512)))) {
    throw new Error('The link opened a web page, not a .scad file. Use the link to the raw file.');
  }
  return addTool({ name: stem(decodeURIComponent(url.pathname)), category: 'Imported', entry: 'model.scad', files: [{ path: 'model.scad', data: data.buffer }], sourceUrl: url.href });
}

// ---- Delete and custom parameters ----

export function deleteSessionTool(toolId) {
  const tool = tools.get(toolId);
  if (!tool) return false;
  sessionBytes -= tool.files.reduce((sum, file) => sum + file.data.byteLength, 0);
  tools.delete(toolId);
  customParameters.delete(toolId);
  return true;
}

export function addCustomParameter(tool, parameter) {
  if (!parameter || typeof parameter.name !== 'string' || !/^[A-Za-z_]\w*$/.test(parameter.name)) {
    throw new Error('Parameter names may contain only letters, numbers, and underscores, and cannot start with a number.');
  }
  if (tool.kind === 'generator') throw new Error('Generator tools have a fixed set of parameters.');
  if ((withCustomParameters(tool).parameters || []).some(item => item.name === parameter.name)) {
    throw new Error(`Parameter "${parameter.name}" already exists.`);
  }
  const value = parameter.type === 'boolean' ? Boolean(parameter.default) : Number(parameter.default);
  if (parameter.type !== 'boolean' && !Number.isFinite(value)) throw new Error('The default numeric value is invalid.');
  const list = customParameters.get(tool.id) || [];
  list.push({
    name: parameter.name,
    label: String(parameter.label || parameter.name).slice(0, 80),
    type: parameter.type === 'boolean' ? 'boolean' : 'number',
    default: value,
    group: 'Custom parameters',
    description: 'Manual parameter',
    source: 'manual'
  });
  customParameters.set(tool.id, list);
}

// ---- Files a model refers to ----

// "a/b/../c.png" relative to the entry file's folder → a path inside the tool, or null when it leaves it.
export function resolveToolPath(entry, reference) {
  const segments = entry.split('/').slice(0, -1);
  for (const part of reference.replace(/\\/g, '/').split('/')) {
    if (!part || part === '.') continue;
    if (part === '..') {
      if (!segments.length) return null;
      segments.pop();
    } else segments.push(part);
  }
  return segments.join('/');
}

// Files used through import()/surface() that the tool does not have (desktop: findMissingReferencedAssets).
export function missingReferencedFiles(tool, source) {
  const present = new Set((tool.files || []).map(file => file.path));
  return referencedAssetPaths(source)
    .filter(reference => !/^(?:[a-z]:)?[\\/]/i.test(reference))
    .filter(reference => {
      const resolved = resolveToolPath(tool.entry, reference);
      return resolved === null || !present.has(resolved);
    });
}
