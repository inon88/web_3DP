// Files and folders dropped onto the window → [{ path, file }], the shape window.formforge.importDropped
// takes. A folder keeps its own name as the first path segment ("Folder/sub/file.scad"), like
// <input webkitdirectory>. Entries must be read during the drop event, before the browser clears them.
const MAX_ENTRIES = 5000;

const readFile = entry => new Promise((resolve, reject) => entry.file(resolve, reject));

async function readDirectory(directory) {
  const reader = directory.createReader();
  const children = [];
  // readEntries returns at most ~100 entries per call; keep calling until it returns none.
  for (;;) {
    const batch = await new Promise((resolve, reject) => reader.readEntries(resolve, reject));
    if (!batch.length) return children;
    children.push(...batch);
    if (children.length > MAX_ENTRIES) return children;
  }
}

async function walk(entry, prefix, out) {
  if (out.length > MAX_ENTRIES) throw new Error('The project folder is too large (maximum 150 MB and 5,000 files).');
  const path = prefix ? `${prefix}/${entry.name}` : entry.name;
  if (entry.isFile) out.push({ path, file: await readFile(entry) });
  else if (entry.isDirectory && !entry.name.startsWith('.') && entry.name !== 'node_modules') {
    for (const child of await readDirectory(entry)) await walk(child, path, out);
  }
}

export function hasDroppedFiles(event) {
  return [...(event.dataTransfer?.types || [])].includes('Files');
}

export async function droppedEntries(dataTransfer) {
  const entries = [...(dataTransfer?.items || [])]
    .filter(item => item.kind === 'file')
    .map(item => item.webkitGetAsEntry?.())
    .filter(Boolean);
  if (!entries.length) return [...(dataTransfer?.files || [])].map(file => ({ path: file.name, file }));
  const out = [];
  for (const entry of entries) await walk(entry, '', out);
  return out;
}
