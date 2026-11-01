// vercel.json must send the same security headers as the Vite servers (security-headers.mjs),
// and versioned assets must exist where the cache rules expect them.
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { securityHeaders } from '../security-headers.mjs';

const vercel = JSON.parse(readFileSync(new URL('../vercel.json', import.meta.url), 'utf8'));
const manifest = JSON.parse(readFileSync(new URL('../src/platform/asset-manifest.json', import.meta.url), 'utf8'));

test('vercel.json security headers match security-headers.mjs', () => {
  const global = vercel.headers.find(rule => rule.source === '/(.*)');
  const sent = Object.fromEntries(global.headers.map(header => [header.key, header.value]));
  for (const [key, value] of Object.entries(securityHeaders())) assert.equal(sent[key], value, key);
});

test('immutable caching only covers versioned or hashed paths', () => {
  assert.match(manifest.wasm, /^openscad\/[\d.]+\//);
  assert.match(manifest.vtracer, /^vtracer\/[\w.-]+\/vtracer\.wasm$/);
  assert.ok(vercel.headers.some(rule => rule.source === '/vtracer/(.*)' && /immutable/.test(rule.headers[0].value)));
  assert.match(manifest.fontDir, /^fonts\/liberation-[\d.]+$/);
  for (const path of Object.keys(manifest.integrity)) assert.ok(existsSync(new URL('../public/' + path, import.meta.url)), path);
});
