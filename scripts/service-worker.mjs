// Vite plugin: after the build, writes dist/sw.js from service-worker.template.js with the list of files
// to keep offline and a version that changes whenever any of them changes (rancangan.md §16).
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';

const TEMPLATE = new URL('./service-worker.template.js', import.meta.url);

// Paths (relative to dist, "/"-separated) → the URLs installed up front. index.html is served as "/";
// fonts and the tracer are cached on first use instead (4.8 MB that many visits never need).
export function precacheEntries(files) {
  const urls = files
    .filter(file => !/(^|\/)\./.test(file))
    .filter(file => file !== 'sw.js' && file !== 'index.html' && !file.endsWith('.map'))
    .filter(file => !/^(?:fonts|vtracer)\//.test(file))
    // As the browser writes them in request URLs (url.pathname), so the worker can match them directly.
    .map(file => '/' + file.split('/').map(encodeURIComponent).join('/'))
    .sort();
  return ['/', ...urls];
}

async function listFiles(directory, base = '') {
  const out = [];
  for (const entry of await fs.readdir(directory, { withFileTypes: true })) {
    const relative = base ? `${base}/${entry.name}` : entry.name;
    if (entry.isDirectory()) out.push(...await listFiles(path.join(directory, entry.name), relative));
    else if (entry.isFile()) out.push(relative);
  }
  return out;
}

export async function writeServiceWorker(outDir) {
  const files = await listFiles(outDir);
  const precache = precacheEntries(files);
  const hash = crypto.createHash('sha256');
  for (const url of precache) {
    const file = url === '/' ? 'index.html' : decodeURIComponent(url.slice(1));
    hash.update(url).update(await fs.readFile(path.join(outDir, file)));
  }
  const template = await fs.readFile(TEMPLATE, 'utf8');
  const version = hash.digest('hex').slice(0, 12);
  const fill = (text, line, value) => {
    if (!text.includes(line)) throw new Error(`service-worker.template.js no longer contains "${line}".`);
    return text.replace(line, () => line.replace(/__\w+__/, value));
  };
  let source = fill(template, 'const VERSION = __VERSION__;', JSON.stringify(version));
  source = fill(source, 'const PRECACHE = __PRECACHE__;', JSON.stringify(precache, null, 1));
  await fs.writeFile(path.join(outDir, 'sw.js'), source);
  return { version, count: precache.length };
}

export function serviceWorker() {
  let outDir = '';
  return {
    name: 'bonastudio-service-worker',
    apply: 'build',
    configResolved(config) {
      outDir = path.resolve(config.root, config.build.outDir);
    },
    async closeBundle() {
      const { version, count } = await writeServiceWorker(outDir);
      console.log(`service worker  ${count} files precached · version ${version}`);
    }
  };
}
