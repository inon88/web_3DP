// Files people add in the web version live only in this tab's memory: nothing is written to the
// browser (no IndexedDB/localStorage) or sent to a server. Closing or reloading the page forgets them.
// - Tool assets: icons, traced images and relief heightmaps, referenced from parameters as
//   "user-assets/<uuid>.svg|png" (the same references the desktop app writes into the tool folder).
// - Icon packs: chosen folders of SVG files. Only the File handles are kept; an icon is read when shown.

const MAX_ASSET_BYTES = 200 * 1024 * 1024;
const ICON_LIMITS = Object.freeze({ maxIcons: 50000, maxDepth: 8, maxBytes: 1024 * 1024 });
export const LOOSE_PACK = '';
export const USER_ASSET_PATTERN = /user-assets\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(?:svg|png)/g;

const toolAssets = new Map(); // toolId → Map(reference → Uint8Array)
let assetBytes = 0;

export function addToolAsset(toolId, extension, bytes) {
  if (!['.svg', '.png'].includes(extension)) throw new Error('Unsupported asset type.');
  if (assetBytes + bytes.length > MAX_ASSET_BYTES) {
    throw new Error('Too many images were added in this session. Reload the page to start fresh.');
  }
  const reference = `user-assets/${crypto.randomUUID()}${extension}`;
  if (!toolAssets.has(toolId)) toolAssets.set(toolId, new Map());
  toolAssets.get(toolId).set(reference, bytes);
  assetBytes += bytes.length;
  return reference;
}

// Every user-assets reference inside the values (strings, nested trees), as files for the render.
export function referencedToolAssets(toolId, values) {
  const references = new Set(JSON.stringify(values ?? null).match(USER_ASSET_PATTERN) || []);
  const assets = toolAssets.get(toolId);
  const missing = [...references].filter(reference => !assets?.has(reference));
  if (missing.length) {
    throw new Error('An image used by this tool is no longer available: images you add are kept only until the page is closed or reloaded. Choose the image again.');
  }
  return [...references].map(reference => ({ path: reference, data: assets.get(reference) }));
}

// ---- Icon packs ----
const packs = new Map(); // pack name → Map(relative path → File)

const iconName = fileName => fileName.replace(/\.svg$/i, '').replace(/[-_.]+/g, ' ').trim();
const byName = (left, right) => left.name.localeCompare(right.name, undefined, { numeric: true, sensitivity: 'base' });

// files: File objects from <input type="file" webkitdirectory> (webkitRelativePath "Pack/sub/icon.svg")
// or plain files (loose icons). Returns the number of SVG files added.
export function addIconFiles(files) {
  let added = 0;
  let total = [...packs.values()].reduce((sum, pack) => sum + pack.size, 0);
  for (const file of files) {
    if (total >= ICON_LIMITS.maxIcons) break;
    const segments = (file.webkitRelativePath || file.name).split('/').filter(Boolean);
    if (!/\.svg$/i.test(file.name) || segments.some(segment => segment.startsWith('.') || segment === '..')) continue;
    // A chosen folder that holds packs ("Icons/Pack/x.svg") keeps the packs; a pack folder itself becomes one pack.
    let pack = LOOSE_PACK;
    let inner = segments;
    if (segments.length >= 3) { pack = segments[1]; inner = segments.slice(2); } else if (segments.length === 2) { pack = segments[0]; inner = segments.slice(1); }
    if (inner.length > ICON_LIMITS.maxDepth + 1) continue;
    if (!packs.has(pack)) packs.set(pack, new Map());
    const path = inner.join('/');
    if (!packs.get(pack).has(path)) { total++; added++; }
    packs.get(pack).set(path, file);
  }
  return added;
}

export function iconIndex() {
  const icons = [];
  for (const [pack, files] of packs) {
    for (const [path, file] of files) icons.push({ pack, path, name: iconName(file.name) });
  }
  const order = [...packs.keys()].sort((a, b) => a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' }));
  icons.sort((a, b) => order.indexOf(a.pack) - order.indexOf(b.pack) || a.path.localeCompare(b.path, undefined, { numeric: true, sensitivity: 'base' }));
  return {
    root: '',
    packs: order.map(name => ({ name, count: packs.get(name).size })).sort(byName),
    icons,
    truncated: icons.length >= ICON_LIMITS.maxIcons
  };
}

export async function readIcon(pack, path) {
  const file = typeof pack === 'string' && typeof path === 'string' ? packs.get(pack)?.get(path) : null;
  if (!file) throw new Error('That icon is not in the icon library.');
  if (file.size > ICON_LIMITS.maxBytes) throw new Error('That icon file is larger than 1 MB.');
  const svg = await file.text();
  if (!/<svg(?:\s|>)/i.test(svg)) throw new Error('That file is not an SVG image.');
  return svg;
}
