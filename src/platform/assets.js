// Heavy static assets (OpenSCAD WASM, fonts) live under versioned paths in public/ and are served by the
// host's CDN (Vercel) with immutable caching. VITE_ASSET_BASE can point them at another CDN instead.
// Every fetch carries the SRI hash from asset-manifest.json (written by scripts/fetch-assets.mjs),
// so no CDN or cache in between can substitute a file unnoticed.
import manifest from './asset-manifest.json' with { type: 'json' };

const configured = import.meta.env?.VITE_ASSET_BASE || '/';
export const ASSET_BASE = configured.endsWith('/') ? configured : configured + '/';
export const WASM_PATH = manifest.wasm;
export const FONT_DIR = manifest.fontDir;
export const VTRACER_PATH = manifest.vtracer;

export function assetUrl(path) {
  return ASSET_BASE + path;
}

export function fetchAsset(path) {
  const integrity = manifest.integrity[path];
  if (!integrity) throw new Error('Unknown asset: ' + path);
  return fetch(assetUrl(path), { integrity, mode: 'cors', credentials: 'omit' });
}
