// Builds the read-only built-in library from the desktop app's examples:
//   public/library/<id>/<files>   and   public/library/index.json
// A top-level .scad becomes one tool with the files it references; a folder becomes one tool with
// all of its files (its main .scad is the one with the most parameters).
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { parseParameters, PARAMETER_PARSER_VERSION } from '../src/shared/parameters.js';
import { referencedAssetPaths } from '../src/shared/scad-assets.js';
import { scadDescription } from '../src/platform/describe.js';

const WEB = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const EXAMPLES = path.resolve(WEB, '..', 'examples');
const OUTPUT = path.join(WEB, 'public', 'library');
// Gallery pictures (scripts/gallery-thumbnails.mjs); kept outside public/library, which is rebuilt here.
const GALLERY = path.join(WEB, 'public', 'gallery');
const MAX_TOOL_BYTES = 20 * 1024 * 1024;
// Friendlier names for files whose names are terse; everything else is derived from the file name.
// Gallery text for files that start without a describing comment.
const DESCRIPTIONS = { 'bracket': 'L-shaped mounting bracket with optional screw holes.', 'pet-bowl': 'Pet bowl with a name and two icons on the front, raised or engraved.' };
const NAMES = { 'bracket': 'Mounting bracket', 'c_keycaps': 'Keycaps', 'c_hex_tray': 'Hex tray', 'c_tray_organizer': 'Tray organizer', 'C_keychain': 'Keychain', 'c_decorativeLatter': 'Decorative letter' };

const slug = text => text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const prettify = stem => NAMES[stem] || stem.replace(/[_-]+/g, ' ').replace(/([a-z])([A-Z])/g, '$1 $2').replace(/\b\w/g, c => c.toUpperCase()).trim();

async function listFiles(directory, base = '') {
  const files = [];
  for (const entry of await fs.readdir(directory, { withFileTypes: true })) {
    if (entry.name.startsWith('.')) continue;
    const relative = base ? base + '/' + entry.name : entry.name;
    if (entry.isDirectory()) files.push(...await listFiles(path.join(directory, entry.name), relative));
    else if (entry.isFile()) files.push(relative);
  }
  return files;
}

async function buildTool(id, name, sourceDirectory, entry, files) {
  const source = await fs.readFile(path.join(sourceDirectory, entry), 'utf8');
  const target = path.join(OUTPUT, id);
  await fs.mkdir(target, { recursive: true });
  let bytes = 0;
  const listed = [];
  const hash = crypto.createHash('sha256');
  for (const file of files.sort()) {
    const data = await fs.readFile(path.join(sourceDirectory, file));
    bytes += data.length;
    hash.update(file).update(data);
    await fs.mkdir(path.dirname(path.join(target, file)), { recursive: true });
    await fs.writeFile(path.join(target, file), data);
    listed.push({ path: file, bytes: data.length });
  }
  if (bytes > MAX_TOOL_BYTES) throw new Error(`${id} is larger than ${MAX_TOOL_BYTES / 1024 / 1024} MB.`);
  const thumbnail = await fs.access(path.join(GALLERY, id + '.webp')).then(() => `/gallery/${id}.webp`, () => '');
  return {
    id,
    name,
    category: 'Example',
    description: DESCRIPTIONS[id] || scadDescription(source),
    thumbnail,
    entry,
    builtIn: true,
    // Changes whenever any file changes; render caches key on it.
    revision: hash.digest('hex').slice(0, 16),
    parameters: parseParameters(source),
    parameterParserVersion: PARAMETER_PARSER_VERSION,
    files: listed
  };
}

await fs.rm(OUTPUT, { recursive: true, force: true });
await fs.mkdir(OUTPUT, { recursive: true });
const tools = [];
for (const entry of await fs.readdir(EXAMPLES, { withFileTypes: true })) {
  if (entry.isFile() && entry.name.endsWith('.scad')) {
    const stem = entry.name.slice(0, -5);
    const source = await fs.readFile(path.join(EXAMPLES, entry.name), 'utf8');
    const assets = referencedAssetPaths(source).filter(reference => !path.isAbsolute(reference) && !reference.includes('..'));
    tools.push(await buildTool(slug(stem), prettify(stem), EXAMPLES, entry.name, [entry.name, ...assets]));
  } else if (entry.isDirectory()) {
    const directory = path.join(EXAMPLES, entry.name);
    const files = await listFiles(directory);
    const scadFiles = files.filter(file => file.endsWith('.scad'));
    if (!scadFiles.length) continue;
    let main = scadFiles[0];
    let most = -1;
    for (const file of scadFiles) {
      const count = parseParameters(await fs.readFile(path.join(directory, file), 'utf8')).length;
      if (count > most) { most = count; main = file; }
    }
    tools.push(await buildTool(slug(entry.name), prettify(entry.name), directory, main, files.filter(file => !/\.md$/i.test(file))));
  }
}
tools.sort((a, b) => a.name.localeCompare(b.name));
await fs.writeFile(path.join(OUTPUT, 'index.json'), JSON.stringify({ version: 1, tools }, null, 1));
console.log(`library  ${tools.length} tools → public/library`);
