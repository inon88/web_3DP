// Builds src/platform/google-fonts.json: Google Fonts the web app loads by link from fonts.gstatic.com
// (nothing is copied into this project or onto Vercel). Run when FAMILIES changes:  npm run google-fonts
//
// Why WOFF and an old Windows user agent: that client gets plain WOFF 1.0 (zlib), which the app turns
// into TTF in the browser (src/shared/woff.js), and hinted files where Google still has them. OpenSCAD
// cannot read WOFF2. Unhinted fonts get a no-op font program at load time (makeOpenScadCompatible).
//
// Each entry pins the file's SHA-256 (SRI), so a changed file at the same URL is rejected at runtime.
// Entries already in the JSON are kept as they are; only new families/weights are fetched.
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { woffToSfnt, fontForOpenScad } from '../src/shared/woff.js';
import { fontFamiliesFromArrayBuffer, fontSupportsOpenScadWasm } from '../src/shared/font-name.js';

const WEB = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const OUTPUT = path.join(WEB, 'src', 'platform', 'google-fonts.json');
const LEGACY_WINDOWS_UA = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.100 Safari/534.30';

// [family, weights, category] — chosen for 3D printing: bold, legible strokes; scripts that stay connected.
const FAMILIES = [
  ['Roboto', [400, 700, 900], 'Sans'],
  ['Open Sans', [400, 700, 800], 'Sans'],
  ['Montserrat', [400, 700, 900], 'Sans'],
  ['Poppins', [400, 700, 900], 'Sans'],
  ['Nunito', [400, 800], 'Sans'],
  ['Rubik', [400, 700], 'Sans'],
  ['Oswald', [400, 700], 'Sans'],
  ['Comic Neue', [400, 700], 'Sans'],
  ['Bebas Neue', [400], 'Display'],
  ['Anton', [400], 'Display'],
  ['Archivo Black', [400], 'Display'],
  ['Russo One', [400], 'Display'],
  ['Bungee', [400], 'Display'],
  ['Righteous', [400], 'Display'],
  ['Lobster', [400], 'Display'],
  ['Bangers', [400], 'Display'],
  ['Luckiest Guy', [400], 'Display'],
  ['Titan One', [400], 'Display'],
  ['Fredoka', [400, 700], 'Display'],
  ['Black Ops One', [400], 'Display'],
  ['Alfa Slab One', [400], 'Display'],
  ['Abril Fatface', [400], 'Display'],
  ['Saira Stencil One', [400], 'Stencil'],
  ['Stardos Stencil', [400, 700], 'Stencil'],
  ['Allerta Stencil', [400], 'Stencil'],
  ['Dancing Script', [400, 700], 'Script'],
  ['Pacifico', [400], 'Script'],
  ['Great Vibes', [400], 'Script'],
  ['Satisfy', [400], 'Script'],
  ['Kaushan Script', [400], 'Script'],
  ['Sacramento', [400], 'Script'],
  ['Allura', [400], 'Script'],
  ['Caveat', [400, 700], 'Script'],
  ['Cookie', [400], 'Script'],
  ['Yellowtail', [400], 'Script'],
  ['Permanent Marker', [400], 'Script'],
  ['Playfair Display', [400, 700, 900], 'Serif'],
  ['Merriweather', [400, 700, 900], 'Serif'],
  ['Roboto Slab', [400, 700], 'Serif'],
  ['Roboto Mono', [400, 700], 'Mono']
];

const sha256 = data => crypto.createHash('sha256').update(data).digest();
const read = async file => { try { return JSON.parse(await fs.readFile(file, 'utf8')); } catch { return { fonts: [] }; } };

async function faces(family, weights) {
  const query = `family=${encodeURIComponent(family).replace(/%20/g, '+')}:wght@${weights.join(';')}`;
  const response = await fetch(`https://fonts.googleapis.com/css2?${query}`, { headers: { 'user-agent': LEGACY_WINDOWS_UA } });
  if (!response.ok) throw new Error(`${family}: Google Fonts CSS HTTP ${response.status}`);
  const css = await response.text();
  return [...css.matchAll(/@font-face\s*{([^}]+)}/g)].map(([, body]) => ({
    weight: Number(body.match(/font-weight:\s*(\d+)/)?.[1]),
    italic: /font-style:\s*italic/.test(body),
    url: body.match(/url\((https:\/\/fonts\.gstatic\.com\/[^)]+\.woff)\)/)?.[1]
  }));
}

const previous = await read(OUTPUT);
const known = new Map(previous.fonts.map(font => [`${font.family}|${font.weight}|${font.italic}`, font]));
const fonts = [];
const rejected = [];
for (const [family, weights, category] of FAMILIES) {
  const missing = weights.filter(weight => !known.has(`${family}|${weight}|false`));
  const fetched = missing.length ? await faces(family, missing) : [];
  for (const weight of weights) {
    const key = `${family}|${weight}|false`;
    if (known.has(key)) { fonts.push({ ...known.get(key), category }); continue; }
    const face = fetched.find(item => item.weight === weight && !item.italic);
    if (!face?.url) { rejected.push(`${family} ${weight}: no WOFF offered`); continue; }
    const response = await fetch(face.url);
    if (!response.ok) throw new Error(`${face.url}: HTTP ${response.status}`);
    const woff = new Uint8Array(await response.arrayBuffer());
    const hinted = fontSupportsOpenScadWasm(woffToSfnt(woff));
    const ttf = fontForOpenScad(woff); // unhinted fonts get the no-op font program (src/shared/woff.js)
    const [name] = fontFamiliesFromArrayBuffer(ttf.buffer);
    if (!name) { rejected.push(`${family} ${weight}: no font name`); continue; }
    const separator = name.indexOf(':style=');
    fonts.push({
      name,
      family: separator < 0 ? name : name.slice(0, separator),
      style: separator < 0 ? 'Regular' : name.slice(separator + 7),
      weight,
      italic: false,
      category,
      hinted,
      url: face.url,
      integrity: 'sha256-' + sha256(woff).toString('base64'),
      bytes: woff.length
    });
    console.log('added  ', name.padEnd(36), (woff.length / 1024).toFixed(0) + ' KB');
  }
}

const names = new Set();
for (const font of fonts) {
  if (names.has(font.name.toLowerCase())) throw new Error('Duplicate font name ' + font.name);
  names.add(font.name.toLowerCase());
}
fonts.sort((a, b) => a.family.localeCompare(b.family) || a.weight - b.weight);
await fs.writeFile(OUTPUT, JSON.stringify({
  source: 'Google Fonts (fonts.gstatic.com), SIL Open Font License 1.1 / Apache License 2.0. Generated by scripts/google-fonts.mjs.',
  fonts
}, null, 1) + '\n');
console.log(`${fonts.length} fonts, ${(fonts.reduce((sum, font) => sum + font.bytes, 0) / 1024 / 1024).toFixed(1)} MB in total (each loads only when chosen)`);
if (rejected.length) console.log('skipped:\n  ' + rejected.join('\n  '));
