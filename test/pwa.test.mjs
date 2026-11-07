// Offline support: the service worker generated at build time, the web app manifest and their headers.
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { readFileSync, existsSync } from 'node:fs';
import { precacheEntries, writeServiceWorker } from '../scripts/service-worker.mjs';

test('the precache list holds the app shell, library and engine, not fonts, tracer or the worker itself', () => {
  const entries = precacheEntries([
    'index.html', 'sw.js', 'manifest.webmanifest', 'assets/index-AbCdEf12.js', 'assets/index-AbCdEf12.js.map',
    'library/index.json', 'library/pet-bowl/my icon.svg', 'openscad/2026.10.11/openscad.wasm',
    'fonts/liberation-2.1.5/LiberationSans-Regular.ttf', 'vtracer/1.0.0/vtracer.wasm', '.vite/manifest.json', 'gallery/bracket.webp'
  ]);
  assert.deepEqual(entries, ['/', '/assets/index-AbCdEf12.js', '/gallery/bracket.webp', '/library/index.json',
    '/library/pet-bowl/my%20icon.svg', '/manifest.webmanifest', '/openscad/2026.10.11/openscad.wasm']);
});

test('sw.js gets a version that follows file contents, and is valid JavaScript', async () => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'bonastudio-sw-'));
  await fs.writeFile(path.join(dir, 'index.html'), '<!doctype html>');
  await fs.mkdir(path.join(dir, 'library'));
  await fs.writeFile(path.join(dir, 'library', 'index.json'), '{"tools":[]}');
  const first = await writeServiceWorker(dir);
  const source = await fs.readFile(path.join(dir, 'sw.js'), 'utf8');
  assert.doesNotMatch(source, /__VERSION__|__PRECACHE__/);
  assert.match(source, new RegExp(`const VERSION = "${first.version}";`));
  assert.doesNotThrow(() => new Function(source));
  await fs.writeFile(path.join(dir, 'library', 'index.json'), '{"tools":[1]}');
  const second = await writeServiceWorker(dir);
  assert.notEqual(second.version, first.version);
  await fs.rm(dir, { recursive: true, force: true });
});

test('the web app manifest is installable and its icons exist', () => {
  const manifest = JSON.parse(readFileSync(new URL('../public/manifest.webmanifest', import.meta.url), 'utf8'));
  assert.equal(manifest.display, 'standalone');
  assert.equal(manifest.start_url, '/');
  for (const size of ['192x192', '512x512']) assert.ok(manifest.icons.some(icon => icon.sizes === size && icon.type === 'image/png'), size);
  assert.ok(manifest.icons.some(icon => icon.purpose === 'maskable'));
  for (const icon of manifest.icons) assert.ok(existsSync(new URL('../public' + icon.src, import.meta.url)), icon.src);
});

test('the service worker and manifest are never cached as immutable', () => {
  const vercel = JSON.parse(readFileSync(new URL('../vercel.json', import.meta.url), 'utf8'));
  for (const source of ['/sw.js', '/manifest.webmanifest']) {
    const rule = vercel.headers.find(item => item.source === source);
    assert.equal(rule?.headers.find(header => header.key === 'Cache-Control')?.value, 'no-cache', source);
  }
});

test('every gallery picture listed in the library exists', () => {
  const index = JSON.parse(readFileSync(new URL('../public/library/index.json', import.meta.url), 'utf8'));
  for (const tool of index.tools) {
    if (tool.thumbnail) assert.ok(existsSync(new URL('../public' + tool.thumbnail, import.meta.url)), tool.thumbnail);
  }
});
