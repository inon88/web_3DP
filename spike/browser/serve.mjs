// Tiny static server for the M0 browser spike. Sends the security headers proposed in rancangan.md §7
// so we can verify WASM + module workers still run under them.
import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const APP = path.resolve(HERE, '..', '..', '..');
const ROUTES = [
  ['/openscad/', path.join(APP, 'vendor', 'openscad-wasm')],
  ['/examples/', path.join(APP, 'examples')],
  ['/fonts/', 'C:/Windows/Fonts'], // spike only; production bundles Liberation fonts
  ['/', HERE]
];
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.wasm': 'application/wasm', '.scad': 'text/plain', '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.json': 'application/json' };
const HEADERS = {
  'Content-Security-Policy': "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; worker-src 'self'; connect-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; require-trusted-types-for 'script'",
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Cross-Origin-Embedder-Policy': 'require-corp',
  'Cross-Origin-Resource-Policy': 'same-origin',
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'no-referrer',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=()'
};

const port = Number(process.env.PORT || 5178);
http.createServer(async (req, res) => {
  const url = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  if (url === '/list') {
    const names = (await fs.readdir(path.join(APP, 'examples'))).filter(n => n.endsWith('.scad'));
    res.writeHead(200, { ...HEADERS, 'Content-Type': 'application/json' });
    return res.end(JSON.stringify(names));
  }
  const [prefix, root] = ROUTES.find(([p]) => url.startsWith(p));
  const file = path.resolve(root, '.' + (url.slice(prefix.length - 1) === '/' ? '/index.html' : url.slice(prefix.length - 1)));
  if (!file.startsWith(path.resolve(root))) { res.writeHead(403); return res.end(); }
  try {
    const data = await fs.readFile(file);
    res.writeHead(200, { ...HEADERS, 'Content-Type': TYPES[path.extname(file).toLowerCase()] || 'application/octet-stream', 'Cache-Control': 'no-store' });
    res.end(data);
  } catch {
    res.writeHead(404, HEADERS); res.end('not found');
  }
}).listen(port, '127.0.0.1', () => console.log('spike server http://127.0.0.1:' + port));
