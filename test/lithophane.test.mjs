// The Lithophane generator as the browser runs it: synced ES module + fflate (no node:zlib).
import test from 'node:test';
import assert from 'node:assert/strict';
import { unzlibSync, unzipSync, zipSync, strToU8, strFromU8 } from 'fflate';
import { prepareHeightmap, encodeGrayPng, decodeGrayPng, LITHOPHANE_LIMITS, validateHeightmapPng } from '../src/shared/heightmap.js';
import { buildLithophaneMesh, cropBorder, threeMfEntries, meshToStl, lithophaneManifest, LITHOPHANE_SHAPES } from '../src/shared/lithophane.js';
import { parseItemEchoes, itemTarget } from '../src/shared/transform.js';

function photo(width, height) {
  const rgba = new Uint8Array(width * height * 4);
  for (let i = 0; i < width * height; i++) {
    const v = Math.round(255 * (i % width) / (width - 1));
    rgba.set([v, v, v, 255], i * 4);
  }
  return prepareHeightmap(rgba, width, height, { autoLevels: false });
}

test('a 1000 px lithophane image passes the lithophane limits and decodes with fflate', () => {
  const png = encodeGrayPng(photo(1000, 750));
  assert.throws(() => validateHeightmapPng(png), 'too large for surface() reliefs');
  assert.equal(validateHeightmapPng(png, LITHOPHANE_LIMITS).width, 1002);
  const image = cropBorder(decodeGrayPng(png, bytes => unzlibSync(bytes)));
  assert.equal(image.width, 1000);
  assert.equal(image.gray[999], 255);
});

test('every shape builds a closed mesh; 3MF zips with fflate and keeps every vertex', () => {
  const image = cropBorder(photo(120, 80));
  for (const shape of LITHOPHANE_SHAPES) {
    const mesh = buildLithophaneMesh(image, { shape, size_mm: 60, resolution_mm: 0.5 }, { preview: true });
    const edges = new Map();
    for (let t = 0; t < mesh.indices.length; t += 3) {
      for (let k = 0; k < 3; k++) {
        const key = mesh.indices[t + k] + ',' + mesh.indices[t + (k + 1) % 3];
        edges.set(key, (edges.get(key) || 0) + 1);
      }
    }
    for (const [key, count] of edges) {
      assert.equal(count, 1, shape);
      assert.ok(edges.has(key.split(',').reverse().join(',')), shape);
    }
  }
  const mesh = buildLithophaneMesh(image, { shape: 'Heart', size_mm: 60, resolution_mm: 1 });
  const files = {};
  for (const entry of threeMfEntries(mesh, { name: 'Lithophane' })) files[entry.name] = strToU8(entry.parts ? entry.parts.join('') : entry.text);
  const unzipped = unzipSync(zipSync(files, { level: 1 }));
  const xml = strFromU8(unzipped['3D/3dmodel.model']);
  assert.equal((xml.match(/<vertex /g) || []).length, mesh.positions.length / 3);
  assert.equal(meshToStl(mesh).length, 84 + 50 * mesh.indices.length / 3);
});

test('the photo item drives image_x/_y/_rot/_size through the viewport item convention', () => {
  const mesh = buildLithophaneMesh(null, { shape: 'Circle', image_x: 4, image_rot: 15 });
  const echoes = mesh.items.map(item => 'ECHO: ' + JSON.stringify(['formforge-item', item.id, ...item.center, ...item.size, item.rotation]).slice(1, -1));
  const [item] = parseItemEchoes(echoes);
  assert.equal(item.id, 'image');
  assert.deepEqual(itemTarget(item.id, lithophaneManifest().parameters), { kind: 'parameters', x: 'image_x', y: 'image_y', rotate: 'image_rot', size: 'image_size' });
});
