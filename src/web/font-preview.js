// The font pickers preview text in the chosen font by CSS family name. On the web those fonts are not
// installed, so the chosen font is registered as a FontFace from the same verified bytes OpenSCAD gets.
// Only selected fonts are loaded (never the whole list), so opening the picker costs nothing.
import { BUNDLED_FONTS, fontData } from '../platform/fonts.js';

const registered = new Set();

async function register(name) {
  const font = BUNDLED_FONTS.find(item => item.name === name);
  if (!font || registered.has(name) || typeof FontFace !== 'function') return;
  registered.add(name);
  try {
    const data = await fontData(font);
    const face = new FontFace(font.family, data.slice(0), { weight: String(font.weight), style: font.italic ? 'italic' : 'normal' });
    document.fonts.add(await face.load());
  } catch {
    registered.delete(name); // The render reports load errors; the preview just keeps its fallback font.
  }
}

const scan = root => root.querySelectorAll?.('select.font-select').forEach(select => register(select.value));

export function startFontPreview(root = document.body) {
  scan(root);
  new MutationObserver(() => scan(root)).observe(root, { childList: true, subtree: true });
  root.addEventListener('change', event => {
    if (event.target.matches?.('select.font-select')) register(event.target.value);
  });
}
