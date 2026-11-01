import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { zlibSync } from 'fflate';
import { woffToSfnt, makeOpenScadCompatible, fontForOpenScad } from '../src/shared/woff.js';
import { fontSupportsOpenScadWasm, fontFamiliesFromArrayBuffer } from '../src/shared/font-name.js';
import manifest from '../src/platform/asset-manifest.json' with { type: 'json' };
import googleFonts from '../src/platform/google-fonts.json' with { type: 'json' };
const { resolveFontAlias, BUNDLED_FONTS } = await import('../src/platform/fonts.js');

const liberation = new Uint8Array(readFileSync(new URL(`../public/${manifest.fontDir}/LiberationSans-Bold.ttf`, import.meta.url)));

function tablesOf(sfnt) {
  const view = new DataView(sfnt.buffer, sfnt.byteOffset, sfnt.byteLength);
  return Array.from({ length: view.getUint16(4) }, (_, index) => {
    const record = 12 + index * 16;
    const offset = view.getUint32(record + 8);
    return { tag: String.fromCharCode(...sfnt.subarray(record, record + 4)), checksum: view.getUint32(record + 4), data: sfnt.subarray(offset, offset + view.getUint32(record + 12)) };
  });
}

// Minimal WOFF 1.0 encoder for the round trip.
function toWoff(sfnt, drop = []) {
  const tables = tablesOf(sfnt).filter(table => !drop.includes(table.tag)).map(table => {
    const packed = zlibSync(table.data);
    return { ...table, stored: packed.length < table.data.length ? packed : table.data };
  });
  let offset = 44 + tables.length * 20;
  const size = tables.reduce((sum, table) => sum + ((table.stored.length + 3) & ~3), offset);
  const woff = new Uint8Array(size);
  const view = new DataView(woff.buffer);
  view.setUint32(0, 0x774f4646);
  view.setUint32(4, new DataView(sfnt.buffer, sfnt.byteOffset).getUint32(0));
  view.setUint32(8, size);
  view.setUint16(12, tables.length);
  tables.forEach((table, index) => {
    const entry = 44 + index * 20;
    woff.set([...table.tag].map(char => char.charCodeAt(0)), entry);
    view.setUint32(entry + 4, offset);
    view.setUint32(entry + 8, table.stored.length);
    view.setUint32(entry + 12, table.data.length);
    view.setUint32(entry + 16, table.checksum);
    woff.set(table.stored, offset);
    offset += (table.stored.length + 3) & ~3;
  });
  return woff;
}

test('WOFF → TTF keeps every table byte for byte', () => {
  const restored = woffToSfnt(toWoff(liberation));
  const before = tablesOf(liberation);
  const after = tablesOf(restored);
  assert.deepEqual(after.map(table => table.tag), before.map(table => table.tag));
  after.forEach((table, index) => assert.deepEqual(table.data, before[index].data, table.tag));
  assert.deepEqual(fontFamiliesFromArrayBuffer(restored.buffer), fontFamiliesFromArrayBuffer(liberation.buffer));
});

test('unhinted fonts get a no-op font program; hinted fonts are untouched', () => {
  assert.equal(makeOpenScadCompatible(liberation), liberation);
  const unhinted = woffToSfnt(toWoff(liberation, ['fpgm']));
  assert.equal(fontSupportsOpenScadWasm(unhinted), false);
  const fixed = fontForOpenScad(toWoff(liberation, ['fpgm']));
  assert.equal(fontSupportsOpenScadWasm(fixed), true);
  assert.deepEqual(tablesOf(fixed).find(table => table.tag === 'fpgm').data, new Uint8Array([0xb0, 0x00, 0x21]));
  assert.deepEqual(tablesOf(fixed).find(table => table.tag === 'glyf').data, tablesOf(liberation).find(table => table.tag === 'glyf').data);
});

test('Google font list: gstatic links with SRI, unique names', () => {
  assert.ok(googleFonts.fonts.length >= 40);
  const names = new Set();
  for (const font of googleFonts.fonts) {
    assert.match(font.url, /^https:\/\/fonts\.gstatic\.com\/s\/[a-z0-9]+\/v\d+\/[\w-]+\.woff$/, font.name);
    assert.match(font.integrity, /^sha256-[A-Za-z0-9+/]{43}=$/, font.name);
    assert.ok(!names.has(font.name.toLowerCase()), font.name);
    names.add(font.name.toLowerCase());
  }
  assert.equal(BUNDLED_FONTS.length, 12 + googleFonts.fonts.length);
});

test('font names and aliases resolve to a listed font', () => {
  assert.equal(resolveFontAlias('Arial:style=Bold'), 'Liberation Sans:style=Bold');
  assert.equal(resolveFontAlias('Times New Roman'), 'Liberation Serif:style=Regular');
  assert.equal(resolveFontAlias('Liberation Mono:style=Italic'), 'Liberation Mono:style=Italic');
  assert.equal(resolveFontAlias('Segoe Script:style=Bold'), 'Dancing Script:style=Bold');
  assert.equal(resolveFontAlias('Comic Sans MS'), 'Comic Neue');
  assert.equal(resolveFontAlias('Impact:style=Bold'), 'Anton');
  assert.equal(resolveFontAlias('roboto:style=Regular'), 'Roboto');
  assert.equal(resolveFontAlias('Pacifico'), 'Pacifico');
  assert.equal(resolveFontAlias('Wingdings'), null);
});
