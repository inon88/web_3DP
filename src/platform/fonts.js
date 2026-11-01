// Fonts for the web version:
// - Liberation (public/fonts, SIL OFL), served from this site; metric-compatible with Arial/Times/Courier.
// - Google Fonts, loaded by link from fonts.gstatic.com only when chosen (google-fonts.json, built by
//   scripts/google-fonts.mjs). Each file is checked against its pinned SHA-256 (SRI), then turned into a
//   TTF OpenSCAD can read (src/shared/woff.js).
// Common proprietary fonts are aliased, so tools written on Windows keep working.
import { fetchAsset, FONT_DIR } from './assets.js';
import googleFonts from './google-fonts.json' with { type: 'json' };
import { fontForOpenScad } from '../shared/woff.js';

export const GOOGLE_FONT_ORIGIN = 'https://fonts.gstatic.com';

const FAMILIES = [['Liberation Sans', 'LiberationSans'], ['Liberation Serif', 'LiberationSerif'], ['Liberation Mono', 'LiberationMono']];
const STYLES = [['Regular', 'Regular', 400, false], ['Bold', 'Bold', 700, false], ['Italic', 'Italic', 400, true], ['Bold Italic', 'BoldItalic', 700, true]];

const LIBERATION_FONTS = FAMILIES.flatMap(([family, file]) => STYLES.map(([style, suffix, weight, italic]) => ({
  name: `${family}:style=${style}`,
  family,
  style,
  weight,
  italic,
  source: 'bundled',
  filePath: `${FONT_DIR}/${file}-${suffix}.ttf`
})));

const GOOGLE_FONTS = googleFonts.fonts
  .filter(font => font.url?.startsWith(GOOGLE_FONT_ORIGIN + '/') && /^sha256-/.test(font.integrity))
  .map(({ name, family, style, weight, italic, category, url, integrity }) => ({ name, family, style, weight, italic, category, source: 'google', url, integrity }));

export const BUNDLED_FONTS = [...LIBERATION_FONTS, ...GOOGLE_FONTS]
  .sort((a, b) => a.family.localeCompare(b.family) || a.weight - b.weight || Number(a.italic) - Number(b.italic));

const FAMILY_ALIASES = new Map([
  ['arial', 'Liberation Sans'], ['helvetica', 'Liberation Sans'], ['segoe ui', 'Liberation Sans'],
  ['calibri', 'Liberation Sans'], ['verdana', 'Liberation Sans'], ['tahoma', 'Liberation Sans'],
  ['times new roman', 'Liberation Serif'], ['times', 'Liberation Serif'], ['georgia', 'Liberation Serif'], ['cambria', 'Liberation Serif'],
  ['courier new', 'Liberation Mono'], ['courier', 'Liberation Mono'], ['consolas', 'Liberation Mono'],
  // Closest free look-alikes from Google Fonts.
  ['segoe script', 'Dancing Script'], ['brush script mt', 'Dancing Script'], ['lucida handwriting', 'Dancing Script'],
  ['comic sans ms', 'Comic Neue'], ['impact', 'Anton'], ['segoe ui black', 'Archivo Black']
]);

const familyOf = name => BUNDLED_FONTS.find(font => font.family.toLowerCase() === name)?.family;

// "Arial:style=Bold" → "Liberation Sans:style=Bold", "Roboto:style=Regular" → "Roboto";
// a style the family lacks falls back to Bold/Regular, then to any style. Unknown names return null.
export function resolveFontAlias(name) {
  if (typeof name !== 'string') return null;
  const exact = BUNDLED_FONTS.find(font => font.name.toLowerCase() === name.toLowerCase());
  if (exact) return exact.name;
  const [familyPart, stylePart = 'style=Regular'] = name.split(':');
  const key = familyPart.trim().toLowerCase();
  const family = familyOf(key) || FAMILY_ALIASES.get(key);
  if (!family) return null;
  const style = stylePart.replace(/^style=/i, '').trim().toLowerCase();
  const faces = BUNDLED_FONTS.filter(font => font.family === family);
  const match = faces.find(font => font.style.toLowerCase() === style)
    || faces.find(font => font.style === (/bold|black|heavy/.test(style) ? 'Bold' : 'Regular'))
    || (/bold|black|heavy/.test(style) ? [...faces].sort((a, b) => b.weight - a.weight)[0] : [...faces].sort((a, b) => a.weight - b.weight)[0]);
  return match?.name || null;
}

export function findFont(name) {
  const resolved = resolveFontAlias(name);
  return resolved ? BUNDLED_FONTS.find(font => font.name === resolved) : null;
}

async function download(font) {
  const response = font.source === 'google'
    ? await fetch(font.url, { integrity: font.integrity, mode: 'cors', credentials: 'omit', referrerPolicy: 'no-referrer' })
    : await fetchAsset(font.filePath);
  if (!response.ok) throw new Error(`Could not load the font ${font.family} (HTTP ${response.status}).`);
  const bytes = new Uint8Array(await response.arrayBuffer());
  return font.source === 'google' ? fontForOpenScad(bytes).buffer : bytes.buffer;
}

const cache = new Map();
// TTF bytes for OpenSCAD (and for the font preview).
export function fontData(font) {
  if (!cache.has(font.name)) {
    const promise = download(font).catch(error => {
      cache.delete(font.name);
      throw error instanceof TypeError
        ? new Error(`Could not load the font ${font.family}. Check the internet connection and try again.`)
        : error;
    });
    cache.set(font.name, promise);
  }
  return cache.get(font.name);
}
